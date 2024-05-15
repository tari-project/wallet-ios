//  ChatConversationModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 14/09/2023
	Using Swift 5.0
	Running on macOS 13.5

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

final class ChatConversationModel {

    enum Attachment {
        case request(value: String)
        case gif(status: GifDynamicModel.GifDataState)
    }

    enum MessageActionType {
        case request(value: UInt64)
    }

    struct UserData {
        let avatarText: String?
        let avatarImage: UIImage?
        let isOnline: Bool
        let name: String?
    }

    struct MessageSection {
        let relativeDay: String
        let messages: [Message]
    }

    struct Message: Identifiable {
        let id: String
        let isIncomming: Bool
        let isLastInContext: Bool
        let notifications: [ChatNotificationModel]
        let message: String
        let timestamp: String
        let rawTimestamp: Date
        let action: MessageActionType?
        let gifIdentifier: String?
    }

    enum Action {
        case moveToContactDetails(contact: ContactsManager.Model)
        case moveToSendTransction(paymentInfo: PaymentInfo)
        case moveToRequestTokens
        case showReplaceAttachmentDialog
    }

    // MARK: - View Model

    @Published private(set) var userData: UserData?
    @Published private(set) var messages: [MessageSection] = []
    @Published private(set) var attachement: Attachment?
    @Published private(set) var action: Action?
    @Published private(set) var errorModel: MessageModel?

    var isPinned: Bool { (try? ChatUserDefaults.pinnedAddresses?.contains(address.byteVector.hex)) == true }

    // MARK: - Properties

    private let address: TariAddress
    private let dateFormatter = DateFormatter.shortDate
    private let hourFormatter = DateFormatter.hour
    private let contactsManager = ContactsManager()
    private let transactionFormatter = TransactionFormatter()
    private let gifDynamicModel = GifDynamicModel()

    private var isOnline: Bool = false
    private var unconfirmedAttachmentAction: (() -> Void)?
    private var messageMetadata: [ChatMessageMetadata.MetadataType: Data] = [:]
    private var chatMessages: [ChatMessage] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(address: TariAddress) {
        self.address = address

        do {
            try setupCallbacks()
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    // MARK: - Setups

    private func setupCallbacks() throws {

        let hex = try address.byteVector.hex

        Tari.shared.chatUsersService
            .$onlineStatuses
            .compactMap { $0.first { $0.key == hex }?.value }
            .map { $0 == .online }
            .sink { [weak self] in
                self?.isOnline = $0
                self?.updateUserData()
            }
            .store(in: &cancellables)

        let transactionsPublisher = Tari.shared.transactions.$all
            .map {
                $0.filter {
                    guard let transactionHex = try? $0.address.byteVector.hex else { return false }
                    return transactionHex == hex
                }
            }

        try Publishers.CombineLatest3(Tari.shared.chatMessagesService.messages(address: address), transactionsPublisher, $userData)
            .compactMap { [weak self] chatMessages, transactions, userData in
                try? self?.messageSections(chatMessages: chatMessages, transactions: transactions, username: userData?.name ?? localized("chat.conversation.messages.username_placeholder"))
            }
            .sink { [weak self] in self?.messages = $0 }
            .store(in: &cancellables)

        gifDynamicModel.$gif
            .sink { [weak self] in
                guard case .gif = self?.attachement else { return }
                self?.attachement = .gif(status: $0)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func updateUserData() {
        Task {
            do {
                try await contactsManager.fetchModels()
                let contact = try contactsManager.contact(address: address)

                userData = try UserData(
                    avatarText: contact?.avatar ?? address.emojis.firstOrEmpty,
                    avatarImage: contact?.avatarImage,
                    isOnline: isOnline,

                    name: contact?.name ?? address.emojis.obfuscatedText
                )
            } catch {
                errorModel = ErrorMessageManager.errorModel(forError: error)
            }
        }
    }

    func requestContactDetails() {
        do {
            let contact = try contactsManager.contact(address: address) ?? ContactsManager.Model(address: address)
            action = .moveToContactDetails(contact: contact)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func send(message: String) {
        do {
            try Tari.shared.chatMessagesService.send(message: message, receiver: address, metadata: messageMetadata)
            attachement = nil
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func attach(requestedTokenAmount: Double) {
        handle { [weak self] in
            do {
                let value = try MicroTari(decimalValue: requestedTokenAmount)
                self?.attachement = .request(value: value.formattedPrecise)
                self?.messageMetadata[.tokenRequest] = value.rawValue.data()
            } catch {
                self?.errorModel = ErrorMessageManager.errorModel(forError: error)
            }
        }
    }

    func attach(gifID: String) {
        handle { [weak self] in
            self?.attachement = .gif(status: .none)
            self?.gifDynamicModel.fetchGif(identifier: gifID)
            self?.messageMetadata[.gif] = gifID.data(using: .utf8)
        }
    }

    func confirmAttachmentReplacement() {
        unconfirmedAttachmentAction?()
    }

    func cancelAttachmetReplacement() {
        unconfirmedAttachmentAction = nil
    }

    func removeAttachment() {
        attachement = nil
        messageMetadata.removeAll()
    }

    func requestSendTransaction() {
        triggerSendTokensAction(amount: 0)
    }

    func requestTokens() {
        action = .moveToRequestTokens
    }

    func switchPinedStatus() {

        guard let hex = try? address.byteVector.hex else { return }
        var pinnedAddresses = ChatUserDefaults.pinnedAddresses ?? []

        if isPinned {
            pinnedAddresses.remove(hex)
        } else {
            pinnedAddresses.insert(hex)
        }

        ChatUserDefaults.pinnedAddresses = pinnedAddresses
    }

    func handle(messageAction: MessageActionType) {
        switch messageAction {
        case let .request(value):
            triggerSendTokensAction(amount: value)
        }
    }

    private func triggerSendTokensAction(amount: UInt64) {
        do {
            let hex = try address.byteVector.hex
            let amount = MicroTari(amount)
            let paymentInfo = PaymentInfo(address: hex, alias: nil, yatID: nil, amount: amount, feePerGram: nil, note: nil)
            action = .moveToSendTransction(paymentInfo: paymentInfo)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    // MARK: - Handlers

    private func messageSections(chatMessages: [ChatMessage], transactions: [Transaction], username: String) throws -> [MessageSection] {

        let chatMessagesSections = try rawMessagesSections(chatMessages: chatMessages, username: username)
        let transactionsMessagesSections = try rawMessagesSections(transactions: transactions, username: username)

        self.chatMessages = chatMessages

        return chatMessagesSections
            .merging(transactionsMessagesSections, uniquingKeysWith: { $0 + $1 })
            .mapValues {
                var messages = $0
                var lastMessages = messages.removeLast()
                lastMessages = lastMessages.update(isLastInContext: true)
                messages.append(lastMessages)
                return messages
            }
            .sorted { $0.key < $1.key }
            .map {
                let messages = $0.value.sorted { $0.rawTimestamp < $1.rawTimestamp }
                return MessageSection(relativeDay: dateFormatter.string(from: $0.key), messages: messages)
            }
    }

    private func rawMessagesSections(chatMessages: [ChatMessage], username: String) throws -> [Date: [Message]] {
        try chatMessages
            .reduce(into: [Date: [Message]]()) { result, chatMessage in

                let timestamp = try Date(timeIntervalSince1970: TimeInterval(chatMessage.timestamp))
                guard let dateOnly = timestamp.dateOnly else { return }
                let allMetadata = try chatMessage.allMetadata
                let allMetadataDictionary = try chatMessage.allMetadataDictionary
                let isIncomming = try chatMessage.isIncomming
                var messages = result[dateOnly] ?? []

                if let lastMessage = messages.last, lastMessage.isIncomming != isIncomming {
                    let updatedLastMessage = lastMessage.update(isLastInContext: true)
                    messages.removeLast()
                    messages.append(updatedLastMessage)
                }

                let message = try Message(
                    id: chatMessage.identifier.string ?? "",
                    isIncomming: chatMessage.isIncomming,
                    isLastInContext: false,
                    notifications: try ChatMessageMetadataFormatter.format(metadataList: allMetadata, isIncomming: isIncomming, username: username),
                    message: chatMessage.body.string ?? "",
                    timestamp: hourFormatter.string(from: timestamp),
                    rawTimestamp: timestamp,
                    action: makeMessageActionType(message: chatMessage),
                    gifIdentifier: allMetadataDictionary[.gif]?.string
                )

                messages.append(message)
                result[dateOnly] = messages
            }
    }

    private func rawMessagesSections(transactions: [Transaction], username: String) throws -> [Date: [Message]] {

        try transactions
            .reduce(into: [Date: [Message]]()) { result, transaction in

                let timestamp = try Date(timeIntervalSince1970: TimeInterval(transaction.timestamp))
                guard let dateOnly = timestamp.dateOnly else { return }

                var messages = result[dateOnly] ?? []
                let isIncomming = try !transaction.isOutboundTransaction
                let gifIdentifier = try transactionFormatter.model(transaction: transaction)?.giphyID

                let message = try Message(
                    id: UUID().uuidString,
                    isIncomming: isIncomming,
                    isLastInContext: false,
                    notifications: [ChatMessageMetadataFormatter.format(transaction: transaction, isIncomming: isIncomming, username: username)],
                    message: transaction.message,
                    timestamp: hourFormatter.string(from: timestamp),
                    rawTimestamp: timestamp,
                    action: nil,
                    gifIdentifier: gifIdentifier
                )

                messages.append(message)
                result[dateOnly] = messages
            }
    }

    private func handle(attachmentAction: @escaping () -> Void) {
        guard self.attachement == nil else {
            unconfirmedAttachmentAction = attachmentAction
            action = .showReplaceAttachmentDialog
            return
        }
        attachmentAction()
    }

    // MARK: - Message Action

    private func makeMessageActionType(message: ChatMessage) throws -> MessageActionType? {

        guard let metadata = try message.allMetadata.first, let metadataType = try metadata.type else { return nil }

        switch metadataType {
        case .tokenRequest:
            guard let value = try metadata.data.data.value(type: UInt64.self, byteCount: UInt64.bitWidth / 8) else { return nil }
            return try message.isIncomming ? .request(value: value) : nil
        case .reply, .gif:
            return nil
        }
    }
}

extension ChatConversationModel.MessageActionType {

    var title: String {
        switch self {
        case .request:
            return localized("chat.conversation.messages.button.send")
        }
    }
}

private extension ChatConversationModel.Message {

    func update(isLastInContext: Bool) -> Self {
        Self(
            id: id,
            isIncomming: isIncomming,
            isLastInContext: isLastInContext,
            notifications: notifications,
            message: message,
            timestamp: timestamp,
            rawTimestamp: rawTimestamp,
            action: action,
            gifIdentifier: gifIdentifier
        )
    }
}
