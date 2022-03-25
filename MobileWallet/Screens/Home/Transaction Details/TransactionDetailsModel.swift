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
import GiphyCoreSDK

final class TransactionDetailsModel {
    
    private enum ModelError: Error {
        case generic
    }
    
    // MARK: - View Model
    
    @Published private(set) var title: String?
    @Published private(set) var subtitle: String?
    @Published private(set) var isFailure: Bool = false
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
    @Published private(set) var errorModel: SimpleErrorModel?
    @Published private(set) var isBlockExplorerActionAvailable: Bool = false
    @Published private(set) var linkToOpen: URL?
    
    var userAliasUpdateSuccessCallback: (() -> Void)?
    
    // MARK: - Properties
    
    private var transaction: TxProtocol
    private var transactionNounce: String?
    private var transactionSignature: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisers
    
    init(transaction: TxProtocol) {
        self.transaction = transaction
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        let eventTypes: [TariEventTypes] = [
            .receievedTxReply,
            .receivedFinalizedTx,
            .txBroadcast,
            .txMinedUnconfirmed,
            .txMined
        ]
        
        eventTypes.forEach {
            TariEventBus.events(forType: $0)
                .compactMap(\.object)
                .compactMap { $0 as? TxProtocol }
                .sink { [weak self] in self?.handle(transaction: $0) }
                .store(in: &cancellables)
        }
    }
    
    private func handle(transaction: TxProtocol) {
        self.transaction = transaction
        fetchData()
    }
    
    // MARK: - Actions
    
    func fetchData() {
        title = fetchTitle()
        transactionState = fetchTransactionState()
        transactionDirection = fetchTransactionDirection()
        emojiIdViewModel = fetchEmojiIdViewModel()
        isContactSectionVisible = !transaction.isOneSidedPayment
        
        do {
            subtitle = try fetchSubtitle()
            amount = try fetchAmount()
            fee = try fetchFee()
            userAlias = try fetchUserAlias()
            try handleMessage()
        } catch {
            errorModel = SimpleErrorModel(title: localized("tx_detail.error.load_tx.title"), message: localized("tx_detail.error.load_tx.description"))
        }
        
        handleTransactionKernel()
        
        isAddContactButtonVisible = userAlias == nil
        isNameSectionVisible = userAlias != nil
    }
    
    func cancelTransactionRequest() {
        
        guard transaction.status.0 == .pending, transaction.direction == .outbound else {
            errorModel = SimpleErrorModel(title: localized("tx_detail.tx_cancellation.error.title"), message: localized("tx_detail.tx_cancellation.error.description"))
            return
        }
        
        do {
            try TariLib.shared.tariWallet?.cancelPendingTx(transaction)
            wasTransactionCanceled = true
        } catch {
            errorModel = SimpleErrorModel(title: localized("tx_detail.tx_cancellation.error.title"), message: "")
        }
    }
    
    func addContactAliasRequest() {
        isAddContactButtonVisible = false
        isNameSectionVisible = true
    }
    
    func update(alias: String?) {
        
        guard let alias = alias, !alias.isEmpty, let hex = emojiIdViewModel?.hex, let wallet = TariLib.shared.tariWallet else { return }
        
        do {
            try wallet.addUpdateContact(alias: alias, publicKeyHex: hex)
            userAliasUpdateSuccessCallback?()
            userAlias = alias
        } catch {
            errorModel = SimpleErrorModel(title: localized("tx_detail.error.contact.title"), message: localized("tx_detail.error.save_contact.description"))
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
    
    private func fetchTitle() -> String? {
        
        if transaction.isCancelled {
            return localized("tx_detail.payment_cancelled")
        }
        
        switch transaction.status.0 {
        case .txNullError, .completed, .broadcast, .minedUnconfirmed, .pending, .unknown:
            return localized("tx_detail.payment_in_progress")
        case .minedConfirmed, .imported, .rejected, .fauxUnconfirmed, .fauxConfirmed:
            break
        }
        
        switch transaction.direction {
        case .inbound:
            return localized("tx_detail.payment_received")
        case .outbound:
            return localized("tx_detail.payment_sent")
        case .none:
            break
        }
        
        return nil
    }
    
    private func fetchSubtitle() throws -> String {
        
        let date = transaction.date.0
        var failureReason: String?
        let formattedDate = date?.formattedDisplay()
        
        if let completedTransaction = transaction as? CompletedTx, let description = try completedTransaction.rejectionReason.description {
            failureReason = description
        }
        
        isFailure = failureReason != nil
        
        return [failureReason, formattedDate]
            .compactMap { $0 }
            .joined(separator: "\n")
    }
    
    private func fetchTransactionState() -> AnimatedRefreshingViewState? {
        
        guard !transaction.isCancelled else {
            return nil
        }
        
        switch transaction.status.0 {
        case .pending:
            switch transaction.direction {
            case .inbound:
                return .txWaitingForSender
            case .outbound:
                return .txWaitingForRecipient
            case .none:
                return nil
            }
        case .broadcast, .completed:
            return .txCompleted(confirmationCount: 1)
        case .minedUnconfirmed:
            guard let confirmationCountTuple = (transaction as? CompletedTx)?.confirmationCount, confirmationCountTuple.1 == nil else {
                return .txCompleted(confirmationCount: 1)
            }
            return .txCompleted(confirmationCount: confirmationCountTuple.0 + 1)
        case .txNullError, .imported, .minedConfirmed, .unknown, .rejected, .fauxUnconfirmed, .fauxConfirmed:
            return nil
        }
    }
    
    private func fetchTransactionDirection() -> String? {
        switch transaction.direction {
        case .inbound:
            return localized("tx_detail.from")
        case .outbound:
            return localized("tx_detail.to")
        case .none:
            return nil
        }
    }
    
    private func fetchAmount() throws -> String {
        
        guard let amount = transaction.microTari.0 else {
            throw transaction.microTari.1 ?? ModelError.generic
        }
        
        return amount.formattedPrecise
    }
    
    private func fetchFee() throws -> String? {
        
        guard transaction.direction == .outbound, let fee = (transaction as? CompletedTx)?.fee ?? (transaction as? PendingOutboundTx)?.fee else {
            return nil
        }
        
        if let error = fee.1 {
            throw error
        }
        
        return fee.0?.formattedWithOperator
    }
    
    private func fetchEmojiIdViewModel() -> EmojiIdView.ViewModel? {
        
        var emojiID: String?
        var hex: String?
        
        switch transaction.direction {
        case .inbound:
            emojiID = transaction.sourcePublicKey.0?.emojis.0
            hex = transaction.sourcePublicKey.0?.hex.0
        case .outbound:
            emojiID = transaction.destinationPublicKey.0?.emojis.0
            hex = transaction.destinationPublicKey.0?.hex.0
        case .none:
            return nil
        }
        
        guard let emojiID = emojiID, let hex = hex else { return nil }
        return EmojiIdView.ViewModel(emojiID: emojiID, hex: hex)
    }
    
    private func fetchUserAlias() throws -> String? {
        guard let contact = transaction.contact.0 else { return nil }
        if let aliasError = contact.alias.1 { throw aliasError }
        return contact.alias.0
    }
    
    private func handleMessage() throws {
        
        guard !transaction.isOneSidedPayment else {
            note = localized("transaction.one_sided_payment.note.normal")
            gifMedia = nil
            return
        }
        
        if let messageError = transaction.message.1 { throw messageError }
        
        let message = transaction.message.0
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
                TariLogger.error("Failed to load gif", error: error)
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
        
        guard let kernel = transaction.transactionKernel.0 else {
            transactionNounce = nil
            transactionSignature = nil
            return
        }
        
        transactionNounce = try? kernel.excessPublicNonce
        transactionSignature = try? kernel.excessSignature
    }
    
    private func fetchLinkToOpen() -> URL? {
        guard let transactionNounce = transactionNounce, let transactionSignature = transactionSignature else { return nil }
        let request = [transactionNounce, transactionSignature].joined(separator: "/")
        return URL(string: TariSettings.shared.blockExplorerKernelUrl + "\(request)")
    }
}

private extension TransactionRejectionReason {
    
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
