//  ChatMessage.swift

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

final class ChatMessage {

    // MARK: - Properties

    let pointer: OpaquePointer

    var metadataCount: UInt32 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = chat_message_metadata_len(pointer, errorCodePointer)
            guard errorCode == 0 else { throw ChatError(code: errorCode) }
            return result
        }
    }

    var body: ByteVector {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_chat_message_body(pointer, errorCodePointer)
            guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
            return ByteVector(pointer: result)
        }
    }

    var address: TariAddress {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_chat_message_address(pointer, errorCodePointer)
            guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
            return TariAddress(pointer: result)
        }
    }

    var direction: UInt8 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_chat_message_direction(pointer, errorCodePointer)
            guard errorCode == 0 else { throw ChatError(code: errorCode) }
            return result
        }
    }

    var timestamp: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_chat_message_stored_at(pointer, errorCodePointer)
            guard errorCode == 0 else { throw ChatError(code: errorCode) }
            return result
        }
    }

    var sendTimestamp: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_chat_message_sent_at(pointer, errorCodePointer)
            guard errorCode == 0 else { throw ChatError(code: errorCode) }
            return result
        }
    }

    var deliveryConfirmationTimestamp: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_chat_message_delivery_confirmation_at(pointer, errorCodePointer)
            guard errorCode == 0 else { throw ChatError(code: errorCode) }
            return result
        }
    }

    var readConfirmationTimestamp: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_chat_message_read_confirmation_at(pointer, errorCodePointer)
            guard errorCode == 0 else { throw ChatError(code: errorCode) }
            return result
        }
    }

    var identifier: ByteVector {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_chat_message_id(pointer, errorCodePointer)
            guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
            return ByteVector(pointer: result)
        }
    }

    // MARK: - Initialisers

    init(address: TariAddress, message: String) throws {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = create_chat_message(address.pointer, message, errorCodePointer)
        guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
        pointer = result
    }

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    // MARK: - Actions

    func addMetadata(key: ByteVector, data: ByteVector) throws {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        add_chat_message_metadata(pointer, key.pointer, data.pointer, errorCodePointer)
        guard errorCode == 0 else { throw ChatError(code: errorCode) }
    }

    func metadata(at index: UInt32) throws -> ChatMessageMetadata {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = chat_metadata_get_at(pointer, index, errorCodePointer)
        guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
        return ChatMessageMetadata(pointer: result)
    }

    // MARK: - Deinitialiser

    deinit {
        destroy_chat_message(pointer)
    }
}

extension ChatMessage {

    var isIncomming: Bool {
        get throws { try direction == 0 }
    }

    var allMetadata: [ChatMessageMetadata] {
        get throws {
            let count = try metadataCount
            return try (0..<count).map { try metadata(at: $0) }
        }
    }

    var allMetadataDictionary: [ChatMessageMetadata.MetadataType: ByteVector] {
        get throws {
            try allMetadata.reduce(into: [ChatMessageMetadata.MetadataType: ByteVector]()) { result, metadata in
                guard let type = try metadata.type else { return }
                result[type] = try metadata.data
            }
        }
    }

    func add(metadataType: ChatMessageMetadata.MetadataType, data: ByteVector) throws {
        try addMetadata(key: ByteVector(string: metadataType.rawValue), data: data)
    }
}
