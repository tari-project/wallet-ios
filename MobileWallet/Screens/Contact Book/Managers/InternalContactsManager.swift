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
        let defaultAlias: String?
        let addressComponents: TariAddressComponents
        let isFavorite: Bool

        static func == (lhs: InternalContactsManager.ContactModel, rhs: InternalContactsManager.ContactModel) -> Bool {
            lhs.addressComponents.uniqueIdentifier == rhs.addressComponents.uniqueIdentifier
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(addressComponents.uniqueIdentifier)
        }
    }

    func fetchAllModels() throws -> [ContactModel] {

        var models: [ContactModel] = []

        models += try fetchWalletContacts().map { try ContactModel(alias: $0.alias, defaultAlias: nil, addressComponents: $0.address.components, isFavorite: $0.isFavorite) }
        models += try fetchTariAddresses().map {
            let placeholder = try $0.components.isUnknownAddress ? localized("transaction.unknown_source") : nil
            return try ContactModel(alias: nil, defaultAlias: placeholder, addressComponents: $0.components, isFavorite: false)
        }

        return models
            .reduce(into: [ContactModel]()) { collection, model in
                guard collection.first(where: {$0.addressComponents.uniqueIdentifier == model.addressComponents.uniqueIdentifier }) == nil else { return }
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

                return $0.addressComponents.fullEmoji < $1.addressComponents.fullEmoji
            }
    }

    func create(name: String, isFavorite: Bool, address: TariAddress) throws -> ContactModel {
        let contact = try Contact(alias: name, isFavorite: isFavorite, addressPointer: address.pointer)
        try Tari.shared.contacts.upsert(contact: contact)
        return try ContactModel(alias: name, defaultAlias: nil, addressComponents: address.components, isFavorite: isFavorite)
    }

    func update(name: String, isFavorite: Bool, base58: String) throws {
        let address = try TariAddress(base58: base58)
        let contact = try Contact(alias: name, isFavorite: isFavorite, addressPointer: address.pointer)
        try Tari.shared.contacts.upsert(contact: contact)
    }

    func remove(uniqueIdentifier: String) throws {
        guard let contact = try Tari.shared.contacts.findContact(uniqueIdentifier: uniqueIdentifier) else { return }
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
            .filter { try !$0.isCoinbase }
            .map { try $0.address }
    }
}
