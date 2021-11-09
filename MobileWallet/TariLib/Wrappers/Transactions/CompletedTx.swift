//  CompletedTx.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/17
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

enum CompletedTxError: Error {
    case generic(_ errorCode: Int32)
}

class CompletedTx: TxProtocol {
    private var ptr: OpaquePointer
    private var cachedContact: Contact?
    let isCancelled: Bool

    var pointer: OpaquePointer {
        return ptr
    }

    var id: (UInt64, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            completed_transaction_get_transaction_id(ptr, error)})
        return (result, errorCode != 0 ? CompletedTxError.generic(errorCode) : nil)
    }

    var confirmationCount: (UInt64, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(
            to: &errorCode, {
                error in
                completed_transaction_get_confirmations(ptr, error)
            }
        )
        return (result, errorCode != 0 ? CompletedTxError.generic(errorCode) : nil)
    }

    var microTari: (MicroTari?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(
            to: &errorCode, {
                error in
                completed_transaction_get_amount(ptr, error)
            }
        )
        guard errorCode == 0 else {
            return (nil, CompletedTxError.generic(errorCode))
        }

        return (MicroTari(result), nil)
    }

    var fee: (MicroTari?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            completed_transaction_get_fee(ptr, error)})
        return (MicroTari(result), errorCode != 0 ? CompletedTxError.generic(errorCode) : nil)
    }

    var message: (String, Error?) {
        var errorCode: Int32 = -1
        let resultPtr = withUnsafeMutablePointer(to: &errorCode, { error in
            completed_transaction_get_message(ptr, error)})
        let result = String(cString: resultPtr!)

        let mutable = UnsafeMutablePointer<Int8>(mutating: resultPtr!)
        string_destroy(mutable)

        return (result, errorCode != 0 ? CompletedTxError.generic(errorCode) : nil)
    }

    var timestamp: (UInt64, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            completed_transaction_get_timestamp(ptr, error)})
        return (result, errorCode != 0 ? CompletedTxError.generic(errorCode) : nil)
    }

    var sourcePublicKey: (PublicKey?, Error?) {
        var errorCode: Int32 = -1
        let resultPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            completed_transaction_get_source_public_key(ptr, error)
        })
        guard errorCode == 0 else {
            return (nil, CompletedTxError.generic(errorCode))
        }

        return (PublicKey(pointer: resultPointer!), nil)
    }

    var destinationPublicKey: (PublicKey?, Error?) {
        var errorCode: Int32 = -1
        let resultPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            completed_transaction_get_destination_public_key(ptr, error)
        })
        guard errorCode == 0 else {
            return (nil, CompletedTxError.generic(errorCode))
        }

        return (PublicKey(pointer: resultPointer!), nil)
    }

    var transactionKernel: (CompletedTxKernel?, Error?) {
        var errorCode: Int32 = -1
        let resultPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            completed_transaction_get_transaction_kernel(ptr, error)
        })
        guard errorCode == 0 else {
            return (nil, CompletedTxKernelError.generic(errorCode))
        }

        return (CompletedTxKernel(pointer: resultPointer!), nil)
    }

    var status: (TxStatus, Error?) {
        var errorCode: Int32 = -1
        let statusCode: Int32 = withUnsafeMutablePointer(to: &errorCode, { error in
            completed_transaction_get_status(ptr, error)})
        guard errorCode == 0 else {
            return (.unknown, CompletedTxError.generic(errorCode))
        }

        return (statusFrom(code: statusCode), nil)
    }

    var direction: TxDirection {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            completed_transaction_is_outbound(ptr, error)})
        guard errorCode == 0 else {
            return .none
        }

        if result {
            return .outbound
        }

        return .inbound
    }

    var contact: (Contact?, Error?) {
        if cachedContact != nil {
            return (cachedContact, nil)
        }

        guard let wallet = TariLib.shared.tariWallet else {
            return (nil, WalletErrors.walletNotInitialized)
        }

        let (contacts, contactsError) = wallet.contacts
        guard contactsError == nil else {
            return (nil, contactsError)
        }

        let (pubKey, pubKeyError) = self.direction == TxDirection.inbound ? self.sourcePublicKey : self.destinationPublicKey
        guard pubKeyError == nil else {
            return (nil, pubKeyError)
        }

        do {
            cachedContact = try contacts!.find(publicKey: pubKey!)
            return (cachedContact, nil)
        } catch {
            return (nil, error)
        }
    }

    init(completedTxPointer: OpaquePointer, isCancelled: Bool = false) {
        ptr = completedTxPointer
        self.isCancelled = isCancelled
    }

    deinit {
        completed_transaction_destroy(ptr)
    }
}
