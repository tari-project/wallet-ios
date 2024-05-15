//  ChatManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 27/09/2023
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

final class ChatManager {

    enum GeneralError: Error {
        case unableToCreateChatClient
    }

    // MARK: Properties

    private var client: ChatClient?

    private var existingClient: ChatClient {
        get throws {
            guard let client else { throw GeneralError.unableToCreateChatClient }
            return client
        }
    }

    // MARK: - Actions

    func start(networkName: String, publicAddress: String, datastorePath: String, identityFilePath: String, transportConfig: TransportConfig, logPath: String, logVerbosity: Int32, contactsHandle: OpaquePointer) throws {

        client = nil

        let config = try ChatConfig(
            network: networkName,
            publicAddress: publicAddress,
            datastorePath: datastorePath,
            identityFilePath: identityFilePath,
            torTransportConfig: transportConfig,
            logPath: logPath,
            logVerbosity: logVerbosity
        )

        client = try ChatClient(config: config, contactsHandle: contactsHandle)
    }

    func add(contact: TariAddress) throws {
        try existingClient.addContact(address: contact)
    }

    func fetchModels(address: TariAddress, limit: UInt32, page: UInt32) throws -> ChatMessages {
        let client = try existingClient
        return try client.fetchMessages(address: address, limit: limit, page: page)
    }

    func send(message: String, receiver: TariAddress, metadata: [ChatMessageMetadata.MetadataType: Data]) throws {
        let client = try existingClient
        let chatMessage = try ChatMessage(receiver: receiver, message: message)
        try metadata.forEach { try chatMessage.add(metadataType: $0, data: ByteVector(data: $1)) }
        try client.send(message: chatMessage)
    }

    func onlineStatus(address: TariAddress) throws -> ChatOnlineStatus? {
        let client = try existingClient
        let result = try client.checkOnlineStatus(address: address)
        return ChatOnlineStatus(rawValue: result)
    }

    func conversationalists() throws -> Conversationalists {
        let client = try existingClient
        return try client.conversationalists()
    }
}
