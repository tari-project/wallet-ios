//  TorManager.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 07/01/2022
	Using Swift 5.0
	Running on macOS 12.1

	Copyright 2019 The Tari Project

	Redistribution and use in source and binary forms, with or
	without modification, are permitted provided that the
	following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above
	copyright notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	3. Neither the name of the copyright holder nor the names of
	its contributors may be used to endorse or promote products
	derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
	CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Tor
import Combine
import IPtProxy

final class TorManager {
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case portsOpen
        case connected
        case disconnecting
    }
    
    enum TorError: Error {
        case connectionFailed(error: Error)
        case connectionTimeout
        case missingCookie(error: Error?)
    }
    
    // MARK: - Constants
    
    
    private let controlAddress = "127.0.0.1"
    private let controlPort: UInt16 = 39069
    private let dataDirectoryUrl = TariSettings.storageDirectory.appendingPathComponent("tor", isDirectory: true)
    private lazy var authDirectoryURL = dataDirectoryUrl.appendingPathComponent("auth", isDirectory: true)
    private(set) lazy var controlServerAddress = "/ip4/\(controlAddress)/tcp/\(controlPort)"
    
    // MARK: - Properties
    
    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    @Published private(set) var bootstrapProgress: Int = 0
    @Published private(set) var error: Error?
    
    private var controller: TorController?
    
    private var configuration: TorConfiguration?
    private var torThread: TorThread?
    private var retryAction: DispatchWorkItem?
    private var needsReconfiguration = false
    
    private(set) var usedBridgesConfiguration: BridgesConfiguration = OnionSettings.currentlyUsedBridgesConfiguration
    
    private var backupBridgesConfiguration: BridgesConfiguration {
        get { OnionSettings.backupBridgesConfiguration }
        set { OnionSettings.backupBridgesConfiguration = newValue }
    }
    
    private var currentBridgesConfiguration: BridgesConfiguration {
        get { OnionSettings.currentlyUsedBridgesConfiguration }
        set { OnionSettings.currentlyUsedBridgesConfiguration = newValue }
    }
    
    // MARK: - Initialisers
    
    init() {
        configuration = try? createBaseConfiguration()
    }
    
    // MARK: - Actions
    
    func update(bridgesConfiguration: BridgesConfiguration) async throws {
        updateAndValidate(bridgesConfiguration: bridgesConfiguration)
        try await reinitiateConnection()
        OnionSettings.backupBridgesConfiguration = bridgesConfiguration
        OnionSettings.currentlyUsedBridgesConfiguration = bridgesConfiguration
    }
    
    func reinitiateConnection() async throws {
        await stop()
        try await start()
    }
    
    func stop() async {
        controller?.disconnect()
        torThread?.cancel()
        connectionStatus = .disconnecting
        await waitForTorThreadStop()
        connectionStatus = .disconnected
        bootstrapProgress = 0
    }
    
    private func start() async throws {
        
        connectionStatus = .connecting
        controller = TorController(socketHost: controlAddress, port: controlPort)
        
        if torThread?.isCancelled ?? true {
            try configureSession()
        } else if needsReconfiguration {
            reconfigureSession()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                do {
                    try self.startController()
                    try self.observeAuthentication()
                    self.setupRetry()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func configureSession() throws {
        
        let configuration = try createBaseConfiguration()
        var arguments = configuration.arguments ?? []
        
        arguments += bridgesArguments()
        
        switch Ipv6Tester.ipv6_status() {
        case .torIpv6ConnOnly:
            arguments += ["--ClientPreferIPv6ORPort", "1"]
            if (usedBridgesConfiguration.bridgesType != .none) {
                arguments += ["--ClientUseIPv4", "1"]
            } else {
                arguments += ["--ClientUseIPv4", "0"]
            }
        case .torIpv6ConnDual, .torIpv6ConnFalse, .torIpv6ConnUnknown:
            arguments += [
                "--ClientPreferIPv6ORPort", "auto",
                "--ClientUseIPv4", "1",
            ]
        }
        
        configuration.arguments = arguments
        
        torThread = TorThread(configuration: configuration)
        needsReconfiguration = false
        torThread?.start()
        startIObfs4Proxy()
    }
    
    private func waitForTorThreadStop() async {
        
        return await withCheckedContinuation { [weak self] continuation in
            
            guard self?.torThread != nil else {
                continuation.resume()
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] in
                    guard self?.torThread == nil || (self?.torThread?.isFinished == true && self?.torThread?.isExecuting == false) else { return }
                    $0.invalidate()
                    self?.torThread = nil
                    continuation.resume()
                }
            }
        }
    }
    
    private func startController() throws {
        
        guard let controller = controller else { return }

        if !controller.isConnected {
            do {
                try controller.connect()
            } catch {
                throw TorError.connectionFailed(error: error)
            }
        }
    }
    
    private func setupRetry() {
        
        let retryAction = DispatchWorkItem { [weak self] in
            self?.controller?.setConfForKey("DisableNetwork", withValue: "1")
            self?.controller?.setConfForKey("DisableNetwork", withValue: "0")
            
            self?.error = TorError.connectionTimeout
        }
        
        self.retryAction = retryAction
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: retryAction)
    }
    
    private func cancelRetry() {
        retryAction?.cancel()
        retryAction = nil
    }
    
    private func startIObfs4Proxy() {
        IPtProxyStartObfs4Proxy(nil, false, false, nil)
    }
    
    private func updateAndValidate(bridgesConfiguration: BridgesConfiguration) {
        
        defer {
            usedBridgesConfiguration = bridgesConfiguration
        }
        
        let currentConfiguration = self.usedBridgesConfiguration
        
        guard currentConfiguration.bridgesType == bridgesConfiguration.bridgesType else {
            needsReconfiguration = true
            return
        }
        
        let currentCustomBridges = currentConfiguration.customBridges
        let customBridges = bridgesConfiguration.customBridges
        
        guard let currentCustomBridges = currentCustomBridges, let customBridges = customBridges else {
            needsReconfiguration = (currentCustomBridges == nil && customBridges != nil) || (currentCustomBridges != nil && customBridges == nil)
            return
        }
        
        needsReconfiguration = currentCustomBridges != customBridges
    }
    
    private func reconfigureSession() {
        
        let config = createBridgesConfig()
        controller?.resetConf(forKey: "Bridge")
        
        guard !config.isEmpty else {
            controller?.setConfForKey("UseBridges", withValue: "0")
            return
        }
        
        controller?.setConfs(config)
        controller?.setConfForKey("UseBridges", withValue: "1")
    }
    
    private func bridges() -> [String] {
        switch usedBridgesConfiguration.bridgesType {
        case .custom:
            return usedBridgesConfiguration.customBridges ?? []
        default:
            return []
        }
    }

    private func bridgesArguments() -> [String] {
        
        var arguments = bridges().flatMap { ["--Bridge", $0] }
        
        if !arguments.isEmpty {
            arguments += ["--UseBridges", "1"]
        }
        
        return arguments
    }

    private func createBridgesConfig() -> [[String: String]] {
        bridges().map { ["key": "Bridge", "value": "\"\($0)\""] }
    }
    
    // MARK: - Observers
    
    private func observeAuthentication() throws {
        
        let cookie = try cookie()
        
        controller?.authenticate(with: cookie) { [weak self] isSuccess, error in
            guard isSuccess else { return }
            self?.connectionStatus = .portsOpen
            self?.observeCircuit()
            self?.observeStatusEvents()
        }
    }
    
    private func observeCircuit() {
        var observer: Any?
        observer = controller?.addObserver { [weak self] isCircuitEstablished in
            guard let self = self, isCircuitEstablished else { return }
            self.connectionStatus = .connected
            self.controller?.removeObserver(observer)
            self.cancelRetry()
        }
    }
    
    func observeStatusEvents() {
        var observer: Any?
        observer = controller?.addObserver { [weak self] type, severity, action, arguments in
            guard type == "STATUS_CLIENT", action == "BOOTSTRAP", let rawProgress = arguments?["PROGRESS"], let progress = Int(rawProgress) else { return false }
            self?.bootstrapProgress = progress
            guard progress >= 100 else { return true }
            self?.controller?.removeObserver(observer)
            return true
        }
    }
    
    // MARK: - Constructors
    
    func cookie() throws -> Data {
        guard let fileUrl = configuration?.dataDirectory?.appendingPathComponent("control_auth_cookie") else { throw TorError.missingCookie(error: nil) }
        do {
            return try Data(contentsOf: fileUrl)
        } catch {
            throw TorError.missingCookie(error: error)
        }
    }
    
    private func createBaseConfiguration() throws -> TorConfiguration {
        
        try createDataDirectoryInNeeded()
        try createAuthDirectoryInNeeded()
        
        let configuration = TorConfiguration()
        
        configuration.cookieAuthentication = true
        configuration.dataDirectory = dataDirectoryUrl
        
        #if DEBUG
        let log_loc = "notice stdout"
        #else
        let log_loc = "notice file /dev/null"
        #endif
        
        configuration.arguments = [
            "--allow-missing-torrc",
            "--ignore-missing-torrc",
            "--clientonly", "1",
            "--AvoidDiskWrites", "1",
            "--socksport", "39059",
            "--controlport", "\(controlAddress):\(controlPort)",
            "--log", log_loc,
            "--clientuseipv6", "1",
            "--ClientTransportPlugin", "obfs4 socks5 127.0.0.1:47351",
            "--ClientTransportPlugin", "meek_lite socks5 127.0.0.1:47352",
            "--ClientOnionAuthDir", authDirectoryURL.path
        ]
        
        return configuration
    }
    
    // MARK: - Helpers
    
    private func createDataDirectoryInNeeded() throws {
        guard !FileManager.default.fileExists(atPath: dataDirectoryUrl.path) else { return }
        try FileManager.default.createDirectory(at: dataDirectoryUrl, withIntermediateDirectories: true)
    }
    
    private func createAuthDirectoryInNeeded() throws {
        guard !FileManager.default.fileExists(atPath: authDirectoryURL.path) else { return }
        try FileManager.default.createDirectory(at: authDirectoryURL, withIntermediateDirectories: true)
    }
}
