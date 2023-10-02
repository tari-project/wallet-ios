//  TorWorkingContainter.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 29/08/2023
	Using Swift 5.0
	Running on macOS 13.4

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
import IPtProxy

enum TorError: Error {
    case connectionFailed(error: Error)
    case authenticationFailed
    case missingController
    case missingCookie(error: Error)
    case unknown(error: Error)
}

enum TorConnectionStatus {
    case disconnected
    case connecting
    case portsOpen
    case connected
    case disconnecting
}

final class TorWorkingContainter {

    private enum InternalError: Error {
        case invalidated
    }

    // MARK: - Constants

    private let controlAddress = "127.0.0.1"
    private let controlPort: UInt16 = 39069
    private let dataDirectoryUrl = TariSettings.storageDirectory.appendingPathComponent("tor", isDirectory: true)
    private lazy var authDirectoryURL = dataDirectoryUrl.appendingPathComponent("auth", isDirectory: true)
    private lazy var cookieURL = dataDirectoryUrl.appendingPathComponent("control_auth_cookie")

    // MARK: - Properties

    @Published private(set) var connectionStatus: TorConnectionStatus = .disconnected
    @Published private(set) var bootstrapProgress: Int = 0
    @Published private(set) var error: TorError?

    private let bridges: [String]

    private lazy var controller: TorController = TorController(socketHost: controlAddress, port: controlPort)
    private var isInvalidated = false
    private var thread: TorThread?
    private var observers: [Any?] = []
    private var retryAction: DispatchWorkItem?
    private var isUsingCustomBridges: Bool { !bridges.isEmpty }

    // MARK: - Initialisers

    init(bridges: [String]) {
        Logger.log(message: "Containter - Init", domain: .tor, level: .info)
        self.bridges = bridges
        setupContainter()
    }

    // MARK: - Setups

    private func setupContainter() {
        Task {
            do {
                try createDirectoriesIfNeeded()
                try await setupThread()
                startIObfs4Proxy()
                try await startController()
                try await observeAuthentication()
                setupRetry()
            } catch {
                handle(error: error)
            }
        }
    }

    private func setupThread() async throws {

        guard thread == nil, !isInvalidated else { throw InternalError.invalidated }

        guard TorThread.active == nil else {
            Logger.log(message: "Containter - Waiting for thread", domain: .tor, level: .info)
            try await Task.sleep(seconds: 0.5)
            try await setupThread()
            return
        }

        let configuration = makeTorConfiguration()

        thread = TorThread(configuration: configuration)
        thread?.start()
        Logger.log(message: "Containter - Thread created", domain: .tor, level: .info)
    }

    private func startController(retryCount: Int = 0) async throws {

        guard !controller.isConnected else { return }
        let maxRetryCount = 4

        do {
            try controller.connect()
            Logger.log(message: "Containter - Controller created", domain: .tor, level: .info)
        } catch {
            if retryCount < maxRetryCount {
                Logger.log(message: "Containter - Waiting for controller: \(retryCount)", domain: .tor, level: .info)
                try await Task.sleep(seconds: 0.2)
                try await startController(retryCount: retryCount + 1)
            } else {
                guard let posixError = error.posixError else { throw TorError.connectionFailed(error: error) }
                throw TorError.connectionFailed(error: posixError)
            }
        }
    }

    private func startIObfs4Proxy() {
        IPtProxyStartObfs4Proxy(nil, false, false, nil)
    }

    private func setupRetry() {

        Logger.log(message: "Containter - Retry set", domain: .tor, level: .info)

        let retryAction = DispatchWorkItem { [weak self] in
            self?.resetConnection()
        }

        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 30.0, execute: retryAction)
        self.retryAction = retryAction
    }

    private func cancelRetry() {

        Logger.log(message: "Containter - Retry cancelled", domain: .tor, level: .info)

        retryAction?.cancel()
        retryAction = nil
    }

    private func resetConnection() {

        Logger.log(message: "Containter - Retry triggered", domain: .tor, level: .info)

        controller.setConfForKey("DisableNetwork", withValue: "1")
        controller.setConfForKey("DisableNetwork", withValue: "0")
    }

    // MARK: - Observers

    private func observeAuthentication() async throws {

        let cookie = try await cookie()

        guard try await controller.authenticate(with: cookie) else { throw TorError.authenticationFailed }

        Logger.log(message: "Containter - Authentication completed", domain: .tor, level: .info)

        connectionStatus = .portsOpen
        observeCircuit()
        observeStatusEvents()
    }

    private func observeCircuit() {

        let observer = controller.addObserver(forCircuitEstablished: { [weak self] isCircuitEstablished in
            Logger.log(message: "Containter - isCircuitEstablished: \(isCircuitEstablished)", domain: .tor, level: .verbose)
            guard isCircuitEstablished else { return }
            self?.connectionStatus = .connected
        })

        observers.append(observer)
    }

    private func observeStatusEvents() {

        let observer = controller.addObserver { [weak self] type, _, action, arguments in
            guard type == "STATUS_CLIENT", action == "BOOTSTRAP", let rawProgress = arguments?["PROGRESS"], let progress = Int(rawProgress) else { return false }
            self?.bootstrapProgress = progress
            guard progress >= 100 else { return true }
            self?.cancelRetry()
            return true
        }

        observers.append(observer)
    }

    // MARK: - Actions

    func invalidate() {
        Logger.log(message: "Containter - Invalidated", domain: .tor, level: .info)
        isInvalidated = true
    }

    // MARK: - Handlers

    private func handle(error: Error) {

        switch error {
        case let error as TorError:
            self.error = error
        default:
            self.error = .unknown(error: error)
        }
    }

    // MARK: - Constructors

    func cookie() async throws -> Data {
        try await cookie(retryCount: 0)
    }

    private func cookie(retryCount: Int) async throws -> Data {

        let maxRetryCount = 5

        do {
            return try self.fetchCookieData()
        } catch {
            guard retryCount < maxRetryCount else { throw error }
            Logger.log(message: "Waiting for cookies: Retry Count: \(retryCount)", domain: .tor, level: .info)
            try await Task.sleep(seconds: 0.1)
            return try await cookie(retryCount: retryCount + 1)
        }
    }

    private func fetchCookieData() throws -> Data {
        do {
            return try Data(contentsOf: cookieURL)
        } catch {
            throw TorError.missingCookie(error: error)
        }
    }

    private func createDirectoriesIfNeeded() throws {
        try createDataDirectoryInNeeded()
        try createAuthDirectoryInNeeded()
    }

    private func makeTorConfiguration() -> TorConfiguration {

        let configuration = TorConfiguration()

        configuration.cookieAuthentication = true
        configuration.dataDirectory = dataDirectoryUrl

        var arguments: [String] = makeBaseArguments()
        arguments += makeBridgeArguments()
        arguments += makeIpArguments()
        configuration.arguments = arguments

        return configuration
    }

    private func makeBaseArguments() -> [String] {

        #if DEBUG
        let logLocation = "notice stdout"
        #else
        let logLocation = "notice file /dev/null"
        #endif

        return [
            "--allow-missing-torrc",
            "--ignore-missing-torrc",
            "--clientonly", "1",
            "--AvoidDiskWrites", "1",
            "--socksport", "39059",
            "--controlport", "\(controlAddress):\(controlPort)",
            "--log", logLocation,
            "--clientuseipv6", "1",
            "--ClientTransportPlugin", "obfs4 socks5 127.0.0.1:47351",
            "--ClientTransportPlugin", "meek_lite socks5 127.0.0.1:47352",
            "--ClientOnionAuthDir", authDirectoryURL.path
        ]
    }

    private func makeBridgeArguments() -> [String] {
        guard isUsingCustomBridges else { return [] }
        var arguments = bridges.flatMap { ["--Bridge", $0] }
        arguments += ["--UseBridges", "1"]
        return arguments
    }

    private func makeIpArguments() -> [String] {

        var arguments: [String] = []

        switch Ipv6Tester.ipv6_status() {
        case .torIpv6ConnOnly:
            arguments += ["--ClientPreferIPv6ORPort", "1"]
            let ipv4argument = isUsingCustomBridges ? "1" : "0"
            arguments += ["--ClientUseIPv4", ipv4argument]
        case .torIpv6ConnDual, .torIpv6ConnFalse, .torIpv6ConnUnknown:
            arguments += [
                "--ClientPreferIPv6ORPort", "auto",
                "--ClientUseIPv4", "1"
            ]
        }

        return arguments
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

    // MARK: - Deinit

    deinit {
        controller.disconnect()
        observers.forEach { self.controller.removeObserver($0) }
        TorThread.active?.cancel()
        thread?.cancel()
        thread = nil

        Logger.log(message: "Containter - Deinit", domain: .tor, level: .info)
    }
}
