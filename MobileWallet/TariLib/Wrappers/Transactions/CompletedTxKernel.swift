//  CompletedTxKernel.swift

/*
	Package MobileWallet
	Created by David Main on 9/2/21
	Using Swift 5.0
	Running on macOS 11.5

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

enum CompletedTxKernelError: Error {
    case generic(_ errorCode: Int32)
}

final class CompletedTxKernel {
    let pointer : OpaquePointer

    var excess: String {
        get throws  {
            var errorCode: Int32 = -1
            let excessPointer = withUnsafeMutablePointer(to: &errorCode, { error in
                transaction_kernel_get_excess_hex(pointer, error)
            })
            guard errorCode == 0 else {
                throw ContactError.generic(errorCode)
            }

            return String(validatingUTF8: excessPointer!)!
        }
    }

    var excessPublicNonce: String {
        get throws {
            var errorCode: Int32 = -1
            let noncePointer = withUnsafeMutablePointer(to: &errorCode, { error in
                transaction_kernel_get_excess_public_nonce_hex(pointer, error)
            })
            guard errorCode == 0 else {
                throw ContactError.generic(errorCode)
            }

            return String(validatingUTF8: noncePointer!)!
        }
    }

    var excessSignature: String {
        get throws {
            var errorCode: Int32 = -1
            let signaturePointer = withUnsafeMutablePointer(to: &errorCode, { error in
                transaction_kernel_get_excess_signature_hex(pointer, error)
            })
            guard errorCode == 0 else {
                throw ContactError.generic(errorCode)
            }

            return String(validatingUTF8: signaturePointer!)!
        }
    }

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        transaction_kernel_destroy(pointer)
    }
}
