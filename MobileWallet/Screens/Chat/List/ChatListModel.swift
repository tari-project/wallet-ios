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
        let isPinned: Bool
        let name: String
        let preview: String
        let timestamp: TimeInterval
        let unreadMessagesCount: Int
    }

    // MARK: - View Model

    @Published private(set) var unreadMessagesCount: Int = 0
    @Published private(set) var previewsSections: [MessageSection] = []
    @Published private(set) var action: Action?
    @Published private(set) var errorMessage: MessageModel?

    // MARK: - Properties

    private let contactsManager = ContactsManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        Publishers.CombineLatest3(Tari.shared.chatMessagesBridgeService.$recentMessages, Tari.shared.chatUsersService.$onlineStatuses, Tari.shared.chatMessagesBridgeService.$unreadMessagesCount)
            .sink { [weak self] in try? self?.handle(recentMessages: $0, onlineStatuses: $1, unreadMessagesCount: $2) }
            .store(in: &cancellables)

        Tari.shared.chatMessagesBridgeService.$totalUnreadMessagesCount
            .assign(to: &$unreadMessagesCount)
    }

    // MARK: - Updates

    private func updateRecentMessages() throws {
        let messages = Tari.shared.chatMessagesBridgeService.recentMessages
        let onlineStatuses = Tari.shared.chatUsersService.onlineStatuses
        let unreadMessagesCount = Tari.shared.chatMessagesBridgeService.unreadMessagesCount
        try handle(recentMessages: messages, onlineStatuses: onlineStatuses, unreadMessagesCount: unreadMessagesCount)
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

    func select(emojiID: String) {
        guard let address = try? TariAddress(emojiID: emojiID) else { return }
        action = .openConversation(address: address)
    }

    // MARK: Handlers

    private func handle(recentMessages: [String: ChatMessageData], onlineStatuses: [String: ChatOnlineStatus], unreadMessagesCount: [String: Int]) throws {

        let pinnedAddresses = ChatUserDefaults.pinnedAddresses ?? []

        let previews: [MessagePreview] = try recentMessages
            .map {

                let hex = $0.key
                let chatMessage = $0.value
                let contact = try contactsManager.contact(address: chatMessage.address)
                let emojis = try chatMessage.address.emojis
                let isOnline = onlineStatuses.first { $0.key == hex }?.value == .online
                let unreadMessagesCount = unreadMessagesCount[hex] ?? 0

                return MessagePreview(
                    id: hex,
                    avatarText: contact?.avatar ?? emojis.firstOrEmpty,
                    avatarImage: contact?.avatarImage,
                    isOnline: isOnline,
                    isPinned: pinnedAddresses.contains(hex),
                    name: contact?.name ?? emojis.obfuscatedText,
                    preview: chatMessage.message,
                    timestamp: chatMessage.timestamp.timeIntervalSince1970,
                    unreadMessagesCount: unreadMessagesCount
                )
            }
            .sorted { $0.timestamp > $1.timestamp }

        let pinnedPreviews: [MessagePreview] = previews.filter(\.isPinned)
        let otherPreviews: [MessagePreview] = previews.filter { !$0.isPinned }

        var sections = [MessageSection]()

        if !pinnedPreviews.isEmpty {
            sections += [
                MessageSection(title: localized("chat.list.table.section.pinned"), previews: pinnedPreviews)
            ]
        }

        if !otherPreviews.isEmpty {
            sections += [
                MessageSection(title: localized("chat.list.table.section.other"), previews: otherPreviews)
            ]
        }

        previewsSections = sections
    }
}
