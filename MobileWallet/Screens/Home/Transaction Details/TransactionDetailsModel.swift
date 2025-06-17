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
    @Published private(set) var total: String?
    @Published private(set) var transactionDirection: String?
    @Published private(set) var paymentReference: PaymentReference?
    @Published private(set) var addressComponents: TariAddressComponents?
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
    @Published private(set) var timestamp: TimeInterval?
    @Published private(set) var identifier: String?
    @Published private(set) var status: TransactionStatus?
    @Published private(set) var statusText: String?
    @Published private(set) var isCoinbase: Bool = false
    @Published private(set) var isEmojiFormat: Bool = true
    @Published private(set) var isInbound: Bool = false
    @Published private(set) var walletBlockHeight: UInt64 = 0

    var isContactExist: Bool { contactModel?.isFFIContact == true }
    var contactHaveSplittedName: Bool { contactModel?.hasIntrenalModel ?? false }
    var contactAlias: String? { contactModel?.alias }

    var userAliasUpdateSuccessCallback: (() -> Void)?

    // MARK: - Properties

    private let contactsManager = ContactsManager()
    weak var presenter: UIViewController?

    private var transaction: Transaction
    private var contactModel: ContactsManager.Model?
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
    private func transactions() -> TariTransactionsService {
        Tari.shared.wallet(.main).transactions
    }

    private func setupCallbacks() {
        let service = transactions()

        Publishers.Merge5(service.$receivedTransactionReply, service.$receivedFinalizedTransaction, service.$transactionBroadcast, service.$unconfirmedTransactionMined, service.$transactionMined)
            .compactMap { $0 }
            .filter { [weak self] in (try? $0.identifier) == (try? self?.transaction.identifier) }
            .sink { [weak self] in self?.handle(transaction: $0) }
            .store(in: &cancellables)
        
        Tari.shared.wallet(.main).connectionCallbacks
            .$blockHeight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.walletBlockHeight = $0 }
            .store(in: &cancellables)
        
        $userAlias
            .map { $0 != nil }
            .sink { [weak self] in self?.handle(isUserAliasExist: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func fetchData() {

        do {
            title = try fetchTitle()
            transactionState = try fetchTransactionState()
            transactionDirection = try fetchTransactionDirection()
            addressComponents = try fetchAddressComponents()
            isContactSectionVisible = try !transaction.isOneSidedPayment && !transaction.isCoinbase
            isCoinbase = try transaction.isCoinbase
            subtitle = try fetchSubtitle()
            amount = try fetchAmount()
            fee = try fetchFee()
            if let ts = try? transaction.timestamp {
                timestamp = TimeInterval(ts)
            }
            if let id = try? transaction.identifier {
                identifier = String(id)
            }
            status = try? transaction.status
            statusText = try fetchStatusText()

            // Hide note for coinbase transactions
            if try !transaction.isCoinbase {
                try handleMessage()
            } else {
                note = nil
                gifMedia = nil
            }

            updateContactData()

            // Calculate total
            if let amount = try? transaction.amount, let fee = try? (transaction as? CompletedTransaction)?.fee ?? (transaction as? PendingOutboundTransaction)?.fee {
                let totalAmount = MicroTari(amount + fee)
                total = totalAmount.formattedPrecise + " " + NetworkManager.shared.currencySymbol
            }

            isInbound = (try? transaction.isOutboundTransaction) == false
            paymentReference = try transactions().paymentReference(transaction: transaction)
        } catch {
            errorModel = MessageModel(title: localized("tx_detail.error.load_tx.title"), message: localized("tx_detail.error.load_tx.description"), type: .error)
        }

        handleTransactionKernel()
    }

    func cancelTransactionRequest() {

        do {
            guard try transaction.status == .pending, try transaction.isOutboundTransaction else {
                errorModel = MessageModel(title: localized("tx_detail.tx_cancellation.error.title"), message: localized("tx_detail.tx_cancellation.error.description"), type: .error)
                return
            }
            wasTransactionCanceled = try transactions().cancelPendingTransaction(identifier: transaction.identifier)
        } catch {
            errorModel = MessageModel(title: localized("tx_detail.tx_cancellation.error.title"), message: nil, type: .error)
        }
    }

    func handleAddContactRequest() {
        isAddContactButtonVisible = false
        isNameSectionVisible = true
    }

    func handleEditContactRequest() {
        guard let contactModel = contactModel,
              let presenter = presenter else { return }

        let alias = contactModel.name
        Task { @MainActor in
            FormOverlayPresenter.showSingleFieldContactEditForm(isContactExist: true, alias: alias, presenter: presenter) { [weak self] alias in
                self?.update(alias: alias)
            }
        }
    }

    func handleRemoveContactRequest() {
        guard contactModel != nil else { return }

        let model = PopUpDialogModel(
            title: localized("contact_book.details.popup.delete_contact.title"),
            message: localized("contact_book.details.popup.delete_contact.message"),
            buttons: [
                PopUpDialogButtonModel(title: localized("contact_book.details.popup.delete_contact.button.ok"), type: .destructive, callback: { [weak self] in
                    self?.removeContact()
                }),
                PopUpDialogButtonModel(title: localized("common.cancel"), type: .text)
            ],
            hapticType: .none
        )

        Task { @MainActor in
            PopUpPresenter.showPopUp(model: model)
        }
    }

    private func removeContact() {
        do {
            guard let contactModel = contactModel else { return }
            try contactsManager.remove(contact: contactModel)
            self.contactModel = nil
            updateAlias()
        } catch {
            errorModel = MessageModel(title: localized("tx_detail.error.contact.title"), message: localized("tx_detail.error.remove_contact.description"), type: .error)
        }
    }

    func update(alias: String?) {

        guard let contactModel else {
            do {
                let address = try transaction.address
                self.contactModel = try contactsManager.createInternalModel(name: alias ?? "", isFavorite: false, address: address)
                updateAlias()
                userAliasUpdateSuccessCallback?()
            } catch {
                errorModel = MessageModel(title: localized("tx_detail.error.contact.title"), message: localized("tx_detail.error.save_contact.description"), type: .error)
                resetAlias()
            }
            return
        }

        do {
            try contactsManager.update(alias: alias, isFavorite: contactModel.isFavorite, contact: contactModel)
            updateContactData()
        } catch {
            errorModel = MessageModel(title: localized("tx_detail.error.contact.title"), message: localized("tx_detail.error.save_contact.description"), type: .error)
            resetAlias()
        }
    }

    public func updateContactData() {
        Task {
            contactModel = try await fetchContactModel()
            updateAlias()
        }
    }

    private func updateAlias() {
        if let contactModel {
            userAlias = isContactExist ? contactModel.name : nil
        } else {
            userAlias = nil
        }
    }

    func resetAlias() {
        userAlias = contactModel?.alias
    }

    func getTransactionAddress() throws -> TariAddress {
        try transaction.address
    }

    func toggleAddressFormat() {
        isEmojiFormat.toggle()
    }

    func requestLinkToBlockExplorer() {
        linkToOpen = fetchLinkToOpen()
    }
    
    var rawDetails: String {
        // TODO: Add paymentId
        get throws {
            try """
            {
            "id": "\(identifier ?? "-")",
            "direction": "\(isInbound ? "INBOUND" : "OUTBOUND")",
            "amount": "\(amount ?? "-")",
            "timestamp": "\(timestamp ?? 0)",
            "status": "\(fetchStatusText() ?? "-")",
            "fee": "\(fee ?? "-")",
            "paymentID": "\(transactionMessage ?? "-")"
            "confirmationCount": "\(transactionConfirmationCount ?? 0)",
            "minedHeight": "\(walletBlockHeight)",
            "nounce": "\(transactionNounce ?? "-")",
            "signature": "\(transactionSignature ?? "-")"
            }
            """
        }
    }
    
    var paymentReferenceConfirmationCount: Int64? {
        guard let paymentReference else { return nil }
        return max(0, Int64(walletBlockHeight) - Int64(paymentReference.blockHeight))
    }
    
    var transactionConfirmationCount: UInt64? {
        try? (transaction as? CompletedTransaction)?.confirmationCount
    }

    // MARK: - Helpers

    private func fetchTitle() throws -> String? {
        if transaction.isCancelled {
            return localized("tx_detail.payment_cancelled")
        }

        if try transaction.isCoinbase {
            return "Mining Reward"
        }

        return try transaction.isOutboundTransaction ? localized("tx_detail.payment_sent") : localized("tx_detail.payment_received")
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

        let requiredConfirmationCount = try transactions().requiredConfirmationsCount

        switch try transaction.status {
        case .pending:
            return try transaction.isOutboundTransaction ? .txWaitingForRecipient : .txWaitingForSender
        case .broadcast, .completed:
            return .txCompleted(confirmationCount: 1, requiredConfirmationCount: requiredConfirmationCount)
        case .minedUnconfirmed:
            guard let confirmationCount = try (transaction as? CompletedTransaction)?.confirmationCount else {
                return .txCompleted(confirmationCount: 1, requiredConfirmationCount: requiredConfirmationCount)
            }
            return .txCompleted(confirmationCount: confirmationCount + 1, requiredConfirmationCount: requiredConfirmationCount)
        case .txNullError, .imported, .minedConfirmed, .unknown, .rejected, .oneSidedUnconfirmed, .oneSidedConfirmed, .queued, .coinbase, .coinbaseUnconfirmed, .coinbaseConfirmed, .coinbaseNotInBlockChain:
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
        // Hide fee for coinbase transactions
        guard try !transaction.isCoinbase, try transaction.isOutboundTransaction else { return nil }

        let fee: UInt64
        if let completedFee = try (transaction as? CompletedTransaction)?.fee {
            fee = completedFee
        } else if let pendingFee = try (transaction as? PendingOutboundTransaction)?.fee {
            fee = pendingFee
        } else {
            return nil
        }

        // Return nil if fee is 0
        guard fee > 0 else { return nil }

        return MicroTari(fee).formattedPrecise
    }

    private func fetchAddressComponents() throws -> TariAddressComponents {
        try TariAddressComponents(address: transaction.address)
    }

    private func fetchContactModel() async throws -> ContactsManager.Model? {
        try await contactsManager.fetchModels()
        return try contactsManager.tariContactModels.first { try $0.internalModel?.addressComponents == transaction.address.components }
    }

    private func fetchLinkToOpen() -> URL? {
        guard let transactionNounce, let transactionSignature else { return nil }
        return NetworkManager.shared.selectedNetwork.blockExplorerKernelURL(nounce: transactionNounce, signature: transactionSignature)
    }

    private func fetchStatusText() throws -> String? {
        guard !transaction.isCancelled else {
            return "Payment Cancelled"
        }
        let requiredConfirmationCount = try transactions().requiredConfirmationsCount

        return switch try transaction.status {
        case .pending:
            try transaction.isOutboundTransaction ? "Waiting for recipient" : "Waiting for sender"
        case .broadcast, .completed:
            "Final processing (1/\(requiredConfirmationCount + 1))"
        case .minedUnconfirmed:
            if let confirmationCount = transactionConfirmationCount {
                "Final processing (\(confirmationCount + 1)/\(requiredConfirmationCount + 1))"
            } else {
                "Final processing (1/\(requiredConfirmationCount + 1))"
            }
        case .txNullError:
            "Transaction Error"
        case .imported:
            "Imported"
        case .minedConfirmed:
            "Mined (Confirmed)"
        case .unknown:
            "Unknown"
        case .rejected:
            "Rejected"
        case .oneSidedUnconfirmed:
            "One-Sided (Unconfirmed)"
        case .oneSidedConfirmed:
            "One-Sided (Confirmed)"
        case .queued:
            "Queued"
        case .coinbase:
            "Coinbase"
        case .coinbaseUnconfirmed:
            "Coinbase (Unconfirmed)"
        case .coinbaseConfirmed:
            "Coinbase (Confirmed)"
        case .coinbaseNotInBlockChain:
            "Coinbase (Not in Blockchain)"
        }
    }

    private func handle(transaction: Transaction) {
        self.transaction = transaction
        fetchData()
    }

    private func handleMessage() throws {
        note = transactionMessage
        gifMedia = nil
    }
    
    var transactionMessage: String? {
        guard let message = try? transaction.message else { return nil }
        // If note is "None", show empty string
        return message == "None" ? "" : message.hex()
    }

    private func handleTransactionKernel() {

        defer {
            isBlockExplorerActionAvailable = NetworkManager.shared.selectedNetwork.isBlockExplorerAvailable && transactionNounce != nil && transactionSignature != nil
        }

        guard let kernel = try? (transaction as? CompletedTransaction)?.transactionKernel else {
            transactionNounce = nil
            transactionSignature = nil
            return
        }

        transactionNounce = try? kernel.excessPublicNonceHex
        transactionSignature = try? kernel.excessSignatureHex
    }

    private func handle(isUserAliasExist: Bool) {
        isAddContactButtonVisible = !isUserAliasExist
        isNameSectionVisible = isUserAliasExist
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
