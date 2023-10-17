//  TorWorker.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 16/10/2023
	Using Swift 5.0
	Running on macOS 14.0

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
import Combine

enum TorError: Error {
    case connectionFailed(error: Error)
    case authenticationFailed
    case missingCookie(error: Error)
    case unknown(error: Error)
}

enum TorConnectionStatus {
    case disconnected
    case connecting
    case portsOpen
    case connected
}

final class TorWorker {

    private enum BootstrapStatus {
        case notStarted
        case inProgress
        case finished
    }

    private enum InternalError: Error {
        case threadAlreadyRunning
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
    @Published private var bootstrapStatus: BootstrapStatus = .notStarted

    private lazy var controller: TorController = TorController(socketHost: controlAddress, port: controlPort)

    private var retryAction: DispatchWorkItem?
    private var observers: [Any?] = []
    private var bootstrapCancellables = Set<AnyCancellable>()

    // MARK: - Actions

    func start(bridges: [String]) {

        Logger.log(message: "TorWorker - Start", domain: .tor, level: .info)

        Task {
            do {
                try createDirectoriesIfNeeded()
                await disconnect()
                try await waitForThread()
                try await createThread(bridges: bridges)
                createController()
                try await connect()
                try await authenticate()
                observeConnection()
                setupRetry()
            } catch {
                handle(error: error)
            }
        }
    }

    func stop() async {
        Logger.log(message: "TorWorker - Stop", domain: .tor, level: .info)
        await disconnect()
    }

    private func createDirectoriesIfNeeded() throws {
        try createDataDirectoryInNeeded()
        try createAuthDirectoryInNeeded()
    }

    private func waitForThread() async throws {
        Logger.log(message: "TorWorker - Waiting for thread", domain: .tor, level: .info)
        guard TorThread.active != nil else { return }
        try await Task.sleep(seconds: 0.5)
        try await waitForThread()
    }

    private func createThread(bridges: [String]) async throws {

        guard TorThread.active == nil else { throw InternalError.threadAlreadyRunning }

        let configuration = makeTorConfiguration(bridges: bridges)
        let thread = TorThread(configuration: configuration)
        thread.start()
        startIObfs4Proxy()
        Logger.log(message: "TorWorker - Thread created", domain: .tor, level: .info)
        try await Task.sleep(seconds: 0.5)
    }

    private func createController() {
        controller = TorController(socketHost: controlAddress, port: controlPort)
        Logger.log(message: "TorWorker - Controller created", domain: .tor, level: .info)
    }

    private func connect(retryCount: Int = 0) async throws {

        guard !controller.isConnected else { return }
        let maxRetryCount = 4

        do {
            try controller.connect()
            Logger.log(message: "TorWorker - Controller connected", domain: .tor, level: .info)
        } catch {
            if retryCount < maxRetryCount {
                Logger.log(message: "TorWorker - Waiting for controller: \(retryCount)", domain: .tor, level: .info)
                try await Task.sleep(seconds: 0.2)
                try await connect(retryCount: retryCount + 1)
            } else {
                guard let posixError = error.posixError else { throw TorError.connectionFailed(error: error) }
                throw TorError.connectionFailed(error: posixError)
            }
        }
    }

    private func disconnect() async {
        await waitingForBootstrap()
        cleanup()
    }

    private func waitingForBootstrap() async {

        guard bootstrapStatus == .inProgress else { return }

        await withCheckedContinuation { [weak self] continuation in
            guard let self else { return }
            self.$bootstrapStatus
                .filter { $0 != .inProgress }
                .sink { [weak self] _ in
                    self?.bootstrapCancellables.forEach { $0.cancel() }
                    self?.bootstrapCancellables.removeAll()
                    continuation.resume()
                }
                .store(in: &self.bootstrapCancellables)
        }
    }

    private func cleanup() {
        guard controller.isConnected else { return }
        bootstrapProgress = 0
        observers.forEach { controller.removeObserver($0) }
        observers.removeAll()
        controller.disconnect()
        connectionStatus = .disconnected
        cancelRetry()
    }

    private func authenticate() async throws {
        let cookie = try await cookie()
        guard try await controller.authenticate(with: cookie) else { throw TorError.authenticationFailed }
        connectionStatus = .portsOpen
        bootstrapStatus = .inProgress
        Logger.log(message: "TorWorker - Authentication completed", domain: .tor, level: .info)
    }

    private func observeConnection() {
        observeCircuit()
        observeStatusEvents()
    }

    private func observeCircuit() {

        let observer = controller.addObserver(forCircuitEstablished: { [weak self] isCircuitEstablished in
            Logger.log(message: "TorWorker - isCircuitEstablished: \(isCircuitEstablished)", domain: .tor, level: .verbose)
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
            self?.bootstrapStatus = .finished
            return true
        }

        observers.append(observer)
    }

    private func startIObfs4Proxy() {
        IPtProxyStartObfs4Proxy(nil, false, false, nil)
    }

    private func setupRetry() {

        Logger.log(message: "TorWorker - Retry set", domain: .tor, level: .info)

        let retryAction = DispatchWorkItem { [weak self] in
            self?.resetConnection()
        }

        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 30.0, execute: retryAction)
        self.retryAction = retryAction
    }

    private func cancelRetry() {

        Logger.log(message: "TorWorker - Retry cancelled", domain: .tor, level: .info)

        retryAction?.cancel()
        retryAction = nil
    }

    private func resetConnection() {

        Logger.log(message: "TorWorker - Retry triggered", domain: .tor, level: .info)

        controller.setConfForKey("DisableNetwork", withValue: "1")
        controller.setConfForKey("DisableNetwork", withValue: "0")
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

    private func makeTorConfiguration(bridges: [String]) -> TorConfiguration {

        let configuration = TorConfiguration()

        configuration.cookieAuthentication = true
        configuration.dataDirectory = dataDirectoryUrl

        var arguments: [String] = makeBaseArguments()
        arguments += makeBridgeArguments(bridges: bridges)
        arguments += makeIpArguments(isUsingCustomBridges: !bridges.isEmpty)
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

    private func makeBridgeArguments(bridges: [String]) -> [String] {
        guard !bridges.isEmpty else { return [] }
        var arguments = bridges.flatMap { ["--Bridge", $0] }
        arguments += ["--UseBridges", "1"]
        return arguments
    }

    private func makeIpArguments(isUsingCustomBridges: Bool) -> [String] {

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
}
