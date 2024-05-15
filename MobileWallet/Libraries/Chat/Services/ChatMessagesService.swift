//  ChatMessagesService.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 06/10/2023
	Using Swift 5.0
	Running on macOS 14.0

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

final class ChatMessagesService: CoreChatService {

    // MARK: - Consts

    private let fetchedMessagesLimit: UInt32 = 100

    // MARK: - Properties

    @Published private(set) var recentMessages: [ChatMessage] = []
    @Published private(set) var error: Error?

    @Published private var messages: [String: [ChatMessage]] = [:]

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init(chatManager: ChatManager) {
        super.init(chatManager: chatManager)
        setupCallbacks()
        fetchData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        ChatCallbackManager.shared.messageReceived
            .sink { [weak self] _ in self?.fetchData() }
            .store(in: &cancellables)

        $messages
            .compactMap {
                try? $0
                    .mapValues(\.first)
                    .values
                    .compactMap { $0 }
                    .sorted { try $0.timestamp > $1.timestamp }
            }
            .sink { [weak self] in self?.recentMessages = $0 }
            .store(in: &cancellables)

    }

    // MARK: - Actions

    func messages(address: TariAddress) throws -> AnyPublisher<[ChatMessage], Never> {

        let emojis = try address.emojis

        return $messages
            .map { $0[emojis] ?? [] }
            .eraseToAnyPublisher()
    }

    func send(message: String, receiver: TariAddress, metadata: [ChatMessageMetadata.MetadataType: Data]) throws {
        try chatManager.send(message: message, receiver: receiver, metadata: metadata)
        fetchData()
    }

    private func fetchData() {
        do {
            let addresses = try chatManager.conversationalists().all
            messages = try addresses.reduce(into: [String: [ChatMessage]]()) { result, address in
                try result[address.emojis] = try fetchAllMessages(address: address)
            }
        } catch {
            self.error = error
        }
    }

    private func fetchAllMessages(address: TariAddress, page: UInt32 = 0) throws -> [ChatMessage] {
        let messages = try chatManager.fetchModels(address: address, limit: fetchedMessagesLimit, page: page).all
        guard !messages.isEmpty else { return messages }
        return try messages + fetchAllMessages(address: address, page: page + 1)
    }
}
