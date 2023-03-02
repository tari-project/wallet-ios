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

struct ContactViewModel: Identifiable {
    let id: UUID
    let name: String
    let avatar: String
    let emojiID: String
    let isFavorite: Bool
}

final class ContactBookModel {

    enum MenuItem: UInt {
        case send
        case favorite
        case link
        case unlink
        case details
    }

    enum Action {
        case sendTokens(paymentInfo: PaymentInfo)
        case showDetails(hexAddress: String)
    }

    // MARK: - View Model

    @Published var searchText: String = ""

    @Published private(set) var contacts: [ContactViewModel] = []
    @Published private(set) var favoriteContacts: [ContactViewModel] = []
    @Published private(set) var errorModel: MessageModel?
    @Published private(set) var action: Action?

    // MARK: - Properties

    @Published private var allContactModels: [ContactViewModel] = []
    @Published private var walletContacts: [WalletContactsManager.ContactModel] = []

    private let walletContactsManager = WalletContactsManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        let contactsPublisher = Publishers.CombineLatest($allContactModels, $searchText)
            .map { contacts, searchText in
                guard !searchText.isEmpty else { return contacts }
                return contacts.filter { $0.name.range(of: searchText, options: .caseInsensitive) != nil }
            }
            .share()

        contactsPublisher
            .sink { [weak self] in self?.contacts = $0 }
            .store(in: &cancellables)

        contactsPublisher
            .map { $0.filter { $0.isFavorite }}
            .sink { [weak self] in self?.favoriteContacts = $0 }
            .store(in: &cancellables)

        $walletContacts
            .map { $0.map { ContactViewModel(id: UUID(), name: $0.alias ?? $0.emojiID, avatar: $0.emojiID.firstOrEmpty, emojiID: $0.emojiID, isFavorite: false) }}
            .assign(to: \.allContactModels, on: self)
            .store(in: &cancellables)
    }

    // MARK: - View Model

    func fetchContacts() {
        do {
            walletContacts = try walletContactsManager.fetchAllModels()
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func performAction(contactID: UUID, menuItemID: UInt) {

        guard let contact = allContactModels.first(where: { $0.id == contactID }), let menuItem = MenuItem(rawValue: menuItemID) else { return }

        switch menuItem {
        case .send:
            performSendAction(contact: contact)
        case .favorite:
            return
        case .link:
            return
        case .unlink:
            return
        case .details:
            performShowDetailsAction(contact: contact)
            return
        }
    }

    // MARK: - Handlers

    private func performSendAction(contact: ContactViewModel) {
        do {
            let address = try TariAddress(emojiID: contact.emojiID)
            let paymentInfo = PaymentInfo(address: address, yatID: nil)
            action = .sendTokens(paymentInfo: paymentInfo)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    private func performShowDetailsAction(contact: ContactViewModel) {
        guard let walletContact = walletContacts.first(where: { $0.emojiID == contact.emojiID }) else { return }
        action = .showDetails(hexAddress: walletContact.hex)
    }
}

final class WalletContactsManager {

    struct ContactModel {
        let alias: String?
        let emojiID: String
        let hex: String
    }

    func fetchAllModels() throws -> [ContactModel] {

        var models: [ContactModel] = []

        models += try fetchWalletContacts().map { try ContactModel(alias: $0.alias, emojiID: $0.address.emojis, hex: $0.address.byteVector.hex) }
        models += try fetchTariAddresses().map { try ContactModel(alias: nil, emojiID: $0.emojis, hex: $0.byteVector.hex) }

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
