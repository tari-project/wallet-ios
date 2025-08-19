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
    static let mainWallet = shared.wallet(.main)

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

    @Published private(set) var containerCreated: String?

    var canAutomaticalyReconnectWallet: Bool = false
    @Published var isDisconnectionDisabled: Bool = false

    private var wallets: [WalletContainer] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    private init() {
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
    }

    // MARK: - Actions

    func start(wallet tag: String) async throws {
//        await waitForTor()
        guard await UIApplication.shared.applicationState != .background else { return }
        try start(tag, seedWords: nil)
    }

    func restore(wallet tag: String, seedWords: [String]) throws {
        try start(tag, seedWords: seedWords)
    }

    func delete(wallet tag: String) {
        walletContainer(tag).stop()
        removeWallet(tag: tag)
        try? deleteAllLogs()
        removeSettings()
    }

    func select(network: TariNetwork) {
        wallets.forEach { $0.stop() }
        removeSettings()
        NetworkManager.shared.selectedNetwork = network
    }

    func log(wallet tag: String, message: String) {
        try? wallet(tag).log(message: message)
    }

    private func connect() {
        guard canAutomaticalyReconnectWallet else { return }
        wallets.forEach { connect(tag: $0.tag) }
    }

    private func connect(tag: String) {
        guard !wallet(tag).isWalletRunning.value else { return }
        Task {
            try? await start(wallet: tag)
        }
    }

    private func disconnect() {
        wallets.forEach { $0.stop() }
    }

    private func start(_ tag: String, seedWords: [String]?) throws {
        try walletContainer(tag).start(seedWords: seedWords, logPath: logFilePath, passphrase: passphrase)
        resetServices(tag)
    }

    private func resetServices(_ tag: String) {
        wallet(tag).walletBalance.reset()
        wallet(tag).transactions.reset()
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

    private func fetchWallet(tag: String) -> WalletContainer {
        guard let wallet = wallets.first(where: { $0.tag == tag }) else {
            let wallet = WalletContainer(tag: tag)
            wallets.append(wallet)
            containerCreated = tag
            return wallet
        }
        return wallet
    }

    private func walletContainer(_ tag: String) -> WalletContainer {
        fetchWallet(tag: tag)
    }

    private func removeWallet(tag: String) {
        try? walletContainer(tag).deleteWallet()
        wallets.removeAll { $0.tag == tag }
    }
}

extension Tari {
    func wallet(_ tag: WalletTag) -> WalletInteractable { wallet(tag.rawValue) }
    func start(wallet tag: WalletTag) async throws { try await start(wallet: tag.rawValue) }
    func restore(wallet tag: WalletTag, seedWords: [String]) throws { try restore(wallet: tag.rawValue, seedWords: seedWords) }
    func delete(wallet tag: WalletTag) { delete(wallet: tag.rawValue) }
    func log(wallet tag: WalletTag, message: String) { log(wallet: tag.rawValue, message: message) }
}
