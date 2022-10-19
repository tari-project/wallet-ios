//  TariVectorWrapper.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 04/07/2022
	Using Swift 5.0
	Running on macOS 12.3

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

final class TariVectorWrapper {
    
    // MARK: - Properties
    
    let pointer: UnsafeMutablePointer<TariVector>
    
    // MARK: - Initialisers
    
    init(type: TariTypeTag) {
        pointer = create_tari_vector(type)
    }
    
    // MARK: - Actions
    
    func add(commitment: String) throws {
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        
        tari_vector_push_string(pointer, commitment, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
    }
    
    // MARK: - Deinitialiser
    
    deinit {
        destroy_tari_vector(pointer)
    }
}

extension TariVectorWrapper {
    
    func add(commitments: [String]) throws {
        try commitments.forEach { try self.add(commitment: $0) }
    }
}

extension UnsafeMutablePointer where Pointee == TariVector {
    
    func array<T>() -> [T] {
        let pointer = pointee.ptr.bindMemory(to: T.self, capacity: Int(pointee.len))
        let buffer = UnsafeBufferPointer(start: pointer, count: Int(pointee.len))
        return Array(buffer)
    }
}
