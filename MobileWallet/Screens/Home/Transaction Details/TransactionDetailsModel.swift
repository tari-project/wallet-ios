//  TransactionDetailsModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 15/03/2022
	Using Swift 5.0
	Running on macOS 12.2

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
import GiphyUISDK

final class TransactionDetailsModel {

    // MARK: - View Model

    @Published private(set) var title: String?
    @Published private(set) var subtitle: String?
    @Published private(set) var transactionState: AnimatedRefreshingViewState?
    @Published private(set) var amount: String?
    @Published private(set) var fee: String?
    @Published private(set) var transactionDirection: String?
    @Published private(set) var emojiIdViewModel: EmojiIdView.ViewModel?
    @Published private(set) var userAlias: String?
    @Published private(set) var isContactSectionVisible: Bool = true
    @Published private(set) var isAddContactButtonVisible: Bool = true
    @Published private(set) var isNameSectionVisible: Bool = false
    @Published private(set) var note: String?
    @Published private(set) var gifMedia: GPHMedia?
    @Published private(set) var wasTransactionCanceled: Bool = false
    @Published private(set) var errorModel: MessageModel?
    @Published private(set) var isBlockExplorerActionAvailable: Bool = false
    @Published private(set) var linkToOpen: URL?

    var userAliasUpdateSuccessCallback: (() -> Void)?

    // MARK: - Properties

    private var transaction: Transaction
    private var transactionNounce: String?
    private var transactionSignature: String?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(transaction: Transaction) {
        self.transaction = transaction
        setupCallbacks()
        fetchData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        let events = [
            WalletCallbacksManager.shared.receivedTransactionReply,
            WalletCallbacksManager.shared.receivedFinalizedTransaction,
            WalletCallbacksManager.shared.transactionBroadcast,
            WalletCallbacksManager.shared.unconfirmedTransactionMined,
            WalletCallbacksManager.shared.transactionMined
        ]

        events.forEach {
            $0
                .filter { [unowned self] in (try? $0.identifier) == (try? self.transaction.identifier) }
                .sink { [weak self] in self?.handle(transaction: $0) }
                .store(in: &cancellables)
        }
    }

    // MARK: - Actions

    private func fetchData() {

        do {
            title = try fetchTitle()
            transactionState = try fetchTransactionState()
            transactionDirection = try fetchTransactionDirection()
            emojiIdViewModel = try fetchEmojiIdViewModel()
            isContactSectionVisible = try !transaction.isOneSidedPayment
            subtitle = try fetchSubtitle()
            amount = try fetchAmount()
            fee = try fetchFee()
            userAlias = try fetchUserAlias()
            try handleMessage()
        } catch {
            errorModel = MessageModel(title: localized("tx_detail.error.load_tx.title"), message: localized("tx_detail.error.load_tx.description"), type: .error)
        }

        handleTransactionKernel()

        isAddContactButtonVisible = userAlias == nil
        isNameSectionVisible = userAlias != nil
    }

    func cancelTransactionRequest() {

        do {
            guard try transaction.status == .pending, try transaction.isOutboundTransaction else {
                errorModel = MessageModel(title: localized("tx_detail.tx_cancellation.error.title"), message: localized("tx_detail.tx_cancellation.error.description"), type: .error)
                return
            }
            wasTransactionCanceled = try Tari.shared.transactions.cancelPendingTransaction(identifier: transaction.identifier)
        } catch {
            errorModel = MessageModel(title: localized("tx_detail.tx_cancellation.error.title"), message: nil, type: .error)
        }
    }

    func addContactAliasRequest() {
        isAddContactButtonVisible = false
        isNameSectionVisible = true
    }

    func update(alias: String?) {

        guard let alias = alias, !alias.isEmpty else { return }

        do {
            let address = try transaction.address
            let isFavorite: Bool

            if let existingContact = try Tari.shared.contacts.findContact(hex: address.byteVector.hex) {
                isFavorite = try existingContact.isFavorite
            } else {
                isFavorite = false
            }

            let contact = try Contact(alias: alias, isFavorite: isFavorite, addressPointer: address.pointer)
            _ = try Tari.shared.contacts.upsert(contact: contact)
            userAliasUpdateSuccessCallback?()
            userAlias = alias
        } catch {
            errorModel = MessageModel(title: localized("tx_detail.error.contact.title"), message: localized("tx_detail.error.save_contact.description"), type: .error)
            resetAlias()
        }
    }

    func resetAlias() {
        userAlias = userAlias
    }

    func requestLinkToBlockExplorer() {
        linkToOpen = fetchLinkToOpen()
    }

    // MARK: - Helpers

    private func fetchTitle() throws -> String? {

        if transaction.isCancelled {
            return localized("tx_detail.payment_cancelled")
        }

        switch try transaction.status {
        case .txNullError, .completed, .broadcast, .minedUnconfirmed, .pending, .unknown:
            return localized("tx_detail.payment_in_progress")
        case .minedConfirmed, .imported, .rejected, .fauxUnconfirmed, .fauxConfirmed:
            return try transaction.isOutboundTransaction ? localized("tx_detail.payment_sent") : localized("tx_detail.payment_received")
        }
    }

    private func fetchSubtitle() throws -> String {

        var formattedDate: String?

        if let timestamp = try? transaction.timestamp {
            formattedDate = Date(timeIntervalSince1970: TimeInterval(timestamp)).formattedDisplay()
        }

        var failureReason: String?

        if let completedTransaction = transaction as? CompletedTransaction, let description = try completedTransaction.rejectionReason.description {
            failureReason = description
        }

        return [failureReason, formattedDate]
            .compactMap { $0 }
            .joined(separator: "\n")
    }

    private func fetchTransactionState() throws -> AnimatedRefreshingViewState? {

        guard !transaction.isCancelled else {
            return nil
        }

        switch try transaction.status {
        case .pending:
            return try transaction.isOutboundTransaction ? .txWaitingForRecipient : .txWaitingForSender
        case .broadcast, .completed:
            return .txCompleted(confirmationCount: 1)
        case .minedUnconfirmed:
            guard let confirmationCount = try (transaction as? CompletedTransaction)?.confirmationCount else {
                return .txCompleted(confirmationCount: 1)
            }
            return .txCompleted(confirmationCount: confirmationCount + 1)
        case .txNullError, .imported, .minedConfirmed, .unknown, .rejected, .fauxUnconfirmed, .fauxConfirmed:
            return nil
        }
    }

    private func fetchTransactionDirection() throws -> String? {
        try transaction.isOutboundTransaction ? localized("tx_detail.to") : localized("tx_detail.from")
    }

    private func fetchAmount() throws -> String {
        let amount = try transaction.amount
        return MicroTari(amount).formattedPrecise
    }

    private func fetchFee() throws -> String? {
        guard try transaction.isOutboundTransaction, let fee = try (transaction as? CompletedTransaction)?.fee ?? (transaction as? PendingOutboundTransaction)?.fee else { return nil }
        return MicroTari(fee).formattedWithOperator
    }

    private func fetchEmojiIdViewModel() throws -> EmojiIdView.ViewModel {
        let address = try transaction.address
        let emojiID = try address.emojis
        let hex = try address.byteVector.hex
        return EmojiIdView.ViewModel(emojiID: emojiID, hex: hex)
    }

    private func fetchUserAlias() throws -> String? {
        let contact = try Tari.shared.contacts.findContact(hex: try transaction.address.byteVector.hex)
        return try contact?.alias
    }

    private func handle(transaction: Transaction) {
        self.transaction = transaction
        fetchData()
    }

    private func handleMessage() throws {

        guard try !transaction.isOneSidedPayment else {
            note = localized("transaction.one_sided_payment.note.normal")
            gifMedia = nil
            return
        }

        let message = try transaction.message
        let giphyLinkPrefix = "https://giphy.com/embed/"

        guard let endIndex = message.range(of: giphyLinkPrefix)?.lowerBound else {
            note = message
            gifMedia = nil
            return
        }

        let messageNote = message[..<endIndex].trimmingCharacters(in: .whitespaces)
        let link = message[endIndex...].trimmingCharacters(in: .whitespaces)
        let gifID = link.replacingOccurrences(of: giphyLinkPrefix, with: "")

        GiphyCore.shared.gifByID(gifID) { [weak self] response, error in

            if let error = error {
                Logger.log(message: "Failed to load gif: \(error.localizedDescription)", domain: .general, level: .error)
                return
            }

            guard let data = response?.data else { return }
            self?.gifMedia = data
        }

        note = messageNote
    }

    private func handleTransactionKernel() {

        defer {
            isBlockExplorerActionAvailable = transactionNounce != nil && transactionSignature != nil
        }

        guard let kernel = try? (transaction as? CompletedTransaction)?.transactionKernel else {
            transactionNounce = nil
            transactionSignature = nil
            return
        }

        transactionNounce = try? kernel.excessPublicNonceHex
        transactionSignature = try? kernel.excessSignatureHex
    }

    private func fetchLinkToOpen() -> URL? {
        guard let transactionNounce = transactionNounce, let transactionSignature = transactionSignature else { return nil }
        let request = [transactionNounce, transactionSignature].joined(separator: "/")
        return URL(string: TariSettings.shared.blockExplorerKernelUrl + "\(request)")
    }
}

private extension CompletedTransaction.RejectionReason {

    var description: String? {
        switch self {
        case .notCancelled:
            return nil
        case .unknown:
            return localized("error.tx_rejection.0")
        case .userCancelled:
            return localized("error.tx_rejection.1")
        case .timeout:
            return localized("error.tx_rejection.2")
        case .doubleSpend:
            return localized("error.tx_rejection.3")
        case .orphan:
            return localized("error.tx_rejection.4")
        case .timeLocked:
            return localized("error.tx_rejection.5")
        case .invalidTransaction:
            return localized("error.tx_rejection.6")
        case .abandonedCoinbase:
            return localized("error.tx_rejection.7")
        }
    }
}
