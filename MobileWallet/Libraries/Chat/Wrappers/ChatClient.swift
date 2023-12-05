//  ChatClient.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 26/09/2023
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

final class ChatClient {

    // MARK: - Properties

    private let pointer: OpaquePointer

    // MARK: - Initialisers

    init(config: ChatConfig) throws {

        let contactStatusChangeCallback: @convention(c) (OpaquePointer?) -> Void = { _ in
            ChatCallbackManager.shared.post(name: .contactStatusChange, object: nil)
        }

        let messageReceivedCallback: @convention(c) (OpaquePointer?) -> Void = { pointer in
            guard let pointer else { return }
            let message = ChatMessage(pointer: pointer)
            ChatCallbackManager.shared.post(name: .messageReceived, object: message)
        }

        let deliveryConfirmationReceivedCallback: @convention(c) (OpaquePointer?) -> Void = { _ in

        }

        let readConfirmationReceived: @convention(c) (OpaquePointer?) -> Void = { _ in

        }

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = create_chat_client(config.pointer, errorCodePointer, contactStatusChangeCallback, messageReceivedCallback, deliveryConfirmationReceivedCallback, readConfirmationReceived)

        guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
        pointer = result
    }

    // MARK: - Actions

    func addContact(address: TariAddress) throws {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        add_chat_contact(pointer, address.pointer, errorCodePointer)
        guard errorCode == 0 else { throw ChatError(code: errorCode) }
    }

    func checkOnlineStatus(address: TariAddress) throws -> Int32 {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = check_online_status(pointer, address.pointer, errorCodePointer)
        guard errorCode == 0 else { throw ChatError(code: errorCode) }
        return result
    }

    func send(message: ChatMessage) throws {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        send_chat_message(pointer, message.pointer, errorCodePointer)
        guard errorCode == 0 else { throw ChatError(code: errorCode) }
    }

    func fetchMessages(address: TariAddress, limit: Int32, page: Int32) throws -> ChatMessages {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = get_chat_messages(pointer, address.pointer, limit, page, errorCodePointer)
        guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
        return ChatMessages(pointer: result)
    }

    func conversationalists() throws -> Conversationalists {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = get_conversationalists(pointer, errorCodePointer)
        guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
        return Conversationalists(pointer: result)
    }

    // MARK: - Deinitialiser

    deinit {
        destroy_chat_client(pointer)
    }
}