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
        case gif(identifier: String)
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
        let id: ChatMessageIdentifier
        let isIncomming: Bool
        let isLastInContext: Bool
        let notifications: [ChatNotificationModel]
        let message: String
        let timestamp: String
        let rawTimestamp: Date
        let action: MessageActionType?
        let gifIdentifier: String?
        let replyModel: ChatReplyViewModel?
    }

    enum Action {
        case moveToContactDetails(contact: ContactsManager.Model)
        case moveToSendTransction(paymentInfo: PaymentInfo)
        case moveToRequestTokens
    }

    // MARK: - View Model

    @Published private(set) var userData: UserData?
    @Published private(set) var messages: [MessageSection] = []
    @Published private(set) var attachement: Attachment?
    @Published private(set) var replyViewModel: ChatReplyViewModel?
    @Published private(set) var action: Action?
    @Published private(set) var errorModel: MessageModel?

    var isPinned: Bool { (try? ChatUserDefaults.pinnedAddresses?.contains(address.byteVector.hex)) == true }

    // MARK: - Properties

    private let address: TariAddress
    private let dateFormatter = DateFormatter.shortDate
    private let hourFormatter = DateFormatter.hour
    private let contactsManager = ContactsManager()

    private var isOnline: Bool = false
    private var messageMetadata: [ChatMessageMetadata.MetadataType: Data] = [:]
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
        Publishers.CombineLatest(try Tari.shared.chatMessagesBridgeService.messages(address: address), $userData)
            .compactMap { [weak self] in try? self?.messageSections(messages: $0, username: $1?.name ?? localized("chat.conversation.messages.username_placeholder")) }
            .sink { [weak self] in self?.messages = $0 }
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
        do {
            let value = try MicroTari(decimalValue: requestedTokenAmount)
            attachement = .request(value: value.formattedPrecise)
            messageMetadata[.tokenRequest] = value.rawValue.data()
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func attach(gifID: String) {
        attachement = .gif(identifier: gifID)
        messageMetadata[.gif] = gifID.data(using: .utf8)
    }

    func attach(replyID: ChatMessageIdentifier) {
        do {
            switch replyID {
            case let .chatMessage(identifier):
                replyViewModel = try makeReplyModel(messageID: identifier)
                messageMetadata[.replyMessage] = identifier.data(using: .utf8)
                messageMetadata[.replyTransaction] = nil
            case let .transaction(identifier):
                replyViewModel = try makeReplyModel(transactionID: identifier)
                messageMetadata[.replyMessage] = nil
                messageMetadata[.replyTransaction] = identifier.data()
            }
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func removeAttachment() {
        attachement = nil
        messageMetadata[.tokenRequest] = nil
        messageMetadata[.gif] = nil
    }

    func removeReplyMessage() {
        replyViewModel = nil
        messageMetadata[.replyMessage] = nil
        messageMetadata[.replyTransaction] = nil
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

    func update(readTimestamp: Date) {
        guard let emojiID = try? address.emojis else { return }
        Tari.shared.chatMessagesBridgeService.updateReadTimestamp(emojiID: emojiID, timestamp: readTimestamp)
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

    private func messageSections(messages: [Date: [ChatMessageData]], username: String) throws -> [MessageSection] {
        try messages
            .sorted { $0.key < $1.key }
            .map {

                let messages = try $0.value.map {

                    var replyModel: ChatReplyViewModel?

                    if let replyMessageID = try $0.metadata[.replyMessage]?.string {
                        replyModel = try makeReplyModel(messageID: replyMessageID)
                    } else if let replyTransactionID = try $0.metadata[.replyTransaction]?.data.value(type: UInt64.self, byteCount: UInt64.bitWidth / 8) {
                        replyModel = try makeReplyModel(transactionID: replyTransactionID)
                    }

                    return Message(
                        id: $0.identifier,
                        isIncomming: $0.isIncomming,
                        isLastInContext: $0.isLastInContext,
                        notifications: try ChatMessageMetadataFormatter.format(metadata: $0.metadata, transactionAmount: $0.transactionAmount, isIncomming: $0.isIncomming, username: username),
                        message: $0.message,
                        timestamp: hourFormatter.string(from: $0.timestamp),
                        rawTimestamp: $0.timestamp,
                        action: try makeMessageActionType(metadata: $0.metadata, isIncommingMessage: $0.isIncomming),
                        gifIdentifier: try $0.metadata[.gif]?.string,
                        replyModel: replyModel
                    )
                }

                return MessageSection(relativeDay: dateFormatter.string(from: $0.key), messages: messages)
            }
    }

    private func makeReplyModel(messageID: String) throws -> ChatReplyViewModel? {
        guard let message = try Tari.shared.chatMessagesService.message(address: address, messageID: messageID) else { return nil }
        let name = try message.isIncomming ? userData?.name : localized("common.you")
        let gifID = try message.allMetadata.first { try $0.type == .gif }?.data.string
        let icon: UIImage? = gifID != nil ? .Icons.Chat.Attachments.gif : nil
        let replyMessage = try message.body.string
        return ChatReplyViewModel(name: name, icon: icon, message: replyMessage, gifID: gifID)
    }

    private func makeReplyModel(transactionID: UInt64) throws -> ChatReplyViewModel? {
        guard let transaction = try Tari.shared.transactions.all.first(where: { try $0.identifier == transactionID }) else { return nil }
        let name = try transaction.isOutboundTransaction ?  localized("common.you") : userData?.name
        let messageData = try transaction.message.splitTransactionMessage()
        let icon: UIImage? = messageData.gifID != nil ? .Icons.Chat.Attachments.gif : nil
        return ChatReplyViewModel(name: name, icon: icon, message: messageData.message, gifID: messageData.gifID)
    }

    // MARK: - Message Action

    private func makeMessageActionType(metadata: [ChatMessageMetadata.MetadataType: ByteVector], isIncommingMessage: Bool) throws -> MessageActionType? {
        guard let requestMetadata = metadata[.tokenRequest], let value = try requestMetadata.data.value(type: UInt64.self, byteCount: UInt64.bitWidth / 8) else { return nil }
        return isIncommingMessage ? .request(value: value) : nil
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
