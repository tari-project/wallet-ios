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
    @Published private(set) var recentTransactions: [HomeViewTransactionCell.ViewModel] = []

    // MARK: - Properties

    private let onContactUpdated = PassthroughSubject<Void, Never>()

    private var contactsManager = ContactsManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
        updateContactsData()
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

        let transactionsPublisher = Publishers.CombineLatest4(Tari.shared.transactions.$completed, Tari.shared.transactions.$cancelled, Tari.shared.transactions.$pendingInbound, Tari.shared.transactions.$pendingOutbound)
            .map { $0 as [Transaction] + $1 + $2 + $3 }
            .tryMap { try $0.sorted { try $0.timestamp > $1.timestamp }}
            .replaceError(with: [Transaction]())

        Publishers.CombineLatest(transactionsPublisher, onContactUpdated)
            .compactMap { [weak self] in self?.removeDuplicates(transactions: $0.0) }
            .compactMap { [weak self] in self?.mapTransactionViewModels(transactions: $0) }
            .sink { [weak self] in self?.recentTransactions = $0 }
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
    }

    func executeQueuedShortcut() {
        ShortcutsManager.executeQueuedShortcut()
    }

    // MARK: - Handlers

    private func handle(networkConnection: NetworkMonitor.Status, torConnection: TorManager.ConnectionStatus, baseNodeConnection: BaseNodeConnectivityStatus, syncStatus: TariValidationService.SyncStatus) {

        switch (networkConnection, torConnection, baseNodeConnection, syncStatus) {
        case (.disconnected, _, _, _),
            (.connected, .disconnected, _, _),
            (.connected, .disconnecting, _, _):
            connectionStatusIcon = .icons.network.off
        case (.connected, .connecting, _, _),
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
        balance = MicroTari(walletBalance.available + walletBalance.incoming).formatted
        availableBalance = MicroTari(walletBalance.available).formatted
    }

    private func mapTransactionViewModels(transactions: [Transaction]) -> [HomeViewTransactionCell.ViewModel] {
        transactions[0..<min(2, transactions.count)]
            .compactMap {
                try? HomeViewTransactionCell.ViewModel(
                    id: $0.identifier,
                    titleComponents: makeTransactionTitleComponents(transaction: $0),
                    timestamp: $0.formattedTimestamp,
                    amount: makeAmountViewModel(transaction: $0)
                )
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

    // MARK: - Helpers

    private func removeDuplicates(transactions: [Transaction]) -> [Transaction] {

        var uniqueTransactions: [Transaction] = []

        transactions.forEach {
            guard let identifier = try? $0.identifier, uniqueTransactions.first(where: { (try? $0.identifier) == identifier }) == nil else { return }
            uniqueTransactions.append($0)
        }

        return uniqueTransactions
    }

    private func makeTransactionTitleComponents(transaction: Transaction) throws -> [StylizedLabel.StylizedText] {

        let hex = try transaction.address.byteVector.hex
        let name = contactsManager.tariContactModels.first { $0.internalModel?.hex == hex }?.name ?? localized("transaction.one_sided_payment.inbound_user_placeholder")

        if try transaction.isOutboundTransaction {
            return [
                StylizedLabel.StylizedText(text: localized("transaction.normal.title.outbound.part.1"), style: .normal),
                StylizedLabel.StylizedText(text: name, style: .bold)
            ]
        } else {

            let name = try transaction.isOneSidedPayment ? localized("transaction.one_sided_payment.inbound_user_placeholder") : name
            let text = transaction.isPending ? localized("transaction.normal.title.pending.part.2") : localized("transaction.normal.title.inbound.part.2")

            return [
                StylizedLabel.StylizedText(text: name, style: .bold),
                StylizedLabel.StylizedText(text: text, style: .normal)
            ]
        }
    }

    private func makeAmountViewModel(transaction: Transaction) throws -> AmountBadge.ViewModel {

        let amount = try MicroTari(transaction.amount).formattedWithNegativeOperator

        let valueType: AmountBadge.ValueType

        if transaction.isCancelled {
            valueType = .invalidated
        } else if transaction.isPending {
            valueType = .waiting
        } else if try transaction.isOutboundTransaction {
            valueType = .negative
        } else {
            valueType = .positive
        }

        return AmountBadge.ViewModel(amount: amount, valueType: valueType)
    }
}
