//  TariTransactionsService.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 04/10/2022
	Using Swift 5.0
	Running on macOS 12.4

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

final class TariTransactionsService: CoreTariService {

    enum InternalError: Error {
        case insufficientFunds(spendableMicroTari: UInt64)
    }

    // MARK: - Properties

    @Published private(set) var completed: [CompletedTransaction] = []
    @Published private(set) var cancelled: [CompletedTransaction] = []
    @Published private(set) var pendingInbound: [PendingInboundTransaction] = []
    @Published private(set) var pendingOutbound: [PendingOutboundTransaction] = []
    @Published private(set) var all: [Transaction] = []
    @Published private(set) var error: Error?

    @Published private(set) var receivedTransactionReply: CompletedTransaction?
    @Published private(set) var receivedFinalizedTransaction: CompletedTransaction?
    @Published private(set) var transactionBroadcast: CompletedTransaction?
    @Published private(set) var unconfirmedTransactionMined: CompletedTransaction?
    @Published private(set) var transactionMined: CompletedTransaction?
    @Published private(set) var transactionSendResult: TransactionSendResult?

    var requiredConfirmationsCount: UInt64 {
        get throws { try walletManager.requiredConfirmationsCount() }
    }

    private var completedTransactions: [CompletedTransaction] {
        get throws {
            let transactions = try walletManager.completedTransactions()
            let count = try transactions.count
            return try (0..<count).map { try transactions.transaction(at: $0, isCancelled: false) }
        }
    }

    private var cancelledTransactions: [CompletedTransaction] {
        get throws {
            let transactions = try walletManager.cancelledTransactions()
            let count = try transactions.count
            return try (0..<count).map { try transactions.transaction(at: $0, isCancelled: true) }
        }
    }

    private var pendingInboundTransactions: [PendingInboundTransaction] {
        get throws {
            let transactions = try walletManager.pendingInboundTransactions()
            let count = try transactions.count
            return try (0..<count).map { try transactions.transaction(at: $0) }
        }
    }

    private var pendingOutboundTransactions: [PendingOutboundTransaction] {
        get throws {
            let transactions = try walletManager.pendingOutboundTransactions()
            let count = try transactions.count
            return try (0..<count).map { try transactions.transaction(at: $0) }
        }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialiser

    override init(walletManager: FFIWalletHandler, walletCallbacks: WalletCallbacks, services: MainServiceable) {
        super.init(walletManager: walletManager, walletCallbacks: walletCallbacks, services: services)
        fetchData()
        setupCallbacks()
    }

    // MARK: - Setups

    func fetchData() {
        do {
            let completed = try completedTransactions
            let cancelled = try cancelledTransactions
            let pendingInbound = try pendingInboundTransactions
            let pendingOutbound = try pendingOutboundTransactions

            Task { @MainActor in
                self.completed = completed
                self.cancelled = cancelled
                self.pendingInbound = pendingInbound
                self.pendingOutbound = pendingOutbound
                self.all = try (completed + cancelled + pendingInbound + pendingOutbound)
                    .sorted { try $0.timestamp > $1.timestamp }
            }
        } catch {
            self.error = error
        }
    }

    private func setupCallbacks() {

        walletCallbacks.receivedTransaction
            .sink { [weak self] _ in self?.fetchData() }
            .store(in: &cancellables)

        walletCallbacks.receivedTransactionReply
            .sink { [weak self] in
                self?.fetchData()
                self?.receivedTransactionReply = $0
            }
            .store(in: &cancellables)

        walletCallbacks.receivedFinalizedTransaction
            .sink { [weak self] in
                self?.fetchData()
                self?.receivedFinalizedTransaction = $0
            }
            .store(in: &cancellables)

        walletCallbacks.transactionBroadcast
            .sink { [weak self] in
                self?.fetchData()
                self?.transactionBroadcast = $0
            }
            .store(in: &cancellables)

        walletCallbacks.transactionMined
            .sink { [weak self] in
                self?.fetchData()
                self?.transactionMined = $0
            }
            .store(in: &cancellables)

        walletCallbacks.unconfirmedTransactionMined
            .sink { [weak self] in
                self?.fetchData()
                self?.unconfirmedTransactionMined = $0
            }
            .store(in: &cancellables)

        walletCallbacks.fauxTransactionConfirmed
            .sink { [weak self] _ in self?.fetchData() }
            .store(in: &cancellables)

        walletCallbacks.fauxTransactionUnconfirmed
            .sink { [weak self] _ in self?.fetchData() }
            .store(in: &cancellables)

        walletCallbacks.transactionSendResult
            .sink { [weak self] in
                self?.fetchData()
                self?.transactionSendResult = $0
            }
            .store(in: &cancellables)

        walletCallbacks.transactionCancellation
            .sink { [weak self] _ in self?.fetchData() }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func reset() {
        fetchData()
    }

    func cancelPendingTransaction(identifier: UInt64) throws -> Bool {
        try walletManager.cancelPendingTransaction(identifier: identifier)
    }

    func send(toAddress address: TariAddress, amount: UInt64, feePerGram: UInt64, isOneSidedPayment: Bool, paymentID: String,
              kernelsCount: UInt32 = TariConstants.defaultKernelCount, outputsCount: UInt32 = TariConstants.defaultOutputCount) throws -> UInt64 {

        let estimatedFee = try walletManager.feeEstimate(amount: amount, feePerGram: feePerGram, kernelsCount: kernelsCount, outputsCount: outputsCount)
        let total = estimatedFee + amount
        let availableBalance = services.walletBalance.balance.available

        guard availableBalance >= total else {
            throw InternalError.insufficientFunds(spendableMicroTari: availableBalance)
        }

        return try walletManager.sendTransaction(address: address, amount: amount, feePerGram: feePerGram, isOneSidedPayment: isOneSidedPayment, paymentID: paymentID)
    }
    
    func paymentReference(transaction: Transaction) throws -> PaymentReference? {
        try walletManager.paymentReference(transaction: transaction)
    }
    
    func transaction(id: UInt64) -> Transaction? {
        all.first { (try? $0.identifier) == id }
    }
}

extension TariTransactionsService {

    var onUpdate: AnyPublisher<Void, Never> {
        $all
            .onChangePublisher()
            .eraseToAnyPublisher()
    }
}
