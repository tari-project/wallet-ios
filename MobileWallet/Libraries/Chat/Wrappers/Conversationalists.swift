//  Conversationalists.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 14/11/2023
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

final class Conversationalists {

    // MARK: - Properties

    private let pointer: OpaquePointer

    var count: UInt32 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = conversationalists_vector_len(pointer, errorCodePointer)
            guard errorCode == 0 else { throw ChatError(code: errorCode) }
            return result
        }
    }

    // MARK: - Initialisers

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    // MARK: - Actions

    func address(index: UInt32) throws -> TariAddress {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = conversationalists_vector_get_at(pointer, index, errorCodePointer)
        guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
        return TariAddress(pointer: result)
    }

    // MARK: - Deinitialiser

    deinit {
        destroy_conversationalists_vector(pointer)
    }
}

extension Conversationalists {

    var all: [TariAddress] {
        get throws {
            try (0..<count).map { try address(index: $0) }
        }
    }
}
