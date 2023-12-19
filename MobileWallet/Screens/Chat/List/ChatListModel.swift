//  ChatListModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 11/09/2023
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

final class ChatListModel {

    enum Action {
        case openConversation(address: TariAddress)
    }

    struct MessageSection {
        let title: String
        let previews: [MessagePreview]
    }

    struct MessagePreview: Identifiable {
        let id: String
        let avatarText: String
        let avatarImage: UIImage?
        let isOnline: Bool
        let name: String
        let preview: String
        let timestamp: TimeInterval
        let unreadMessagesCount: Int
    }

    // MARK: - View Model

    @Published private(set) var unreadMessagesCount: Int = 0 // TODO: Currently unused
    @Published private(set) var previewsSections: [MessageSection] = []
    @Published private(set) var action: Action?
    @Published private(set) var errorMessage: MessageModel?

    // MARK: - Properties

    private let contactsManager = ContactsManager()
    private var addressCache: [String: TariAddress] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {
        Publishers.CombineLatest(Tari.shared.chatMessagesService.$recentMessages, Tari.shared.chatUsersService.$onlineStatuses)
            .sink { [weak self] in try? self?.handle(messages: $0, onlineStatuses: $1) }
            .store(in: &cancellables)
    }

    // MARK: - Updates

    private func updateRecentMessages() throws {
        let messages = Tari.shared.chatMessagesService.recentMessages
        let onlineStatuses = Tari.shared.chatUsersService.onlineStatuses
        try handle(messages: messages, onlineStatuses: onlineStatuses)
    }

    // MARK: - Actions

    func updateData() {
        Task {
            do {
                try await contactsManager.fetchModels()
                try updateRecentMessages()
            } catch {
                errorMessage = ErrorMessageManager.errorModel(forError: error)
            }
        }
    }

    func select(identifier: String) {
        guard let address = addressCache[identifier] else { return }
        action = .openConversation(address: address)
    }

    // MARK: Handlers

    private func handle(messages: [ChatMessage], onlineStatuses: [String: ChatOnlineStatus]) throws {

        let previews: [MessagePreview] = try messages.compactMap {
            guard let identifier = try $0.identifier.string else { return nil }

            let address = try $0.address
            let emojis = try address.emojis
            let hex = try address.byteVector.hex
            let timestamp = try TimeInterval($0.timestamp)
            let contact = try contactsManager.contact(address: address)
            let isOnline = onlineStatuses.first { $0.key == hex }?.value == .online

            return try MessagePreview(
                id: identifier,
                avatarText: contact?.avatar ?? emojis.firstOrEmpty,
                avatarImage: contact?.avatarImage,
                isOnline: isOnline,
                name: contact?.name ?? emojis.obfuscatedText,
                preview: $0.body.string ?? "",
                timestamp: timestamp,
                unreadMessagesCount: 0 // TODO: Currently unused
            )
        }
        .sorted { $0.timestamp > $1.timestamp }

        var sections = [MessageSection]()

        if !previews.isEmpty {
            sections = [
                MessageSection(title: localized("chat.list.table.section.other"), previews: previews)
            ]
        }

        previewsSections = sections

        addressCache = try zip(previews, messages)
            .reduce(into: [String: TariAddress]()) { result, values in
                result[values.0.id] = try values.1.address
            }
    }
}
