//  TariAddress.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 17/11/2022
	Using Swift 5.0
	Running on macOS 12.6

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

final class TariAddress {

//    enum InternalError: Error {
//        case invalidHex
//    }

    // MARK: - Properties

    let pointer: OpaquePointer

    var byteVector: ByteVector {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = tari_address_get_bytes(pointer, errorCodePointer)
            guard errorCode == 0, let result else { throw WalletError(code: errorCode) }
            return ByteVector(pointer: result)
        }
    }

    var emojis: String {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = tari_address_to_emoji_id(pointer, errorCodePointer)
            guard errorCode == 0, let result else { throw WalletError(code: errorCode) }
            return String(cString: result)
        }
    }

    // MARK: - Initialisers

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    init(base58: String) throws {

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let pointer = tari_address_from_base58(base58, errorCodePointer)

        guard errorCode == 0, let pointer else { throw WalletError(code: errorCode) }
        self.pointer = pointer
    }

    init(emojiID: String) throws {

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let result = emoji_id_to_tari_address(emojiID, errorCodePointer)

        guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
        self.pointer = pointer
    }

    // MARK: - Deinitialiser

    deinit {
        tari_address_destroy(pointer)
    }
}

extension TariAddress: Equatable {

    static func == (lhs: TariAddress, rhs: TariAddress) -> Bool {
        guard let leftHex = try? lhs.byteVector.hex, let rightHex = try? rhs.byteVector.hex else { return false }
        return leftHex == rightHex
    }

    var publicKey: String {
        get throws { try String(byteVector.hex.dropLast(2)) }
    }

    var isUnknownUser: Bool {
        get throws { try publicKey.filter { $0 == "0" }.count == 64 }
    }
}
