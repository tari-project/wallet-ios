//  ContactsLivenessData.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 19/12/2023
	Using Swift 5.0
	Running on macOS 14.2

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

final class ContactsLivenessData {

    // MARK: - Properties

    var address: TariAddress {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_liveness_data_address(pointer, errorCodePointer)
            guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
            return TariAddress(pointer: result)
        }
    }

    var onlineStatus: ChatOnlineStatus {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_liveness_data_online_status(pointer, errorCodePointer)
            guard errorCode == 0, let status = ChatOnlineStatus(rawValue: result) else { throw ChatError(code: errorCode) }
            return status
        }
    }

    var lastSeen: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = read_liveness_data_last_seen(pointer, errorCodePointer)
            guard errorCode == 0 else { throw ChatError(code: errorCode) }
            return result
        }
    }

    private let pointer: OpaquePointer

    // MARK: - Initialisers

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    // MARK: - Deinitialiser

    deinit {
        destroy_contacts_liveness_data(pointer)
    }
}
