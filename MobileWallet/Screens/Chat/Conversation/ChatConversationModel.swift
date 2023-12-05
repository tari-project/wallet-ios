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
        let notificationParts: [StylizedLabel.StylizedText]
        let message: String
        let timestamp: String
    }

    enum Action {
        case openContactDetails(contact: ContactsManager.Model)
    }

    // MARK: - View Model

    @Published private(set) var userData: UserData?
    @Published private(set) var messages: [MessageSection] = []
    @Published private(set) var action: Action?
    @Published private(set) var errorModel: MessageModel?

    // MARK: - Properties

    private let address: TariAddress
    private let dateFormatter = DateFormatter.shortDate
    private let hourFormatter = DateFormatter.hour
    private let contactsManager = ContactsManager()
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
        try Tari.shared.chatMessagesService.messages(address: address)
            .compactMap { [weak self] in try? self?.messagesSections(chatMessages: $0) }
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
                    isOnline: false, // TODO: Currently unused

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
            action = .openContactDetails(contact: contact)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func send(message: String) {
        do {
            try Tari.shared.chatMessagesService.send(message: message, receiver: address)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    // MARK: - Handlers

    private func messagesSections(chatMessages: [ChatMessage]) throws -> [MessageSection] {

        return try chatMessages
            .reversed()
            .reduce(into: [Date: [Message]]()) { result, chatMessage in

                let timestamp = try Date(timeIntervalSince1970: TimeInterval(chatMessage.timestamp))
                guard let dateOnly = timestamp.dateOnly else { return }
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
                    notificationParts: [], // TODO: Currently unused
                    message: chatMessage.body.string ?? "",
                    timestamp: hourFormatter.string(from: timestamp)
                )

                messages.append(message)
                result[dateOnly] = messages
            }
            .mapValues {
                var messages = $0
                var lastMessages = messages.removeLast()
                lastMessages = lastMessages.update(isLastInContext: true)
                messages.append(lastMessages)
                return messages
            }
            .sorted { $0.key < $1.key }
            .map { MessageSection(relativeDay: dateFormatter.string(from: $0.key), messages: $0.value) }
    }
}

private extension ChatConversationModel.Message {

    func update(isLastInContext: Bool) -> Self {
        Self(id: id, isIncomming: isIncomming, isLastInContext: isLastInContext, notificationParts: notificationParts, message: message, timestamp: timestamp)
    }
}
