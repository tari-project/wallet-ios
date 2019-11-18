//  Wallet.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/15
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

enum WalletErrors: Error {
    case insufficientFunds(microTariRequired: UInt64)
    case addContact
    case invalidPublicKeyHex
    case generateTestData
    case generateTestReceiveTransaction
    case testTransactionBroadcast
}

class Wallet {
    private var ptr: OpaquePointer

    var pointer: OpaquePointer {
        return ptr
    }

    var contacts: Contacts {
        return Contacts(contactsPointer: wallet_get_contacts(ptr))
    }

    var completedTransactions: CompletedTransactions {
        return CompletedTransactions(completedTransactionsPointer: wallet_get_completed_transactions(ptr))
    }

    var pendingOutboundTransactions: PendingOutboundTransactions {
        return PendingOutboundTransactions(pendingOutboundTransactionsPointer: wallet_get_pending_outbound_transactions(ptr))
    }

    var pendingInboundTransactions: PendingInboundTransactions {
        return PendingInboundTransactions(pendingInboundTransactionsPointer: wallet_get_pending_inbound_transactions(ptr))
    }

    var availableBalance: UInt64 {
        return wallet_get_available_balance(ptr)
    }

    var pendingIncomingBalance: UInt64 {
        return wallet_get_pending_incoming_balance(ptr)
    }

    var pendingOutgoingBalance: UInt64 {
        return wallet_get_pending_outgoing_balance(ptr)
    }

    var publicKey: PublicKey {
        return PublicKey(pointer: wallet_get_public_key(ptr))
    }

    init(comsConfig: CommsConfig) {
        ptr = wallet_create(comsConfig.pointer)
    }

    func addContact(alias: String, publicKeyHex: String) throws {
        if !PublicKey.validHex(publicKeyHex) {
            throw WalletErrors.invalidPublicKeyHex
        }

        let publicKey = PublicKey(hex: publicKeyHex)

        let newContact = Contact(alias: alias, publicKey: publicKey)
        let contactAdded = wallet_add_contact(ptr, newContact.pointer)

        if !contactAdded {
            throw WalletErrors.addContact
        }
    }

    deinit {
        wallet_destroy(ptr)
    }
}
