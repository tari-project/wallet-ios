//  CompletedTransaction.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 26/09/2022
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

final class CompletedTransaction: Transaction {

    enum RejectionReason: Int32 {
        case notCancelled = -1
        case unknown
        case userCancelled
        case timeout
        case doubleSpend
        case orphan
        case timeLocked
        case invalidTransaction
        case abandonedCoinbase

        init(code: Int32) {
            self = Self(rawValue: code) ?? .unknown
        }
    }

    // MARK: - Protocol

    var address: TariAddress {
        get throws { try isOutboundTransaction ? destination : source }
    }

    let isCancelled: Bool
    var isPending: Bool { false }

    // MARK: - Properties

    var identifier: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_transaction_id(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var confirmationCount: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_confirmations(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var amount: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_amount(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var fee: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_fee(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var message: String {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_payment_id_as_bytes(pointer, errorCodePointer)

            /** ## Returns
            * `*mut ByteVector` - Pointer to the created ByteVector. Note that it will be ptr::null_mut()
            * if the byte_array pointer was null or if the elements in the byte_vector don't match
            * element_count when it is created
            *
            * # Safety
            * The ```byte_vector_destroy``` function must be called when finished with a ByteVector to prevent a memory leak
            */
            guard errorCode == 0, let result else { throw WalletError(code: errorCode) }

            // Create a ByteVector instance that will handle memory management
            let byteVector = ByteVector(pointer: result)

            // Convert the bytes to a string
            return try byteVector.data.string
        }
    }

    var timestamp: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_timestamp(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var minedBlockHeight: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_mined_height(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var source: TariAddress {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_source_tari_address(pointer, errorCodePointer)

            guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
            return TariAddress(pointer: pointer)
        }
    }

    var destination: TariAddress {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_destination_tari_address(pointer, errorCodePointer)

            guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
            return TariAddress(pointer: pointer)
        }
    }

    var transactionKernel: CompletedTransactionKernel {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_transaction_kernel(pointer, errorCodePointer)

            guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
            return CompletedTransactionKernel(pointer: pointer)
        }
    }

    var status: TransactionStatus {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_status(pointer, errorCodePointer)

            guard errorCode == 0, let status = TransactionStatus(rawValue: result) else { throw WalletError(code: errorCode) }
            return status
        }
    }

    var isOutboundTransaction: Bool {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_is_outbound(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var rejectionReason: RejectionReason {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = completed_transaction_get_cancellation_reason(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return RejectionReason(code: result)
        }
    }

    private let pointer: OpaquePointer

    // MARK: - Initialiser

    init(pointer: OpaquePointer, isCancelled: Bool) {
        self.pointer = pointer
        self.isCancelled = isCancelled
    }

    // MARK: - Deinitialiser

    deinit {
        completed_transaction_destroy(pointer)
    }
}
