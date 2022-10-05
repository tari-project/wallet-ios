//  TransactionSendResult.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 03/10/2022
	Using Swift 5.0
	Running on macOS 12.4

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

final class TransactionSendResult {
    
    enum Status: UInt32 {
        case queued
        case directSendSafSend
        case directSend
        case safSend
        case invalid
    }
    
    enum InternalError: Error {
        case invalidStatus
    }
    
    // MARK: - Properties
    
    let identifier: UInt64
    let rawStatus: UInt32
    let status: Status
    private let pointer: OpaquePointer
    
    // MARK: - Initialisers
    
    init(identifier: UInt64, pointer: OpaquePointer) throws {
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = transaction_send_status_decode(pointer, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        guard let status = Status(rawValue: result) else { throw InternalError.invalidStatus }
        
        self.identifier = identifier
        self.rawStatus = result
        self.status = status
        self.pointer = pointer
    }
    
    // MARK: - Deinitialiser
    
    deinit {
        transaction_send_status_destroy(pointer)
    }
}

extension TransactionSendResult.Status {
    
    var isSuccess: Bool { isDirectSend || isSafSend || !isQueued }
    
    private var isDirectSend: Bool {
        switch self {
        case .directSend, .directSendSafSend:
            return true
        case .queued, .safSend, .invalid:
            return false
        }
    }
    
    private var isSafSend: Bool {
        switch self {
        case .directSendSafSend, .safSend:
            return true
        case .queued, .directSend, .invalid:
            return false
        }
    }
    
    private var isQueued: Bool {
        switch self {
        case .queued:
            return true
        case .directSendSafSend, .directSend, .safSend, .invalid:
            return false
        }
    }
}
