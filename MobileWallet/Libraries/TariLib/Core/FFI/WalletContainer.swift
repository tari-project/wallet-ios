//  WalletContainer.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 12/09/2024
	Using Swift 5.0
	Running on macOS 14.6

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

protocol WalletInteractable {

    var address: TariAddress { get throws }
    var dataVersion: String? { get throws }
    var isWalletRunning: StaticPublisherWrapper<Bool> { get }
    var isWalletDBExist: Bool { get }

    var connectionCallbacks: WalletConnectionCallbacks { get }

    var connection: TariConnectionService { get }
    var contacts: TariContactsService { get }
    var fees: TariFeesService { get }
    var keyValues: TariKeyValueService { get }
    var messageSign: TariMessageSignService { get }
    var recovery: TariRecoveryService { get }
    var transactions: TariTransactionsService { get }
    var unspentOutputsService: TariUnspentOutputsService { get }
    var utxos: TariUTXOsService { get }
    var validation: TariValidationService { get }
    var walletBalance: TariBalanceService { get }

    func log(message: String) throws

    var databaseDirectoryURL: URL { get }
    var databaseURL: URL { get }
}

final class WalletConnectionCallbacks {

    @Published private(set) var baseNodeConnectionStatus: BaseNodeConnectivityStatus = .offline
    @Published private(set) var scannedHeight: UInt64 = 0
    @Published private(set) var blockHeight: UInt64 = 0

    init(baseNodeConnectionStatusPublisher: Published<BaseNodeConnectivityStatus>.Publisher, scannedHeightPublisher: Published<UInt64>.Publisher, blockHeight: Published<UInt64>.Publisher) {
        baseNodeConnectionStatusPublisher.assign(to: &$baseNodeConnectionStatus)
        scannedHeightPublisher.assign(to: &$scannedHeight)
        blockHeight.assign(to: &$blockHeight)
    }
}

final class WalletContainer: WalletInteractable, MainServiceable {

    @Published private var baseNodeConnectionStatus: BaseNodeConnectivityStatus = .offline
    @Published private var scannedHeight: UInt64 = 0
    @Published private var blockHeight: UInt64 = NetworkManager.shared.blockHeight

    // MARK: - WalletInteractable

    var address: TariAddress {
        get throws { try manager.walletAddress() }
    }

    var dataVersion: String? {
        get throws {
            let commsConfig = try makeCommsConfig(controlServerAddress: controlServerAddress, torCookie: torCookie)
            return try manager.walletVersion(commsConfig: commsConfig)
        }
    }

    private(set) lazy var isWalletRunning: StaticPublisherWrapper<Bool> = StaticPublisherWrapper(publisher: manager.$isWalletRunning)
    var isWalletDBExist: Bool { (try? databaseDirectoryURL.checkResourceIsReachable()) ?? false }

    private(set) lazy var connectionCallbacks = WalletConnectionCallbacks(baseNodeConnectionStatusPublisher: $baseNodeConnectionStatus, scannedHeightPublisher: $scannedHeight, blockHeight: $blockHeight)

    private(set) lazy var connection: TariConnectionService = TariConnectionService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)
    private(set) lazy var contacts = TariContactsService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)
    private(set) lazy var fees = TariFeesService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)
    private(set) lazy var keyValues = TariKeyValueService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)
    private(set) lazy var messageSign = TariMessageSignService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)
    private(set) lazy var recovery = TariRecoveryService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)
    private(set) lazy var transactions = TariTransactionsService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)
    private(set) lazy var unspentOutputsService = TariUnspentOutputsService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)
    private(set) lazy var utxos = TariUTXOsService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)
    private(set) lazy var validation: TariValidationService = TariValidationService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)
    private(set) lazy var walletBalance = TariBalanceService(walletManager: manager, walletCallbacks: walletCallbacks, services: self)

    // MARK: - Constants

    private let publicAddress = "/ip4/0.0.0.0/tcp/9838"
    private let databaseName = "tari_wallet"
    private let discoveryTimeout: UInt64 = 20
    private let safMessageDuration: UInt64 = 10800

    // MARK: - Properties

    let tag: String
    private let walletCallbacks = WalletCallbacks()

    private var torCookie: Data
    private var controlServerAddress: String

    var databaseDirectoryURL: URL { TariSettings.storageDirectory.appendingPathComponent("\(databaseName)_\(NetworkManager.shared.selectedNetwork.name)", isDirectory: true) }
    var databaseURL: URL { databaseDirectoryURL.appendingPathComponent(fullDatabaseName) }
    private var fullDatabaseName: String { databaseName + ".sqlite3" }

    private lazy var manager = FFIWalletHandler()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(tag: String, torCookie: Data, controlServerAddress: String) {
        self.tag = tag
        self.torCookie = torCookie
        self.controlServerAddress = controlServerAddress
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        $baseNodeConnectionStatus
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

        walletCallbacks.connectivityStatus
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$baseNodeConnectionStatus)

        walletCallbacks.scannedHeight
            .assign(to: &$scannedHeight)

        walletCallbacks.baseNodeState
            .receive(on: DispatchQueue.main)
            .compactMap { try? $0.heightOfTheLongestChain }
            .removeDuplicates()
            .sink { [weak self] in
                NetworkManager.shared.blockHeight = $0
                self?.blockHeight = $0
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func update(torCookie: Data) {
        self.torCookie = torCookie
    }

    func start(seedWords: [String]?, logPath: String, passphrase: String) throws {

        guard !manager.isWalletRunning else { return }

        let walletSeedWords = try makeSeedWords(seedWords: seedWords)
        try createWalletDirectoryIfNeeded()

        Logger.log(message: "Log Path: \(logPath)", domain: .general, level: .info)

        try manager.connectWallet(
            commsConfig: makeCommsConfig(controlServerAddress: controlServerAddress, torCookie: torCookie),
            logFilePath: logPath,
            seedWords: walletSeedWords,
            passphrase: passphrase,
            networkName: NetworkManager.shared.selectedNetwork.name,
            dnsPeer: NetworkManager.shared.selectedNetwork.dnsPeer,
            isDnsSecureOn: false,
            logVerbosity: TariSettings.shared.environment == .debug ? 11 : 4,
            callbacks: walletCallbacks
        )
    }

    func stop() {
        manager.disconnectWallet()
        baseNodeConnectionStatus = .offline
    }

    func log(message: String) throws {
        try manager.log(message: message)
    }

    func deleteWallet() throws {
        try deleteWalletDirectory()
    }

    // MARK: - Helpers

    private func createWalletDirectoryIfNeeded() throws {
        guard !isWalletDBExist else { return }
        try FileManager.default.createDirectory(at: databaseDirectoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    private func deleteWalletDirectory() throws {
        try FileManager.default.removeItem(at: databaseDirectoryURL)
    }

    private func makeSeedWords(seedWords: [String]?) throws -> SeedWords? {
        guard let seedWords else { return nil }
        return try SeedWords(words: seedWords)
    }

    private func makeCommsConfig(controlServerAddress: String, torCookie: Data) throws -> CommsConfig {
        try CommsConfig(
            publicAddress: publicAddress,
            transport: makeTransportConfig(controlServerAddress: controlServerAddress, torCookie: torCookie),
            databaseName: databaseName,
            databaseFolderPath: databaseDirectoryURL.path,
            discoveryTimeoutInSecs: discoveryTimeout,
            safMessageDurationInSec: safMessageDuration
        )
    }

    private func makeTransportConfig(controlServerAddress: String, torCookie: Data) throws -> TransportConfig {
        try TransportConfig(
            controlServerAddress: controlServerAddress,
            torPort: TariConstants.torPort,
            torCookie: ByteVector(data: torCookie),
            socksUsername: nil,
            socksPassword: nil
        )
    }
}

extension WalletInteractable {
    func transaction(id: UInt64) -> Transaction? {
        transactions.transaction(id: id)
    }
}
