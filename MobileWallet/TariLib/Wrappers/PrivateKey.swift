//  PrivateKey.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/15
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

enum PrivateKeyError: Error {
    case generic(_ errorCode: Int32)
    case invalidHex
}

class PrivateKey {
    private var ptr: OpaquePointer

    var pointer: OpaquePointer {
        return ptr
    }

    var bytes: (ByteVector?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            ByteVector(pointer: private_key_get_bytes(ptr, error))
        })
        guard errorCode == 0 else {
            return (nil, PrivateKeyError.generic(errorCode))
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

    init(byteVector: ByteVector) throws {
        var errorCode: Int32 = -1
        self.ptr = withUnsafeMutablePointer(to: &errorCode, { error in
            private_key_create(byteVector.pointer, error)
        })
        guard errorCode == 0 else {
            throw PrivateKeyError.generic(errorCode)
        }
    }

    init(hex: String) throws {
        let chars = CharacterSet(charactersIn: "0123456789abcdef")
        guard hex.count == 64 && hex.rangeOfCharacter(from: chars) != nil else {
            throw PrivateKeyError.invalidHex
        }

        var errorCode: Int32 = -1
        let result = hex.withCString({ chars in
            withUnsafeMutablePointer(to: &errorCode, { error in
            private_key_from_hex(chars, error)
        })
        })
        guard errorCode == 0 else {
            throw PrivateKeyError.generic(errorCode)
        }
        ptr = result!
    }

    init() {
        ptr = private_key_generate()
    }

    deinit {
        private_key_destroy(ptr)
    }
}
