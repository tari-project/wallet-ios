//  PendingOutboundTransaction.swift

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

final class PendingOutboundTransaction: Transaction {

    // MARK: - Protocol

    var isOutboundTransaction: Bool { true }
    var isCancelled: Bool { false }
    var isPending: Bool { true }

    // MARK: - Properties

    var identifier: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = pending_outbound_transaction_get_transaction_id(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var amount: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = pending_outbound_transaction_get_amount(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var fee: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = pending_outbound_transaction_get_fee(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var paymentId: String {
        get throws {
            try paymentId(
                getPaymentId: pending_outbound_transaction_get_payment_id,
                getPaymentIdAsBytes: pending_outbound_transaction_get_payment_id_as_bytes,
                getUserPaymentIdAsBytes: pending_outbound_transaction_get_user_payment_id_as_bytes
            )
        }
    }

    var timestamp: UInt64 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = pending_outbound_transaction_get_timestamp(pointer, errorCodePointer)

            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    var address: TariAddress {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = pending_outbound_transaction_get_destination_tari_address(pointer, errorCodePointer)

            guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
            return TariAddress(pointer: pointer)
        }
    }

    var status: TransactionStatus {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = pending_outbound_transaction_get_status(pointer, errorCodePointer)

            guard errorCode == 0, let status = TransactionStatus(rawValue: result) else { throw WalletError(code: errorCode) }
            return status
        }
    }

    let pointer: OpaquePointer

    // MARK: - Initialisers

    init(pointer: OpaquePointer) {
        self.pointer = pointer

    }

    // MARK: - Deinitialiser

    deinit {
        pending_outbound_transaction_destroy(pointer)
    }
}
