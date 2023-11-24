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

    private enum Action {
        case connect
        case disconnect
    }

    // MARK: - Constants

    private(set) lazy var controlServerAddress = "/ip4/\(socketHost)/tcp/\(port)"

    private let socketHost = "127.0.0.1"
    private let port: UInt16 = 39069
    private let workingDirectory = TariSettings.storageDirectory.appendingPathComponent("tor", isDirectory: true)
    private lazy var authDirectory = workingDirectory.appendingPathComponent("auth", isDirectory: true)
    private lazy var controlAuthCookieURL = workingDirectory.appendingPathComponent("control_auth_cookie")

    // MARK: - Properties

    @Published private(set) var connectionStatus: TorConnectionStatus = .disconnected
    @Published private(set) var bootstrapProgress: Int = 0
    @Published private(set) var error: TorError?

    var isUsingCustomBridges: Bool { TorManagerUserDefaults.isUsingCustomBridges ?? false }
    var bridges: String? { TorManagerUserDefaults.torBridges }

    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var controller: TorController?
    private var queuedAction: Action? {
        didSet {
            guard let queuedAction else {
                Logger.log(message: "queuedAction: None", domain: .debug, level: .info)
                return
            }
            Logger.log(message: "queuedAction: \(queuedAction)", domain: .debug, level: .info)
        }
    }
    private var retryAction: DispatchWorkItem?
    private var observers: [Any?] = []
    private var isActionLocked = false {
        didSet { Logger.log(message: "isActionLocked: \(isActionLocked)", domain: .debug, level: .info) }
    }
    private var cancellables = Set<AnyCancellable>()

    private var isThreadRunning: Bool { TorThread.active != nil }

    private var existingController: TorController {
        get throws {
            guard let controller else { throw TorError.missingController }
            return controller
        }
    }

    private var bridgesChunks: [String] {
        (bridges ?? "")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("//") && !$0.hasPrefix("#") }
    }

    // MARK: - Init

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        $bootstrapProgress
            .sink { [weak self] in
                switch $0 {
                case 0:
                    break
                case 100:
                    self?.isActionLocked = false
                    self?.cancelRetry()
                    self?.runQueuedAction()
                default:
                    self?.isActionLocked = true
                }
            }
            .store(in: &cancellables)

        $error
            .compactMap { $0 }
            .sink { [weak self] in self?.handle(torError: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Files

    private func createDirectories() throws {
        try FileManager.default.createDirectory(at: authDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Actions

    func start() {

        Logger.log(message: "Start", domain: .tor, level: .info)

        guard !isActionLocked else {
            queuedAction = .connect
            return
        }

        Task {
            do {
                try await disconnect()
                try await connect()
            } catch {
                handle(error: error)
            }
        }
    }

    func stop() {

        Logger.log(message: "Stop", domain: .tor, level: .info)

        guard !isActionLocked else {
            queuedAction = .disconnect
            return
        }

        endBackgroundTask()
        startBackgroundTask()

        Task {
            do {
                try await disconnect()
                endBackgroundTask()
            } catch {
                handle(error: error)
                endBackgroundTask()
            }
        }
    }

    func disconnect() async throws {
        Logger.log(message: "Disconnect: Start", domain: .tor, level: .info)
        isActionLocked = true
        stopController()
        connectionStatus = .disconnecting
        bootstrapProgress = 0
        try await waitingForThread()
        connectionStatus = .disconnected
        isActionLocked = false
        Logger.log(message: "Disconnect: Done", domain: .tor, level: .info)
    }

    func update(bridges: String?) {
        Logger.log(message: "Update bridges", domain: .tor, level: .info)
        TorManagerUserDefaults.isUsingCustomBridges = bridges != nil
        TorManagerUserDefaults.torBridges = bridges
        start()
    }

    private func connect() async throws {
        Logger.log(message: "Connect: Start", domain: .tor, level: .info)
        connectionStatus = .connecting
        isActionLocked = true
        try createDirectories()
        try createThread()
        startIObfs4Proxy()
        createController()
        try await startController()
        guard try await auth() else { throw TorError.authenticationFailed }
        connectionStatus = .portsOpen
        try observeConnection()
        setupRetry()
        Logger.log(message: "Connect: Done", domain: .tor, level: .info)
    }

    private func runQueuedAction() {

        guard let queuedAction else { return }
        self.queuedAction = nil

        switch queuedAction {
        case .connect:
            start()
        case .disconnect:
            stop()
        }
    }

    // MARK: - Thread

    private func createThread() throws {
        let configuration = makeConfiguration()
        let thread = TorThread(configuration: configuration)
        thread.start()
    }

    private func waitingForThread() async throws {
        guard isThreadRunning else { return }
        Logger.log(message: "Waiting for thread", domain: .tor, level: .info)
        try await Task.sleep(seconds: 0.5)
        try await waitingForThread()
    }

    // MARK: - Proxy

    private func startIObfs4Proxy() {
        IPtProxyStartObfs4Proxy(nil, false, false, nil)
    }

    // MARK: - Controller

    private func createController() {
        controller = TorController(socketHost: socketHost, port: port)
        Logger.log(message: "Controller Created", domain: .tor, level: .info)
    }

    private func startController(retryCount: Int = 0) async throws {

        Logger.log(message: "Controller Connecting", domain: .tor, level: .info)

        let maxRetryCount = 5

        do {
            try existingController.connect()
            isActionLocked = true
            Logger.log(message: "Controller Connected", domain: .tor, level: .info)
        } catch {
            Logger.log(message: "Waiting for connection: \(retryCount)", domain: .tor, level: .info)
            let retryCount = retryCount + 1
            guard retryCount < maxRetryCount else {
                guard let posixError = error.posixError else { throw TorError.connectionFailed(error: error) }
                isActionLocked = false
                throw TorError.connectionFailed(error: posixError)
            }

            try await Task.sleep(seconds: 0.5)
            try await startController(retryCount: retryCount)
        }
    }

    private func stopController() {
        controller?.disconnect()
        Logger.log(message: "Controller Disconnected", domain: .tor, level: .info)
    }

    private func auth() async throws -> Bool {
        let controlAuthCookie = try controlAuthCookie()
        let result = try await existingController.authenticate(with: controlAuthCookie)
        Logger.log(message: "Authenticated", domain: .tor, level: .info)
        return result
    }

    private func observeConnection() throws {

        let statsObserver = try existingController.addObserver { [weak self] _, _, action, arguments in
            guard action == "BOOTSTRAP", let rawProgress = arguments?["PROGRESS"], let progress = Int(rawProgress) else { return false }
            self?.bootstrapProgress = progress
            return false
        }

        let circlesObserver = try existingController.addObserver { [weak self] isEstablished in
            guard isEstablished else { return }
            self?.connectionStatus = .connected
            self?.removeObservers()
        }

        observers += [statsObserver, circlesObserver]
    }

    private func removeObservers() {
        observers.forEach { self.controller?.removeObserver($0) }
        observers.removeAll()
    }

    // MARK: - Retry

    private func setupRetry() {

        Logger.log(message: "Retry set", domain: .tor, level: .info)

        let retryAction = DispatchWorkItem { [weak self] in
            self?.resetConnection()
        }

        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 30.0, execute: retryAction)
        self.retryAction = retryAction
    }

    private func cancelRetry() {

        Logger.log(message: "Retry cancelled", domain: .tor, level: .info)

        retryAction?.cancel()
        retryAction = nil
    }

    private func resetConnection() {

        Logger.log(message: "Retry triggered", domain: .tor, level: .info)

        controller?.setConfForKey("DisableNetwork", withValue: "1")
        controller?.setConfForKey("DisableNetwork", withValue: "0")
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

    private func handle(torError: TorError) {

        Logger.log(message: "\(torError)", domain: .tor, level: .error)

        switch torError {
        case let .connectionFailed(error):
            handle(connectionError: error)
        case .authenticationFailed, .missingController, .missingCookie, .unknown:
            break
        }
    }

    private func handle(connectionError: Error) {

        guard let posixError = connectionError as? PosixError else { return }

        Logger.log(message: "POSIX Error: \(posixError.code)", domain: .tor, level: .error)

        switch posixError {
        case .connectionRefused:
            Logger.log(message: "Connection Refused. Custom Tor bridged disabled.", domain: .tor, level: .warning)
            TorManagerUserDefaults.isUsingCustomBridges = false
            start()
        default:
            break
        }
    }

    // MARK: - Cookies

    func controlAuthCookie() throws -> Data {
        do {
            return try Data(contentsOf: controlAuthCookieURL)
        } catch {
            throw TorError.missingCookie(error: error)
        }
    }

    // MARK: - Background Tasks

    private func startBackgroundTask() {
        Logger.log(message: "Start Background Task", domain: .tor, level: .info)
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        Logger.log(message: "BG Task - Start: \(backgroundTaskID)", domain: .debug, level: .info)
    }

    private func endBackgroundTask() {
        Logger.log(message: "BG Task - End: \(backgroundTaskID)", domain: .debug, level: .info)
        guard backgroundTaskID != .invalid else { return }
        Logger.log(message: "End Background Task", domain: .tor, level: .info)
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }

    // MARK: - Helpers

    private func makeConfiguration() -> TorConfiguration {

        var arguments: [String] = makeBaseArguments()
        arguments += makeBridgeArguments()
        arguments += makeIpArguments()

        let configuration = TorConfiguration()
        configuration.cookieAuthentication = true
        configuration.dataDirectory = workingDirectory
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
            "--controlport", "\(socketHost):\(port)",
            "--log", logLocation,
            "--clientuseipv6", "1",
            "--ClientTransportPlugin", "obfs4 socks5 127.0.0.1:47351",
            "--ClientTransportPlugin", "meek_lite socks5 127.0.0.1:47352",
            "--ClientOnionAuthDir", authDirectory.path
        ]
    }

    private func makeBridgeArguments() -> [String] {
        guard isUsingCustomBridges else { return [] }
        var arguments = bridgesChunks.flatMap { ["--Bridge", $0] }
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
}
