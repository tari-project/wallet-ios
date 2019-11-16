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
    case generateTestData
    case insufficientFunds(microTariRequired: UInt64)
    case createContact
    case addContact
    case invalidPublicKeyHex
}

class Wallet {
    private var ptr: OpaquePointer
    var contacts: Contacts

    init(comsConfig: CommsConfig) {
        ptr = wallet_create(comsConfig.pointer())
        contacts = Contacts(contactsPointer: wallet_get_contacts(ptr))
    }

    init(hex: String) {
        let hexPtr = UnsafeMutablePointer<Int8>(mutating: hex)
        ptr = private_key_from_hex(hexPtr)
        contacts = Contacts(contactsPointer: wallet_get_contacts(ptr))
    }

    //TODO create convenience get var
    func availableBalance() -> UInt64 {
        return wallet_get_available_balance(ptr)
    }

    //TODO create convenience get var
    func pendingIncomingBalance() -> UInt64 {
        return wallet_get_pending_incoming_balance(ptr)
    }

    //TODO create convenience get var
    func pendingOutgoingBalance() -> UInt64 {
        wallet_get_pending_outgoing_balance(ptr)
    }

    func publicKey() -> PublicKey {
        return PublicKey(pointer: wallet_get_public_key(ptr))
    }

    func addContact(alias: String, publicKeyHex: String) throws {
        if !PublicKey.validHex(publicKeyHex) {
            throw WalletErrors.invalidPublicKeyHex
        }

        let publicKey = PublicKey(hex: publicKeyHex)
        let aliasPointer = UnsafeMutablePointer<Int8>(mutating: (alias as NSString).utf8String)
        let contactPointer = contact_create(aliasPointer, publicKey.pointer())

        if contactPointer != nil {
            let newContact = Contact(contactPointer: contactPointer!)
            let contactAdded = wallet_add_contact(ptr, newContact.pointer())

            if !contactAdded {
                throw WalletErrors.addContact
            }
        } else {
           throw WalletErrors.createContact
        }
    }

    func generateTestData() throws {
        let didGenerateData = wallet_test_generate_data(ptr)

        if !didGenerateData {
            throw WalletErrors.generateTestData
        }
    }

    func pointer() -> OpaquePointer {
        return ptr
    }

    deinit {
        wallet_destroy(ptr)
    }
}
