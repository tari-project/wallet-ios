//  TransactionHistoryModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 05/07/2023
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

import Combine

final class TransactionHistoryModel {

    struct TransactionsSection {
        let title: String?
        let transactions: [TransactionFormatter.Model]
    }

    // MARK: - View Model

    @Published var searchText = ""

    @Published private(set) var transactions: [TransactionsSection] = []
    @Published private(set) var selectedTransaction: Transaction?

    // MARK: - Properties

    private var transactionFormatter = TransactionFormatter()
    private var allTransactions: [Transaction] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        let pendingTransactionsPublisher = Publishers.CombineLatest(Tari.shared.transactions.$pendingInbound, Tari.shared.transactions.$pendingOutbound)
            .map { $0 as [Transaction] + $1 }
            .tryMap { try $0.sorted { try $0.timestamp > $1.timestamp }}
            .replaceError(with: [])

        let completedTransactionsPublisher = Publishers.CombineLatest(Tari.shared.transactions.$completed, Tari.shared.transactions.$cancelled)
            .map { $0 + $1 }
            .tryMap { try $0.sorted { try $0.timestamp > $1.timestamp }}
            .replaceError(with: [])

        Publishers.CombineLatest3(pendingTransactionsPublisher, completedTransactionsPublisher, $searchText)
            .sink { [weak self] in self?.handle(pendingTransactions: $0, completedTransactions: $1, searchText: $2) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func select(transactionID: UInt64) {
        selectedTransaction = try? allTransactions.first(where: { try $0.identifier == transactionID })
    }

    // MARK: - Handlers

    private func handle(pendingTransactions: [Transaction], completedTransactions: [Transaction], searchText: String) {

        allTransactions = pendingTransactions + completedTransactions

        Task {
            try? await transactionFormatter.updateContactsData()

            let pendingTransactionModels = map(transactions: pendingTransactions, searchText: searchText)
            let completedTransactionsModels = map(transactions: completedTransactions, searchText: searchText)
            var models: [TransactionsSection] = []

            if !pendingTransactionModels.isEmpty {
                models.append(TransactionsSection(title: localized("transaction_history.section.pending"), transactions: pendingTransactionModels))
            }

            if !completedTransactionsModels.isEmpty {
                models.append(TransactionsSection(title: localized("transaction_history.section.completed"), transactions: completedTransactionsModels))
            }

            transactions = models
        }
    }

    private func map(transactions: [Transaction], searchText: String) -> [TransactionFormatter.Model] {
        transactions.compactMap { [weak self] in try? self?.transactionFormatter.model(transaction: $0, filter: searchText) }
    }
}
