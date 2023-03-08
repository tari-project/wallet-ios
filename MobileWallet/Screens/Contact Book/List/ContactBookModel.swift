//  ContactBookModel.swift

/*
	Package MobileWallet
	Created by Browncoat on 09/02/2023
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

import Combine

final class ContactBookModel {

    struct ContactSection {
       let title: String?
       let viewModels: [ContactViewModel]
    }

    struct ContactViewModel: Identifiable {
        let id: UUID
        let name: String
        let avatar: String
        let isFavorite: Bool
        let menuItems: [ContactBookModel.MenuItem]
    }

    enum MenuItem: UInt {
        case send
        case favorite
        case link
        case unlink
        case details
    }

    enum Action {
        case sendTokens(paymentInfo: PaymentInfo)
        case link(model: ContactsManager.Model)
        case unlink(model: ContactsManager.Model)
        case showUnlinkSuccess(emojiID: String, name: String)
        case showDetails(model: ContactsManager.Model)
    }

    // MARK: - View Model

    @Published var searchText: String = ""

    @Published private(set) var contactsList: [ContactSection] = []
    @Published private(set) var favoriteContactsList: [ContactSection] = []
    @Published private(set) var errorModel: MessageModel?
    @Published private(set) var action: Action?

    // MARK: - Properties

    @Published private var allContactList: [ContactSection] = []

    private let contactsManager = ContactsManager()

    private var contacts: [ContactsManager.Model] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        let contactsPublisher = Publishers.CombineLatest($allContactList, $searchText)
            .map { sections, searchText in
                guard !searchText.isEmpty else { return sections }
                return sections.map { ContactSection(title: $0.title, viewModels: $0.viewModels.filter { $0.name.range(of: searchText, options: .caseInsensitive) != nil }) }
            }
            .share()

        contactsPublisher
            .map { $0.filter { !$0.viewModels.isEmpty } }
            .sink { [weak self] in self?.contactsList = $0 }
            .store(in: &cancellables)

        contactsPublisher
            .map { $0.map { ContactSection(title: $0.title, viewModels: $0.viewModels.filter { $0.isFavorite }) }}
            .map { $0.filter { !$0.viewModels.isEmpty } }
            .sink { [weak self] in self?.favoriteContactsList = $0 }
            .store(in: &cancellables)
    }

    // MARK: - View Model

    func fetchContacts() {

        Task {
            do {
                try await contactsManager.fetchModels()

                var sections: [ContactSection] = []

                let internalContacts = contactsManager.tariContactModels
                let externalContacts = contactsManager.externalModels

                let internalContactSection = internalContacts.map { ContactViewModel(id: $0.id, name: $0.name, avatar: $0.avatar, isFavorite: false, menuItems: $0.menuItems) }
                let externalContactSection = externalContacts.map { ContactViewModel(id: $0.id, name: $0.name, avatar: $0.avatar, isFavorite: false, menuItems: $0.menuItems) }

                if !internalContactSection.isEmpty {
                    sections.append(ContactSection(title: nil, viewModels: internalContactSection))
                }

                if !externalContactSection.isEmpty {
                    sections.append(ContactSection(title: localized("contact_book.section.phone_contacts"), viewModels: externalContactSection))
                }

                contacts = internalContacts + externalContacts
                allContactList = sections
            } catch {
                errorModel = ErrorMessageManager.errorModel(forError: error)
            }
        }
    }

    func performAction(contactID: UUID, menuItemID: UInt) {

        guard let model = contacts.first(where: { $0.id == contactID }), let menuItem = MenuItem(rawValue: menuItemID) else { return }

        switch menuItem {
        case .send:
            performSendAction(model: model)
        case .favorite:
            return
        case .link:
            performLinkAction(model: model)
        case .unlink:
            performUnlinkAction(model: model)
        case .details:
            performShowDetailsAction(model: model)
            return
        }
    }

    func unlink(contact: ContactsManager.Model) {

        guard let emojiID = contact.internalModel?.emojiID, let name = contact.externalModel?.fullname else { return }

        do {
            try contactsManager.unlink(contact: contact)
            fetchContacts()
            action = .showUnlinkSuccess(emojiID: emojiID, name: name)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    // MARK: - Handlers

    private func performSendAction(model: ContactsManager.Model) {

        do {
            guard let paymentInfo = try model.paymentInfo else { return }
            action = .sendTokens(paymentInfo: paymentInfo)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    private func performLinkAction(model: ContactsManager.Model) {
        action = .link(model: model)
    }

    private func performShowDetailsAction(model: ContactsManager.Model) {
        action = .showDetails(model: model)
    }

    private func performUnlinkAction(model: ContactsManager.Model) {
        action = .unlink(model: model)
    }
}
