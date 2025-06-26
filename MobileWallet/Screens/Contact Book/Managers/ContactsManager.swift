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

import UIKit

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
    var isPermissionGranted: Bool { true }

    // MARK: - Properties

    private(set) var tariContactModels: [Model] = []
    private let internalContactsManager = InternalContactsManager()

    // MARK: - Actions
    
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
        }
    }

    func remove(contact: Model) throws {
        if let components = contact.internalModel?.addressComponents {
            try internalContactsManager.remove(components: components)
        }
    }

    func createInternalModel(name: String, isFavorite: Bool, address: TariAddress) throws -> Model {
        let internalModel = try internalContactsManager.create(alias: name, isFavorite: isFavorite, address: address)
        return Model(internalModel: internalModel)
    }

    private func update(tariContactModels: [Model]) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
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
