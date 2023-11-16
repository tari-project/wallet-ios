//  Tari.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 19/11/2021
	Using Swift 5.0
	Running on macOS 12.0

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

import Combine
import UIKit

final class Tari: MainServiceable {

    // MARK: - Constants

    static let defaultFeePerGram = MicroTari(10)
    static let defaultKernelCount = UInt32(1)
    static let defaultOutputCount = UInt32(2)

    private let databaseName = "tari_wallet"

    var connectedDatabaseDirectory: URL { TariSettings.storageDirectory.appendingPathComponent("\(databaseName)_\(NetworkManager.shared.selectedNetwork.name)", isDirectory: true) }
    var databaseURL: URL { connectedDatabaseDirectory.appendingPathComponent(databaseFilename) }
    private var databaseFilename: String { databaseName + ".sqlite3" }

    private let logFilePrefix = "log"
    private let publicAddress = "/ip4/0.0.0.0/tcp/9838"
    private let discoveryTimeoutSec: UInt64 = 20
    private let safMessageDurationSec: UInt64 = 10800

    // MARK: - Properties

    static let shared = Tari()

    let connectionMonitor = ConnectionMonitor()

    private(set) lazy var connection = TariConnectionService(walletManager: walletManager, services: self)
    private(set) lazy var contacts = TariContactsService(walletManager: walletManager, services: self)
    private(set) lazy var messageSign = TariMessageSignService(walletManager: walletManager, services: self)
    private(set) lazy var fees = TariFeesService(walletManager: walletManager, services: self)
    private(set) lazy var keyValues = TariKeyValueService(walletManager: walletManager, services: self)
    private(set) lazy var recovery = TariRecoveryService(walletManager: walletManager, services: self)
    private(set) lazy var transactions = TariTransactionsService(walletManager: walletManager, services: self)
    private(set) lazy var utxos = TariUTXOsService(walletManager: walletManager, services: self)
    private(set) lazy var validation = TariValidationService(walletManager: walletManager, services: self)
    private(set) lazy var walletBalance = TariBalanceService(walletManager: walletManager, services: self)
    private(set) lazy var unspentOutputsService = TariUnspentOutputsService(walletManager: walletManager, services: self)

    private(set) lazy var logFilePath: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        return "\(TariSettings.storageDirectory.path)/\(logFilePrefix)-\(dateString).txt"
    }()

    var walletAddress: TariAddress {
        get throws { try walletManager.walletAddress() }
    }

    var logsURLs: [URL] {
        get throws {
            try FileManager.default.contentsOfDirectory(at: TariSettings.storageDirectory, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.hasPrefix(logFilePrefix) }
                .sorted { $0.path > $1.path }
        }
    }

    var isUsingCustomBridges: Bool { torManager.isUsingCustomBridges }
    var torBridges: String? { torManager.bridges }

    var isWalletExist: Bool { (try? connectedDatabaseDirectory.checkResourceIsReachable()) ?? false }

    @Published private(set) var isWalletConnected: Bool = false
    @Published private(set) var torError: TorError?

    var canAutomaticalyReconnectWallet: Bool = false
    @Published var isDisconnectionDisabled: Bool = false

    private let torManager = TorManager()
    private let walletManager = FFIWalletManager()
    private var cancellables = Set<AnyCancellable>()

    private var passphrase: String {
        guard let passphrase = AppKeychainWrapper.dbPassphrase else {
            let newPassphrase = String.random(length: 32)
            AppKeychainWrapper.dbPassphrase = newPassphrase
            return newPassphrase
        }
        return passphrase
    }

    func update(torBridges: String?) {
        torManager.update(bridges: torBridges)
    }

    // MARK: - Initialisers

    private init() {
        connectionMonitor.setupPublishers(
            torConnectionStatus: torManager.$connectionStatus.eraseToAnyPublisher(),
            torBootstrapProgress: torManager.$bootstrapProgress.eraseToAnyPublisher(),
            baseNodeConnectionStatus: walletManager.$baseNodeConnectionStatus.eraseToAnyPublisher(),
            baseNodeSyncStatus: validation.$status.eraseToAnyPublisher()
        )
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        Publishers.CombineLatest(connectionMonitor.$baseNodeConnection, connectionMonitor.$syncStatus)
            .filter { $0 == .offline || $1 == .failed }
            .sink { [weak self] _, _ in try? self?.switchBaseNode() }
            .store(in: &cancellables)

        connectionMonitor.$baseNodeConnection
            .sink { [weak self] in
                switch $0 {
                case .offline:
                    self?.validation.reset()
                case .connecting:
                    break
                case .online:
                    try? self?.validation.sync()
                }
            }
            .store(in: &cancellables)

        walletManager.$isWalletConnected
            .sink { [weak self] in self?.isWalletConnected = $0 }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.connect() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .filter { [weak self] _ in self?.isDisconnectionDisabled == false }
            .sink { [weak self] _ in self?.disconnect() }
            .store(in: &cancellables)

        $isDisconnectionDisabled
            .receive(on: DispatchQueue.main)
            .filter { !$0 && UIApplication.shared.applicationState == .background }
            .sink { [weak self] _ in self?.disconnect() }
            .store(in: &cancellables)

        torManager.$error
            .assignPublisher(to: \.torError, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func startWallet() async throws {
        await waitForTor()
        try startWallet(seedWords: nil)
        try connection.selectCurrentNode()
    }

    func restoreWallet(seedWords: [String]) throws {
        try startWallet(seedWords: seedWords)
    }

    func deleteWallet() {
        try? deleteWalletDirectory()
        try? deleteLogs()
        disconnectWallet()
    }

    func select(network: TariNetwork) {
        disconnectWallet()
        NetworkManager.shared.selectedNetwork = network
    }

    func log(message: String) {
        try? walletManager.log(message: message)
    }

    private func connect() {
        torManager.start()
        guard canAutomaticalyReconnectWallet, !walletManager.isWalletConnected else { return }
        Task {
            try? await startWallet()
        }
    }

    private func disconnect() {
        walletManager.disconnectWallet()
        torManager.stop()
    }

    private func startWallet(seedWords: [String]?) throws {

        let commsConfig = try makeCommsConfig()
        let selectedNetwork = NetworkManager.shared.selectedNetwork
        var walletSeedWords: SeedWords?

        if let seedWords = seedWords {
            walletSeedWords = try SeedWords(words: seedWords)
        }

        if !isWalletExist {
            try createWalletDirectory()
        }

        let logFilePath = logFilePath
        Logger.log(message: "Log Path: \(logFilePath)", domain: .general, level: .info)

        do {
            try walletManager.connectWallet(commsConfig: commsConfig, logFilePath: logFilePath, seedWords: walletSeedWords, passphrase: passphrase, networkName: selectedNetwork.name)
            resetServices()
        } catch {
            guard let error = error as? WalletError, error == WalletError.invalidPassphrase else { throw error }
            try walletManager.connectWallet(commsConfig: commsConfig, logFilePath: logFilePath, seedWords: walletSeedWords, passphrase: nil, networkName: selectedNetwork.name)
        }
    }

    private func waitForTor() async {
        return await withCheckedContinuation { continuation in
            Tari.shared.connectionMonitor.$torConnection
                .filter { $0 == .portsOpen || $0 == .connected }
                .first()
                .sink { _ in continuation.resume() }
                .store(in: &cancellables)
        }
    }

    private func resetServices() {
        walletBalance.reset()
        transactions.reset()
    }

    private func disconnectWallet() {
        walletManager.disconnectWallet()
        UserDefaults.standard.removeAll()
        NetworkManager.shared.removeSelectedNetworkSettings()
    }

    private func makeCommsConfig() throws -> CommsConfig {

        let torCookie = try torManager.controlAuthCookie()
        let transportType = try makeTransportType(torCookie: torCookie)

        return try CommsConfig(
            publicAddress: publicAddress,
            transport: transportType,
            databaseName: databaseName,
            databaseFolderPath: connectedDatabaseDirectory.path,
            discoveryTimeoutInSecs: discoveryTimeoutSec,
            safMessageDurationInSec: safMessageDurationSec
        )
    }

    private func makeTransportType(torCookie: Data) throws -> TransportConfig {

        let torCookie = try ByteVector(data: torCookie)

        return try TransportConfig(
            controlServerAddress: torManager.controlServerAddress,
            torPort: 18101,
            torCookie: torCookie,
            socksUsername: nil,
            socksPassword: nil
        )
    }

    private func createWalletDirectory() throws {
        try FileManager.default.createDirectory(at: connectedDatabaseDirectory, withIntermediateDirectories: true, attributes: nil)
    }

    private func deleteWalletDirectory() throws {
        try FileManager.default.removeItem(at: connectedDatabaseDirectory)
    }

    private func deleteLogs() throws {
        try FileManager.default.contentsOfDirectory(at: TariSettings.storageDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.contains(logFilePrefix) }
            .forEach { try FileManager.default.removeItem(at: $0) }
    }

    private func switchBaseNode() throws {

        let selectedBaseNode = NetworkManager.shared.selectedNetwork.selectedBaseNode
        guard NetworkManager.shared.selectedNetwork.baseNodes.contains(selectedBaseNode), NetworkManager.shared.selectedNetwork.baseNodes.count > 1 else { return }

        var newBaseNode: BaseNode

        repeat {
            newBaseNode = try NetworkManager.shared.selectedNetwork.randomNode()
        } while newBaseNode == selectedBaseNode

        try connection.select(baseNode: newBaseNode)
    }

    // MARK: - Data

    func walletVersion() throws -> String? {
        let commsConfig = try makeCommsConfig()
        return try walletManager.walletVersion(commsConfig: commsConfig)
    }
}
