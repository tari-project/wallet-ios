//  Balance.swift

/*
	Package MobileWallet
	Created by David Main on 11/3/21
	Using Swift 5.0
	Running on macOS 11.6

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

final class Balance {

    // MARK: - Properties

    let pointer: OpaquePointer

    var available: UInt64 {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = balance_get_available(pointer, errorCodePointer)
        guard errorCode == 0 else { return 0 }
        return result
    }

    var incoming: UInt64 {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = balance_get_pending_incoming(pointer, errorCodePointer)
        guard errorCode == 0 else { return 0 }
        return result
    }

    var outgoing: UInt64 {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = balance_get_pending_outgoing(pointer, errorCodePointer)
        guard errorCode == 0 else { return 0 }
        return result
    }

    var timelocked: UInt64 {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = balance_get_time_locked(pointer, errorCodePointer)
        guard errorCode == 0 else { return 0 }
        return result
    }

    // MARK: - Initialisers

    init (pointer: OpaquePointer) {
        self.pointer = pointer
    }

    // MARK: - Deinitialiser

    deinit {
        balance_destroy(pointer)
    }
}
