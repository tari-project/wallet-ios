//  ContactDetailsModel.swift

/*
	Package MobileWallet
	Created by Browncoat on 23/02/2023
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

final class ContactDetailsModel {

    enum MenuItem: UInt {
        case send
        case addToFavorites
        case removeContact
    }

    enum Action {
        case sendTokens(paymentInfo: PaymentInfo)
        case removeContactConfirmation
        case endFlow
    }

    struct ViewModel {
        let avatar: String
        let emojiID: String
        let hex: String
    }

    // MARK: - View Model

    @Published private(set) var viewModel: ViewModel?
    @Published private(set) var name: String?
    @Published private(set) var mainMenuItems: [MenuItem] = []
    @Published private(set) var action: Action?
    @Published private(set) var errorModel: MessageModel?

    // MARK: - Properties

    @Published private var contact: Contact?

    private let hex: String
    private var cancellables = Set<AnyCancellable>()

    init(hex: String) {
        self.hex = hex
        setupCallbacks()
        updateData()
    }

    // MARK: - View Model

    func perform(actionID: UInt) {

        guard let menuItem = MenuItem(rawValue: actionID) else { return }

        switch menuItem {
        case .send:
            performSendAction()
        case .addToFavorites:
            return
        case .removeContact:
            action = .removeContactConfirmation
        }
    }

    // MARK: - Setups

    private func setupCallbacks() {
        $contact
            .sink { [weak self] in self?.handle(contact: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func update(name: String?) {

        guard let name else { return }

        let address: TariAddress

        do {

            if let contact {
                address = try contact.address
            } else {
                address = try TariAddress(hex: hex)
            }

            let updatedContact = try Contact(alias: name, addressPointer: address.pointer)

            try Tari.shared.contacts.upsert(contact: updatedContact)
            contact = updatedContact
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func removeContact() {
        do {
            guard let contact else { return }
            try Tari.shared.contacts.remove(contact: contact)
            action = .endFlow
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    private func updateData() {
        do {
            let address = try TariAddress(hex: hex)

            contact = try Tari.shared.contacts.findContact(hex: hex)

            viewModel = ViewModel(
                avatar: try address.emojis.firstOrEmpty,
                emojiID: try address.emojis,
                hex: hex
            )

        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    private func performSendAction() {
        do {
            let address = try TariAddress(hex: hex)
            let paymentInfo = PaymentInfo(address: address, yatID: nil)
            action = .sendTokens(paymentInfo: paymentInfo)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    // MARK: - Handlers

    private func handle(contact: Contact?) {

        name = try? contact?.alias

        var mainMenuItems: [MenuItem] = [.send, .addToFavorites]

        if contact != nil {
            mainMenuItems.append(.removeContact)
        }

        self.mainMenuItems = mainMenuItems
    }
}
