//  ContactsManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 06/03/2023
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

import SwiftUI
import Combine

struct ContactModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let alias: String?
    var avatar: String
    let address: TariAddressComponents?
    var isFavorite: Bool
    var isFFIContact: Bool
    var type: ContactsManager.ContactType

    init(internalModel: InternalContactsManager.ContactModel?) {
        alias = internalModel?.alias ?? internalModel?.defaultAlias
        name = alias ?? internalModel?.addressComponents.formattedCoreAddress ?? ""
        avatar = internalModel?.addressComponents.spendKey.firstOrEmpty ?? ""
        address = internalModel?.addressComponents
        isFavorite = internalModel?.isFavorite ?? false
        isFFIContact = internalModel?.alias != nil
        type = internalModel != nil ? .internalOrEmojiID : .empty
    }
}

final class ContactsManager {
    enum ContactType {
        case internalOrEmojiID
        case empty
    }

    enum InternalError: Error {
        case emptyContactName
    }

    struct Model: Identifiable, Hashable {
        let id = UUID()
        let internalModel: InternalContactsManager.ContactModel?
        let name: String
        let alias: String?
        var avatar: String

        var isFavorite: Bool { internalModel?.isFavorite ?? false }
        var isFFIContact: Bool { internalModel?.alias != nil }
        var hasIntrenalModel: Bool { internalModel != nil }

        var type: ContactType {
            if hasIntrenalModel {
                return .internalOrEmojiID
            }
            return .empty
        }

        init(internalModel: InternalContactsManager.ContactModel?) {
            self.internalModel = internalModel

            alias = internalModel?.alias ?? internalModel?.defaultAlias
            name = alias ?? internalModel?.addressComponents.formattedCoreAddress ?? ""
            avatar = internalModel?.addressComponents.spendKey.firstOrEmpty ?? ""
        }
    }

    // MARK: - Properties
    
    static var contactUpdated = PassthroughSubject<Void, Never>()

    private(set) var tariContactModels: [Model] = []
    private let internalContactsManager = InternalContactsManager()

    // MARK: - Actions
    func contacts() -> [ContactModel] {
        tariContactModels.map {
            ContactModel(internalModel: $0.internalModel)
        }
    }
    
    func contact(for address: TariAddress) async throws -> ContactsManager.Model? {
        try await fetchModels()
        return try tariContactModels.first {
            try $0.internalModel?.addressComponents == address.components
        }
    }

    func fetchModels() async throws {
        let internalContacts = try internalContactsManager.fetchAllModels()
        let tariContactModels = internalContacts.map { Model(internalModel: $0) }
        await update(tariContactModels: tariContactModels)
    }

    func updatedModel(model: Model) -> Model {
        if let internalModel = model.internalModel, let updatedModel = tariContactModels.first(where: { $0.internalModel == internalModel }) {
            return updatedModel
        }
        return model
    }

    func update(alias: String?, isFavorite: Bool, contact: Model) throws {
        if let internalContact = contact.internalModel {
            if let alias, !alias.isEmpty {
                try internalContactsManager.update(alias: alias, isFavorite: isFavorite, base58: internalContact.addressComponents.fullRaw)
            } else {
                try internalContactsManager.remove(components: internalContact.addressComponents)
            }
            Self.contactUpdated.send()
        }
    }
    
    func update(alias: String, for components: TariAddressComponents, onContactUpdate: (ContactsManager.Model) -> Void) async throws {
        let address = try TariAddress(base58: components.fullRaw)
        try await update(alias: alias, for: address, onContactUpdate: onContactUpdate)
    }
    
    func update(alias: String, for address: TariAddress, onContactUpdate: (ContactsManager.Model) -> Void) async throws {
        if let contact = try await contact(for: address) {
            try update(alias: alias, isFavorite: contact.isFavorite, contact: contact)
            if let contact = try await self.contact(for: address) {
                onContactUpdate(contact)
            }
        } else {
            let contact = try createInternalModel(name: alias, isFavorite: false, address: address)
            onContactUpdate(contact)
        }
        Tari.mainWallet.transactions.fetchData()
        Self.contactUpdated.send()
    }

    func remove(contact: Model) throws {
        if let components = contact.internalModel?.addressComponents {
            try remove(contact: components)
        }
    }
    
    func remove(contact: TariAddressComponents) throws {
        try internalContactsManager.remove(components: contact)
        Self.contactUpdated.send()
    }

    func createInternalModel(name: String, isFavorite: Bool, address: TariAddress) throws -> Model {
        let internalModel = try internalContactsManager.create(alias: name, isFavorite: isFavorite, address: address)
        return Model(internalModel: internalModel)
    }
    
    func recentAddresses(count: Int) throws -> [TariAddress] {
        let transactions = Tari.mainWallet.allTransactions
        let addresses = try transactions
            .map { try $0.address }
            .reduce(into: (identifiers: [String](), output: [TariAddress]())) { result, address in
                let addressComponents = try address.components
                guard !result.identifiers.contains(addressComponents.uniqueIdentifier), !addressComponents.isUnknownAddress else { return }
                result.identifiers.append(addressComponents.uniqueIdentifier)
                result.output.append(address)
            }
            .output
            .prefix(3)
        return Array(addresses)
    }

    private func update(tariContactModels: [Model]) async {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.tariContactModels = tariContactModels
                continuation.resume()
            }
        }
    }
}

extension ContactsManager.Model {
    var paymentInfo: PaymentInfo? {
        get throws {
            guard let internalModel else { return nil }
            return PaymentInfo(addressComponents: internalModel.addressComponents, alias: nil, yatID: nil, amount: nil, feePerGram: nil, note: nil)
        }
    }
}
