//  ChatSelectContactModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 29/11/2023
	Using Swift 5.0
	Running on macOS 14.0

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

final class ChatSelectContactModel {

    enum Action {
        case startConversation(address: TariAddress)
    }

    // MARK: - View Model

    @Published private(set) var contactsList: [ContactBookContactListView.Section] = []
    @Published private(set) var favoriteContactsList: [ContactBookContactListView.Section] = []
    @Published private(set) var action: Action?
    @Published private(set) var errorModel: MessageModel?

    // MARK: - Properties

    @Published private var contacts: [ContactsManager.Model] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Properties

    private let contactsManager = ContactsManager()

    // MARK: - Setups

    private func setupCallbacks() {

        $contacts
            .map {
                $0.map { ContactBookCell.ViewModel(
                    id: $0.id,
                    name: $0.name,
                    avatarText: $0.avatar,
                    avatarImage: $0.avatarImage,
                    isFavorite: $0.isFavorite,
                    contactTypeImage: nil,
                    isSelectable: false
                )
                }
            }
            .sink { [weak self] in self?.contactsList = [ContactBookContactListView.Section(title: nil, items: $0)] }
            .store(in: &cancellables)

        $contacts
            .map { $0.filter { $0.isFavorite }}
            .map {
                $0.map { ContactBookCell.ViewModel(
                    id: $0.id,
                    name: $0.name,
                    avatarText: $0.avatar,
                    avatarImage: $0.avatarImage,
                    isFavorite: $0.isFavorite,
                    contactTypeImage: nil,
                    isSelectable: false
                )
                }
            }
            .sink { [weak self] in self?.favoriteContactsList = [ContactBookContactListView.Section(title: nil, items: $0)] }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func fetchContacts() {
        Task {
            do {
                try await contactsManager.fetchModels()
                contacts = contactsManager.tariContactModels
            } catch {
                errorModel = ErrorMessageManager.errorModel(forError: error)
            }
        }
    }

    func select(contactID: UUID) {
        do {
            guard let address = try contacts.first(where: { $0.id == contactID })?.tariAddress else { return }
            action = .startConversation(address: address)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }
}
