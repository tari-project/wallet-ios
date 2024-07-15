//  ByteVector.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/14
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

final class ByteVector {

    // MARK: - Properties

    let pointer: OpaquePointer

    var count: UInt32 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = byte_vector_get_length(pointer, errorCodePointer)
            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    // MARK: - Constructors

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    convenience init(data: Data) throws {

        let byteArray = [UInt8](data)
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let result = byte_vector_create(byteArray, UInt32(byteArray.count), errorCodePointer)

        guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }

        self.init(pointer: pointer)
    }

    // MARK: - Actions

    func byte(index: UInt32) throws -> UInt8 {

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let result = byte_vector_get_at(pointer, index, errorCodePointer)
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }

    deinit {
        byte_vector_destroy(pointer)
    }
}

extension ByteVector {

    @available(*, deprecated, message: "Obsolette, use TariAddress.base58 instead")
    var hex: String {
        get throws {
            try bytes
                .map { String(format: "%02hhx", $0) }
                .joined()
        }
    }

    var bytes: [UInt8] {
        get throws {
            let count = try count
            return try (0..<count).map { try byte(index: $0) }
        }
    }

    var data: Data {
        get throws { Data(try bytes) }
    }
}
