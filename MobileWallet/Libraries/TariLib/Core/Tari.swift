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

final class Tari {

    // MARK: - Constants

    private let logFilePrefix = "log"

    // MARK: - Properties

    static let shared = Tari()

    let connectionMonitor = ConnectionMonitor()

    private(set) lazy var logFilePath: String = {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        return "\(TariSettings.storageDirectory.path)/\(logFilePrefix)-\(timestamp).txt"
    }()

    private var passphrase: String {
        guard let passphrase = AppKeychainWrapper.dbPassphrase else {
            let newPassphrase = String.random(length: 32)
            AppKeychainWrapper.dbPassphrase = newPassphrase
            return newPassphrase
        }
        return passphrase
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

    @Published private(set) var torError: TorError?
    @Published private(set) var blockHeight: UInt64 = NetworkManager.shared.blockHeight

    var canAutomaticalyReconnectWallet: Bool = false
    @Published var isDisconnectionDisabled: Bool = false

    private var wallets: [WalletContainer] = []

    private lazy var torManager = TorManager(logPath: logFilePath)
    private var cancellables = Set<AnyCancellable>()

    func update(torBridges: String?) {
        torManager.update(bridges: torBridges)
    }

    // MARK: - Initialisers

    private init() {
        connectionMonitor.setupPublishers(
            torConnectionStatus: torManager.$connectionStatus.eraseToAnyPublisher(),
            torBootstrapProgress: torManager.$bootstrapProgress.eraseToAnyPublisher(),
            baseNodeConnectionStatus: wallet(.main).connectionCallbacks.$baseNodeConnectionStatus.eraseToAnyPublisher(),
            scannedHeight: wallet(.main).connectionCallbacks.$scannedHeight.eraseToAnyPublisher(),
            blockHeight: $blockHeight.eraseToAnyPublisher(),
            baseNodeSyncStatus: wallet(.main).validation.$status.eraseToAnyPublisher()
        )
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

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

        WalletCallbacksManager.shared.baseNodeState
            .compactMap { try? $0.heightOfTheLongestChain }
            .removeDuplicates()
            .sink { [weak self] in
                NetworkManager.shared.blockHeight = $0
                self?.blockHeight = $0
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func start(wallet tag: WalletTag) async throws {
        await waitForTor()
        guard await UIApplication.shared.applicationState != .background else { return }
        try start(tag, seedWords: nil)
    }

    func restoreWallet(seedWords: [String]) throws {
        try start(.main, seedWords: seedWords)
    }

    func deleteWallet() {
        removeWallet(tag: .main)
        try? deleteAllLogs()
        walletContainer(.main).stop()
        removeSettings()
    }

    func select(network: TariNetwork) {
        walletContainer(.main).stop()
        removeSettings()
        NetworkManager.shared.selectedNetwork = network
    }

    func log(message: String) {
        try? wallet(.main).log(message: message)
    }

    private func connect() {
        torManager.start()
        guard canAutomaticalyReconnectWallet, !wallet(.main).isWalletRunning.value else { return }
        Task {
            try? await start(wallet: .main)
        }
    }

    private func disconnect() {
        walletContainer(.main).stop()
        torManager.stop()
    }

    private func start(_ tag: WalletTag, seedWords: [String]?) throws {
        try walletContainer(tag).start(seedWords: seedWords, logPath: logFilePath, passphrase: passphrase)
        resetServices()
    }

    private func waitForTor() async {
        return await withCheckedContinuation { continuation in
            Tari.shared.connectionMonitor.$torConnection
                .filter { $0 == .waitingForAuthorization || $0 == .portsOpen || $0 == .connected }
                .first()
                .sink { _ in continuation.resume() }
                .store(in: &cancellables)
        }
    }

    private func resetServices() {
        Tari.shared.wallet(.main).walletBalance.reset()
        Tari.shared.wallet(.main).transactions.reset()
    }

    private func removeSettings() {
        UserDefaults.standard.removeAll()
        NetworkManager.shared.removeSelectedNetworkSettings()
    }

    private func deleteAllLogs() throws {
        try logsURLs.forEach { try FileManager.default.removeItem(at: $0) }
    }

    // MARK: - Helpers

    func wallet(_ tag: String) -> WalletInteractable { walletContainer(tag) }

    private func fetchWallet(tag: String, torCookie: Data, controlServerAddress: String) -> WalletContainer {

        guard let wallet = wallets.first(where: { $0.tag == tag }) else {
            let wallet = WalletContainer(tag: tag, torCookie: torCookie, controlServerAddress: controlServerAddress)
            wallets.append(wallet)
            return wallet
        }

        wallet.update(torCookie: torCookie)
        return wallet
    }

    private func walletContainer(_ tag: String) -> WalletContainer {
        let torCookie = try? torManager.controlAuthCookie()
        return fetchWallet(tag: tag, torCookie: torCookie ?? Data(), controlServerAddress: torManager.controlServerAddress)
    }

    private func removeWallet(tag: String) {
        try? walletContainer(tag).deleteWallet()
        wallets.removeAll { $0.tag == tag }
    }
}

extension Tari {
    func wallet(_ tag: WalletTag) -> WalletInteractable { wallet(tag.rawValue) }
    private func walletContainer(_ tag: WalletTag) -> WalletContainer { walletContainer(tag.rawValue) }
    private func removeWallet(tag: WalletTag) { removeWallet(tag: tag.rawValue) }
}
