//  InternalContactsManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 02/03/2023
	Using Swift 5.0
	Running on macOS 13.0

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

final class InternalContactsManager {

    struct ContactModel: Hashable {

        let alias: String?
        let emojiID: String
        let hex: String
        private(set) var contact: Contact?

        static func == (lhs: InternalContactsManager.ContactModel, rhs: InternalContactsManager.ContactModel) -> Bool {
            lhs.hex == rhs.hex
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(hex)
        }
    }

    func fetchAllModels() throws -> [ContactModel] {

        var models: [ContactModel] = []

        models += try fetchWalletContacts().map { try ContactModel(alias: $0.alias, emojiID: $0.address.emojis, hex: $0.address.byteVector.hex, contact: $0) }
        models += try fetchTariAddresses().map { try ContactModel(alias: nil, emojiID: $0.emojis, hex: $0.byteVector.hex, contact: nil) }

        return models
            .reduce(into: [ContactModel]()) { collection, model in
                guard collection.first(where: {$0.emojiID == model.emojiID }) == nil else { return }
                collection.append(model)
            }
            .sorted {

                let firstAlias = $0.alias?.lowercased()
                let secondAlias = $1.alias?.lowercased()

                if let firstAlias, let secondAlias {
                    return firstAlias < secondAlias
                }

                if firstAlias != nil {
                    return true
                }

                if secondAlias != nil {
                    return false
                }

                return $0.emojiID < $1.emojiID
            }
    }

    func create(name: String, address: TariAddress) throws -> ContactModel {
        let contact = try Contact(alias: name, addressPointer: address.pointer)
        try Tari.shared.contacts.upsert(contact: contact)
        return try ContactModel(alias: name, emojiID: address.emojis, hex: address.byteVector.hex, contact: contact)
    }

    func update(name: String, contact: ContactModel) throws {

        let address: TariAddress

        if let existingContact = contact.contact {
            address = try TariAddress(emojiID: existingContact.address.emojis)
        } else {
            address = try TariAddress(emojiID: contact.emojiID)
        }

        let contact = try Contact(alias: name, addressPointer: address.pointer)
        try Tari.shared.contacts.upsert(contact: contact)
    }

    func remove(contact: ContactModel) throws {
        guard let contact = contact.contact else { return }
        try Tari.shared.contacts.remove(contact: contact)
    }

    private func fetchWalletContacts() throws -> [Contact] {
        try Tari.shared.contacts.allContacts
    }

    private func fetchTariAddresses() throws -> [TariAddress] {

        var transactions: [Transaction] = []

        transactions += Tari.shared.transactions.pendingInbound
        transactions += Tari.shared.transactions.pendingOutbound
        transactions += Tari.shared.transactions.cancelled
        transactions += Tari.shared.transactions.completed

        return try transactions
            .map { try $0.address }
    }
}
