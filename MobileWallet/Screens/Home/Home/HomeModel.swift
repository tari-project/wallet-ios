//  HomeModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 22/06/2023
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

import UIKit
import Combine

final class HomeModel {

    // MARK: - View Model

    @Published private(set) var connectionStatusIcon: UIImage?
    @Published private(set) var balance: String = ""
    @Published private(set) var availableBalance: String = ""
    @Published private(set) var avatar: String = ""
    @Published private(set) var username: String = ""
    @Published private(set) var recentTransactions: [TransactionFormatter.Model] = []
    @Published private(set) var selectedTransaction: Transaction?

    // MARK: - Properties

    private let onContactUpdated = PassthroughSubject<Void, Never>()

    private let contactsManager = ContactsManager()
    private let transactionFormatter = TransactionFormatter()
    private var recentWalletTransactions: [Transaction] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        let monitor = Tari.shared.connectionMonitor

        Publishers.CombineLatest4(monitor.$networkConnection, monitor.$torConnection, monitor.$baseNodeConnection, monitor.$syncStatus)
            .sink { [weak self] in self?.handle(networkConnection: $0, torConnection: $1, baseNodeConnection: $2, syncStatus: $3) }
            .store(in: &cancellables)

        Tari.shared.walletBalance.$balance
            .sink { [weak self] in self?.handle(walletBalance: $0) }
            .store(in: &cancellables)

        Tari.shared.$isWalletConnected
            .filter { $0 }
            .sink { [weak self] _ in self?.updateAvatar() }
            .store(in: &cancellables)

        let transactionsPublisher = Tari.shared.transactions.$all
            .map { $0.filterDuplicates() }
            .replaceError(with: [Transaction]())

        Publishers.CombineLatest(transactionsPublisher, onContactUpdated)
            .sink { [weak self] in self?.handle(transactions: $0.0) }
            .store(in: &cancellables)
    }

    private func updateContactsData() {
        Task {
            try await contactsManager.fetchModels()
            onContactUpdated.send(())
        }
    }

    // MARK: - Actions

    func runManagers() {
        NotificationManager.shared.requestAuthorization()
        StagedWalletSecurityManager.shared.start()
        BLEPeripheralManager.shared.isEnabled = true
    }

    func executeQueuedShortcut() {
        ShortcutsManager.executeQueuedShortcut()
    }

    func select(transactionID: UInt64) {
        selectedTransaction = try? recentWalletTransactions.first { try $0.identifier == transactionID }
    }

    func updateData() {
        updateContactsData()
    }

    // MARK: - Handlers

    private func handle(networkConnection: NetworkMonitor.Status, torConnection: TorConnectionStatus, baseNodeConnection: BaseNodeConnectivityStatus, syncStatus: TariValidationService.SyncStatus) {

        switch (networkConnection, torConnection, baseNodeConnection, syncStatus) {
        case (.disconnected, _, _, _),
            (.connected, .disconnected, _, _),
            (.connected, .disconnecting, _, _):
            connectionStatusIcon = .icons.network.off
        case (.connected, .connecting, _, _),
            (.connected, .waitingForAuthorization, _, _),
            (.connected, .portsOpen, _, _),
            (.connected, .connected, .offline, _),
            (.connected, .connected, .connecting, _),
            (.connected, .connected, .online, .idle),
            (.connected, .connected, .online, .failed):
            connectionStatusIcon = .icons.network.limited
        case (.connected, .connected, .online, .syncing),
            (.connected, .connected, .online, .synced):
            connectionStatusIcon = .icons.network.full
        }
    }

    private func handle(walletBalance: WalletBalance) {
        balance = MicroTari(walletBalance.total).formatted
        availableBalance = MicroTari(walletBalance.availableToSpend).formatted
    }

    private func handle(transactions: [Transaction]) {
        Task {
            try? await transactionFormatter.updateContactsData()
            recentWalletTransactions = transactions
            recentTransactions = transactions[0..<min(2, transactions.count)].compactMap { try? transactionFormatter.model(transaction: $0) }
        }
    }

    private func updateAvatar() {

        guard let emojis = try? Tari.shared.walletAddress.emojis else {
            avatar = ""
            username = ""
            return
        }

        avatar = emojis.firstOrEmpty
        username = emojis.obfuscatedText
    }
}
