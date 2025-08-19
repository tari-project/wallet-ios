//  LinkContactsModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 07/03/2023
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
import UIKit

final class ContactSelectionModel {
    enum Action {
        case showConfirmation(address: String, name: String)
        case showSuccess(address: String, name: String)
        case moveToAddContact
    }

    struct PlaceholderModel {
        let title: String?
        let message: String?
        let buttonTitle: String?
    }

    // MARK: - View Model

    @Published var searchText: String = ""

    @Published private(set) var name: String?
    @Published private(set) var models: [ContactsManager.Model] = []
    @Published private(set) var action: Action?
    @Published private(set) var errorModel: MessageModel?
    @Published private(set) var placeholder: PlaceholderModel?

    // MARK: - Properties

    @Published private var allModels: [ContactsManager.Model] = []

    private let contactsManager = ContactsManager()
    private let contactModel: ContactsManager.Model

    private var selectedContact: InternalContactsManager.ContactModel?
    private var cancellables = Set<AnyCancellable>()

    init(contactModel: ContactsManager.Model) {
        self.contactModel = contactModel
        setupCallbacks()
    }

    // MARK: - Setups

    func fetchData() {
        Task {
            do {
                try await contactsManager.fetchModels()
                updateModels()
            } catch {
                errorModel = ErrorMessageManager.errorModel(forError: error)
            }
        }

        name = contactModel.internalModel?.addressComponents.formattedCoreAddress
    }

    private func updateModels() {
        allModels = contactsManager.tariContactModels.filter { $0.type == .internalOrEmojiID }
    }

    private func setupCallbacks() {
        Publishers.CombineLatest($allModels, $searchText)
            .map { models, searchText in
                guard !searchText.isEmpty else { return models }
                return models.filter { $0.name.range(of: searchText, options: .caseInsensitive) != nil }
            }
            .sink { [weak self] in self?.models = $0 }
            .store(in: &cancellables)

        $allModels
            .map(\.isEmpty)
            .map { [weak self] in $0 ? self?.makePlaceholderModel() : nil }
            .assignPublisher(to: \.placeholder, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func selectModel(index: IndexPath) {
        guard models.count > index.row else { return }
        let model = models[index.row]

        guard let internalModel = model.internalModel else {
            errorModel = ErrorMessageManager.errorModel(forError: nil)
            return
        }

        selectedContact = internalModel
        action = .showConfirmation(address: internalModel.addressComponents.formattedCoreAddress, name: internalModel.alias ?? "")
    }

    func confirmSelection() {
        guard let selectedContact else {
            errorModel = ErrorMessageManager.errorModel(forError: nil)
            return
        }

        do {
            try contactsManager.update(alias: selectedContact.alias, isFavorite: selectedContact.isFavorite, contact: contactModel)
            action = .showSuccess(address: selectedContact.addressComponents.formattedCoreAddress, name: selectedContact.alias ?? "")
            cancelSelection()
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func cancelSelection() {
        selectedContact = nil
    }

    func performPlaceholderAction() {
        action = .moveToAddContact
    }

    // MARK: - Handlers

    private func makePlaceholderModel() -> PlaceholderModel {
        PlaceholderModel(
            title: localized("contact_book.link_contacts.placeholder.title"),
            message: localized("contact_book.link_contacts.placeholder.message.internal"),
            buttonTitle: localized("contact_book.link_contacts.placeholder.buttons.add_contact")
        )
    }
}
