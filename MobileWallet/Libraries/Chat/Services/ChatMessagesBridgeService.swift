//  ChatMagicManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 29/05/2024
	Using Swift 5.0
	Running on macOS 14.4

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

enum ChatMessageIdentifier: Hashable {
    case chatMessage(id: String)
    case transaction(id: UInt64)
}

struct ChatMessageData {
    let identifier: ChatMessageIdentifier
    let timestamp: Date
    let address: TariAddress
    let message: String
    let metadata: [ChatMessageMetadata.MetadataType: ByteVector]
    let isIncomming: Bool
    let isLastInContext: Bool
    let transactionAmount: MicroTari?
}

final class ChatMessagesBridgeService {

    // MARK: - Properties

    @Published private(set) var recentMessages: [String: ChatMessageData] = [:]
    @Published private(set) var unreadMessagesCount: [String: Int] = [:]
    @Published private(set) var totalUnreadMessagesCount: Int = 0

    @Published private var allMessages: [String: [Date: [ChatMessageData]]] = [:]
    @Published private var readTimestamps: [String: Date] = ChatUserDefaults.readTimestamps ?? [:]

    unowned private var transactionsService: TariTransactionsService
    unowned private var chatMessagesService: ChatMessagesService

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(transactionsService: TariTransactionsService, chatMessagesService: ChatMessagesService) {
        self.transactionsService = transactionsService
        self.chatMessagesService = chatMessagesService
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        let messagesPublisher = Tari.shared.chatMessagesService.$messages

        let transactionsPublisher = Tari.shared.transactions.$all
            .map {
                $0.reduce(into: [String: [Transaction]]()) { result, transaction in
                    guard let emojis = try? transaction.address.emojis else { return }
                    var transactions = result[emojis] ?? []
                    transactions.append(transaction)
                    result[emojis] = transactions
                }
            }

        Publishers.CombineLatest(messagesPublisher, transactionsPublisher)
            .compactMap { [weak self] in try? self?.map(messages: $0, transactions: $1) }
            .sink { [weak self] in self?.allMessages = $0 }
            .store(in: &cancellables)

        $allMessages
            .map { $0.compactMapValues { $0.sorted { $0.key < $1.key }.last?.value.sorted { $0.timestamp < $1.timestamp }.last }}
            .sink { [weak self] in self?.recentMessages = $0 }
            .store(in: &cancellables)

        Publishers.CombineLatest($allMessages, $readTimestamps)
            .map { messages, timestamps in
                messages.reduce(into: [String: Int]()) { result, element in
                    let readTimestamp = timestamps[element.key] ?? Date(timeIntervalSince1970: 0)
                    result[element.key] = element.value
                        .filter { $0.key >= readTimestamp }
                        .values
                        .flatMap { $0 }
                        .filter { $0.timestamp >= readTimestamp }
                        .count
                }
            }
            .sink { [weak self] in self?.unreadMessagesCount = $0 }
            .store(in: &cancellables)

        $unreadMessagesCount
            .map { $0.values.reduce(0, +) }
            .sink { [weak self] in self?.totalUnreadMessagesCount = $0 }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func messages(address: TariAddress) throws -> AnyPublisher<[Date: [ChatMessageData]], Never> {

        let emojis = try address.emojis

        return $allMessages
            .map { $0[emojis] ?? [:] }
            .eraseToAnyPublisher()
    }

    func updateReadTimestamp(emojiID: String, timestamp: Date) {

        var readTimestamps = ChatUserDefaults.readTimestamps ?? [:]
        let storedTimestamp = readTimestamps[emojiID] ?? Date(timeIntervalSince1970: 0)

        guard storedTimestamp < timestamp else { return }
        readTimestamps[emojiID] = timestamp
        ChatUserDefaults.readTimestamps = readTimestamps
        self.readTimestamps = readTimestamps
    }

    // MARK: - Handlers

    private func map(messages: [String: [ChatMessage]], transactions: [String: [Transaction]]) throws -> [String: [Date: [ChatMessageData]]] {

        let messageDataSections = try messages
            .mapValues {

                try $0.reduce(into: [Date: [ChatMessageData]]()) { result, chatMessage in

                    let timestamp = try Date(timeIntervalSince1970: TimeInterval(chatMessage.timestamp))
                    guard let day = timestamp.dateOnly, let messageID = try chatMessage.identifier.string else { return }

                    let messageData = try ChatMessageData(
                        identifier: .chatMessage(id: messageID),
                        timestamp: timestamp,
                        address: chatMessage.address,
                        message: chatMessage.body.string ?? "",
                        metadata: chatMessage.allMetadataDictionary,
                        isIncomming: chatMessage.isIncomming,
                        isLastInContext: false,
                        transactionAmount: nil
                    )

                    var allMessages = result[day] ?? []
                    allMessages.append(messageData)
                    result[day] = allMessages
                }
            }

        let transactionsDataSections = try transactions
            .mapValues {
                try $0.reduce(into: [Date: [ChatMessageData]]()) { result, transaction in

                    let timestamp = try Date(timeIntervalSince1970: TimeInterval(transaction.timestamp))
                    guard let day = timestamp.dateOnly else { return }

                    let transactionMessageData = try transaction.message.splitTransactionMessage()
                    var metadata: [ChatMessageMetadata.MetadataType: ByteVector] = [:]

                    if let gifID = transactionMessageData.gifID {
                        metadata = [.gif: try ByteVector(string: gifID)]
                    }

                    let messageData = try ChatMessageData(
                        identifier: .transaction(id: transaction.identifier),
                        timestamp: timestamp,
                        address: transaction.address,
                        message: transactionMessageData.message ?? "",
                        metadata: metadata,
                        isIncomming: !transaction.isOutboundTransaction,
                        isLastInContext: false,
                        transactionAmount: MicroTari(transaction.amount)
                    )

                    var allMessages = result[day] ?? []
                    allMessages.append(messageData)
                    result[day] = allMessages
                }
            }

        return messageDataSections
            .merging(transactionsDataSections) { $0.merging($1) { $0 + $1 }}
            .mapValues { $0.mapValues {

                var isIncomming: Bool?

                return $0
                    .sorted { $0.timestamp < $1.timestamp }
                    .reversed()
                    .map {
                        let previousValue = isIncomming
                        isIncomming = $0.isIncomming
                        guard isIncomming != previousValue else { return $0 }
                        return $0.update(isLastInContext: true)
                    }
                    .reversed()
            }}
    }
}

private extension ChatMessageData {

    func update(isLastInContext: Bool) -> Self {
        Self(
            identifier: identifier,
            timestamp: timestamp,
            address: address,
            message: message,
            metadata: metadata,
            isIncomming: isIncomming,
            isLastInContext: isLastInContext,
            transactionAmount: transactionAmount
        )
    }
}
