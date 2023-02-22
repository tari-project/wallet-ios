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
import UIKit

struct ContactViewModel: Identifiable {
    let id: UUID
    let name: String
    let avatar: String
    let emojiID: String
    let isFavorite: Bool
}

final class ContactBookModel {

    // MARK: - View Model

    @Published var searchText: String = ""

    @Published private(set) var contacts: [ContactViewModel] = []
    @Published private(set) var favoriteContacts: [ContactViewModel] = []
    @Published private(set) var errorModel: MessageModel?
    @Published private(set) var recipientPaymentInfo: PaymentInfo?

    // MARK: - Properties

    @Published private var allContacts: [ContactViewModel] = []

    private let walletContactsManager = WalletContactsManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
        fetchContacts()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        let contactsPublisher = Publishers.CombineLatest($allContacts, $searchText)
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
    }

    private func fetchContacts() {
        do {
            allContacts = try walletContactsManager.fetchAllModels()
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    // MARK: - View Model

    func performAction(contactID: UUID, actionID: UInt) {

        guard let contact = allContacts.first(where: { $0.id == contactID }), let action = MenuAction(rawValue: actionID) else { return }

        switch action {
        case .send:
            performSendAction(contact: contact)
        case .favorite:
            return
        case .link:
            return
        case .unlink:
            return
        case .details:
            return
        }
    }

    // MARK: - Handlers

    private func performSendAction(contact: ContactViewModel) {
        do {
            let address = try TariAddress(emojiID: contact.emojiID)
            recipientPaymentInfo = PaymentInfo(address: address, yatID: nil)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }
}

final class WalletContactsManager {

    func fetchAllModels() throws -> [ContactViewModel] {

        var models: [ContactViewModel] = []

        models += try fetchWalletContacts().map {
            let emojis = try $0.address.emojis
            return try ContactViewModel(id: UUID(), name: $0.alias, avatar: emojis.firstOrEmpty, emojiID: emojis, isFavorite: true)
        }

        models += try fetchTariAddresses().map { ContactViewModel(id: UUID(), name: $0, avatar: $0.firstOrEmpty, emojiID: $0, isFavorite: true) }

        return models
            .reduce(into: [ContactViewModel]()) { collection, model in
                guard collection.first(where: {$0.emojiID == model.emojiID }) == nil else { return }
                collection.append(model)
            }
            .sorted { $0.name < $1.name }
    }

    private func fetchWalletContacts() throws -> [Contact] {
        try Tari.shared.contacts.allContacts
    }

    private func fetchTariAddresses() throws -> [String] {

        var transactions: [Transaction] = []
        transactions += Tari.shared.transactions.pendingInbound
        transactions += Tari.shared.transactions.pendingOutbound
        transactions += Tari.shared.transactions.cancelled
        transactions += Tari.shared.transactions.completed

        return try transactions
            .map { try $0.address.emojis }
    }
}

private extension String {

    var firstOrEmpty: String {
        guard let first else { return "" }
        return String(first)
    }
}

enum MenuAction: UInt {
    case send
    case favorite
    case link
    case unlink
    case details
}

extension MenuAction {

    var buttonViewModel: ContactCapsuleMenu.ButtonViewModel { ContactCapsuleMenu.ButtonViewModel(id: rawValue, icon: icon) }

    private var icon: UIImage? {
        switch self {
        case .send:
            return .icons.send
        case .favorite:
            return .icons.star.filled
        case .link:
            return .icons.link
        case .unlink:
            return .icons.unlink
        case .details:
            return .icons.profile
        }
    }
}
