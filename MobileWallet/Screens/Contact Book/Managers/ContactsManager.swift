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

final class ContactsManager {

    enum ContactType {
        case internalOrEmojiID
        case external
        case linked
        case empty
    }

    struct Model: Identifiable {

        let id: UUID = UUID()
        let internalModel: InternalContactsManager.ContactModel?
        let externalModel: ExternalContactsManager.ContactModel?

        var name: String {
            guard let externalModel else { return internalModel?.alias ?? internalModel?.emojiID ?? "" }
            return externalModel.fullname
        }

        var avatar: String {
            guard let externalModel else { return internalModel?.emojiID.firstOrEmpty ?? "" }
            return [externalModel.firstName, externalModel.lastName]
                .compactMap { $0.first }
                .map { String($0) }
                .joined()
        }

        var isFFIContact: Bool { internalModel?.alias != nil }
        var hasIntrenalModel: Bool { internalModel != nil }
        var hasExternalModel: Bool { externalModel != nil }

        var type: ContactType {

            if hasIntrenalModel && hasExternalModel {
                return .linked
            }

            if hasIntrenalModel {
                return .internalOrEmojiID
            }

            if hasExternalModel {
                return .external
            }

            return .empty
        }
    }

    var isPermissionGranted: Bool {
        externalContactsManager.isPermissionGranted
    }

    // MARK: - Properties

    @Published private(set) var tariContactModels: [Model] = []
    @Published private(set) var externalModels: [Model] = []

    private let internalContactsManager = InternalContactsManager()
    private let externalContactsManager = ExternalContactsManager()

    // MARK: - Actions

    func fetchModels() async throws {

        var internalContacts = try internalContactsManager.fetchAllModels()
        let externalContacts = try await externalContactsManager.fetchAllModels()
        var filteredExternalContacts = externalContacts

        var tariContactModels = [Model]()

        for index in 0..<externalContacts.count {

            let externalContact = externalContacts[index]
            guard let linkedEmojiID = externalContact.emojiID, let linkedContactIndex = internalContacts.firstIndex(where: { $0.emojiID == linkedEmojiID }) else { continue }
            let internalContact = internalContacts[linkedContactIndex]

            internalContacts.remove(at: linkedContactIndex)
            filteredExternalContacts.remove(at: index)

            tariContactModels.append(Model(internalModel: internalContact, externalModel: externalContact))
        }

        tariContactModels += internalContacts.map { Model(internalModel: $0, externalModel: nil) }

        self.tariContactModels = tariContactModels.sorted { $0.name < $1.name }
        externalModels = filteredExternalContacts.map { Model(internalModel: nil, externalModel: $0) }.sorted { $0.name < $1.name }
    }

    func updatedModel(model: Model) -> Model {

        if let externalModel = model.externalModel, let updatedModel = tariContactModels.first(where: { $0.externalModel == externalModel }) {
            return updatedModel
        }

        if let externalModel = model.externalModel, let updatedModel = externalModels.first(where: { $0.externalModel == externalModel }) {
            return updatedModel
        }

        if let internalModel = model.internalModel, let updatedModel = tariContactModels.first(where: { $0.internalModel == internalModel }) {
            return updatedModel
        }

        return model
    }

    func update(nameComponents: [String], yat: String, contact: Model) throws {

        let internalContact = contact.internalModel
        let externalContact = contact.externalModel

        if let internalContact {
            try internalContactsManager.update(name: nameComponents.joined(separator: " "), contact: internalContact)
        }

        if let externalContact, nameComponents.count == 2 {
            try externalContactsManager.update(firstName: nameComponents[0], lastName: nameComponents[1], yat: yat, contact: externalContact)
        }
    }

    func remove(contact: Model) throws {

        if let internalContact = contact.internalModel {
            try internalContactsManager.remove(contact: internalContact)
        }

        if let externalContact = contact.externalModel {
            try externalContactsManager.remove(contact: externalContact)
        }
    }

    func link(internalContact: InternalContactsManager.ContactModel, externalContact: ExternalContactsManager.ContactModel) throws {
        try externalContactsManager.link(hex: internalContact.hex, emojiID: internalContact.emojiID, contact: externalContact)
        try internalContactsManager.update(name: externalContact.fullname, contact: internalContact)
    }

    func unlink(contact: Model) throws {
        guard let externalContact = contact.externalModel else { return }
        try externalContactsManager.unlink(contact: externalContact)
    }
}

extension ContactsManager.Model {

    var menuItems: [ContactBookModel.MenuItem] {

        var items: [ContactBookModel.MenuItem] = []

        if isFFIContact {
            items.append(.send)
        }

        if hasIntrenalModel {
            items.append(.favorite)
        }

        if hasIntrenalModel, hasExternalModel {
            items.append(.unlink)
        } else {
            items.append(.link)
        }

        items.append(.details)

        return items
    }

    var paymentInfo: PaymentInfo? {
        get throws {
            guard let internalModel else { return nil }
            let address = try TariAddress(hex: internalModel.hex)
            return PaymentInfo(address: address, yatID: nil)
        }
    }
}
