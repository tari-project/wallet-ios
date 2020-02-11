//  PublicKey.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/16
	Using Swift 5.0
	Running on macOS 10.15

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

import Foundation

enum PublicKeyError: Error {
    case generic(_ errorCode: Int32)
    case invalidHex
}

class PublicKey {
    private var ptr: OpaquePointer
    private var cachedEmojiId: String?

    var pointer: OpaquePointer {
        return ptr
    }

    var bytes: (ByteVector?, Error?) {
       var errorCode: Int32 = -1
       let result = ByteVector(pointer: public_key_get_bytes(ptr, UnsafeMutablePointer<Int32>(&errorCode)))
       guard errorCode == 0 else {
           return (nil, PublicKeyError.generic(errorCode))
       }

       return (result, nil)
    }

    var hex: (String, Error?) {
        let (bytes, bytesError) = self.bytes
        if bytesError != nil {
            return ("", bytesError)
        }

        return bytes!.hexString
    }

    var emojis: (String, Error?) {
        var errorCode: Int32 = -1
        let emojiPtr = public_key_to_emoji(ptr, UnsafeMutablePointer<Int32>(&errorCode))
        let result = String(cString: emojiPtr!)

        let mutable = UnsafeMutablePointer<Int8>(mutating: emojiPtr!)
        string_destroy(mutable)

        return (result, errorCode != 0 ? PublicKeyError.generic(errorCode) : nil)
    }

    //TODO setup attributed string version with dots in the middle for shortened version in Common dir.
    //https://stackoverflow.com/questions/19318421/how-to-embed-small-icon-in-uilabel

    init(privateKey: PrivateKey) throws {
        var errorCode: Int32 = -1
        ptr = public_key_from_private_key(privateKey.pointer, UnsafeMutablePointer<Int32>(&errorCode))
        guard errorCode == 0 else {
            throw PublicKeyError.generic(errorCode)
        }
    }

    init(hex: String) throws {
        let chars = CharacterSet(charactersIn: "0123456789abcdef")
        guard (hex.count == 64 && hex.rangeOfCharacter(from: chars) != nil) else {
            throw PublicKeyError.invalidHex
        }
        let hexPtr = UnsafeMutablePointer<Int8>(mutating: hex)
        var errorCode: Int32 = -1
        let result = public_key_from_hex(hexPtr, UnsafeMutablePointer<Int32>(&errorCode))
        guard errorCode == 0 else {
            throw PublicKeyError.generic(errorCode)
        }
        ptr = result!
    }

    init(emojis: String) throws {
        let emojiPtr = UnsafeMutablePointer<Int8>(mutating: emojis)
        var errorCode: Int32 = -1
        let result = public_key_from_emoji(emojiPtr, UnsafeMutablePointer<Int32>(&errorCode))
        guard errorCode == 0 else {
            throw PublicKeyError.generic(errorCode)
        }
        ptr = result!
    }

    init(pointer: OpaquePointer) {
        ptr = pointer
    }

    deinit {
        public_key_destroy(ptr)
    }
}
