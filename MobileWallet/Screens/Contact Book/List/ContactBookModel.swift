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

import UIKit
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
        let avatarImage: UIImage?
        let isFavorite: Bool
        let menuItems: [ContactBookModel.MenuItem]
        let type: ContactsManager.ContactType
        let isSelectable: Bool
    }

    enum MenuItem: UInt {
        case send
        case addToFavorites
        case removeFromFavorites
        case link
        case unlink
        case details
    }

    enum ContentMode {
        case normal
        case shareContacts
    }

    enum ShareType: Int, CaseIterable {
        case qr
        case link
        case ble
    }

    enum Action {
        case sendTokens(paymentInfo: PaymentInfo)
        case link(model: ContactsManager.Model)
        case unlink(model: ContactsManager.Model)
        case showUnlinkSuccess(emojiID: String, name: String)
        case showDetails(model: ContactsManager.Model)
        case showQRDialog
        case shareQR(image: UIImage)
        case shareLink(link: URL)
        case showBLEWaitingForReceiverDialog
        case showBLESuccessDialog
        case showBLEFailureDialog(message: String?)
    }

    // MARK: - View Model

    @Published var searchText: String = ""
    @Published var contentMode: ContentMode = .normal

    @Published private(set) var contactsList: [ContactSection] = []
    @Published private(set) var favoriteContactsList: [ContactSection] = []
    @Published private(set) var selectedIDs: Set<UUID> = []
    @Published private(set) var areContactsAvailable: Bool = false
    @Published private(set) var areFavoriteContactsAvailable: Bool = false
    @Published private(set) var errorModel: MessageModel?
    @Published private(set) var action: Action?
    @Published private(set) var isPermissionGranted: Bool = false
    @Published private(set) var isSharePossible: Bool = false

    // MARK: - Properties

    @Published private var allContactList: [ContactSection] = []

    private let contactsManager = ContactsManager()

    private weak var bleTask: BLECentralTask?
    private var contacts: [ContactsManager.Model] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        $allContactList
            .sink { [weak self] in
                let models = $0.flatMap { $0.viewModels }
                self?.areContactsAvailable = !models.isEmpty
                self?.areFavoriteContactsAvailable = models.first { $0.isFavorite } != nil
            }
            .store(in: &cancellables)

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

        $contentMode
            .filter { $0 == .normal }
            .sink { [weak self] _ in self?.selectedIDs = [] }
            .store(in: &cancellables)

        $selectedIDs
            .map { !$0.isEmpty }
            .assignPublisher(to: \.isSharePossible, on: self)
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

                let internalContactSection = internalContacts
                    .map { ContactViewModel(id: $0.id, name: $0.name, avatar: $0.avatar, avatarImage: $0.avatarImage, isFavorite: $0.isFavorite, menuItems: $0.menuItems, type: $0.type, isSelectable: true) }

                let externalContactSection = externalContacts
                    .map { ContactViewModel(id: $0.id, name: $0.name, avatar: $0.avatar, avatarImage: $0.avatarImage, isFavorite: false, menuItems: $0.menuItems, type: $0.type, isSelectable: false) }

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

            isPermissionGranted = contactsManager.isPermissionGranted
        }
    }

    func performAction(contactID: UUID, menuItemID: UInt) {

        guard let model = contacts.first(where: { $0.id == contactID }), let menuItem = MenuItem(rawValue: menuItemID) else { return }

        switch menuItem {
        case .send:
            performSendAction(model: model)
        case .addToFavorites:
            update(isFavorite: true, contact: model)
        case .removeFromFavorites:
            update(isFavorite: false, contact: model)
        case .link:
            performLinkAction(model: model)
        case .unlink:
            performUnlinkAction(model: model)
        case .details:
            performShowDetailsAction(model: model)
        }
    }

    func toggle(contactID: UUID) {

        guard selectedIDs.contains(contactID) else {
            selectedIDs.insert(contactID)
            return
        }

        selectedIDs.remove(contactID)
    }

    func unlink(contact: ContactsManager.Model) {

        guard let emojiID = contact.internalModel?.emojiID.obfuscatedText, let name = contact.externalModel?.fullname else { return }

        do {
            try contactsManager.unlink(contact: contact)
            fetchContacts()
            action = .showUnlinkSuccess(emojiID: emojiID, name: name)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func shareSelectedContacts(shareType: ShareType) {

        let deeplink: URL

        do {
            guard let link = try makeDeeplink() else { return }
            deeplink = link
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
            return
        }

        switch shareType {
        case .qr:
            shareQR(deeplink: deeplink)
        case .link:
            shareLink(deeplink: deeplink)
        case .ble:
            shareLinkViaBLE(deeplink: deeplink)
        }

        contentMode = .normal
    }

    func cancelBLESharing() {
        bleTask?.cancel()
    }

    private func update(isFavorite: Bool, contact: ContactsManager.Model) {
        do {
            try contactsManager.update(nameComponents: contact.nameComponents, isFavorite: isFavorite, yat: contact.externalModel?.yat ?? "", contact: contact)
            fetchContacts()
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    private func shareQR(deeplink: URL) {

        action = .showQRDialog

        Task {
            guard let data = deeplink.absoluteString.data(using: .utf8), let image = await QRCodeFactory.makeQrCode(data: data) else { return }
            action = .shareQR(image: image)
        }
    }

    private func shareLink(deeplink: URL) {
        action = .shareLink(link: deeplink)
    }

    private func shareLinkViaBLE(deeplink: URL) {

        guard let payload = deeplink.absoluteString.data(using: .utf8) else { return }

        action = .showBLEWaitingForReceiverDialog

        let bleTask = BLECentralTask(service: BLEConstants.contactBookService.uuid, characteristic: BLEConstants.contactBookService.characteristics.contactsShare)
        self.bleTask = bleTask

        Task {
            do {
                guard try await bleTask.findAndWrite(payload: payload) else { return }
                action = .showBLESuccessDialog
            } catch {
                handle(bleWriteError: error)

            }
        }
    }

    private func handle(bleWriteError error: Error) {

        Logger.log(message: "Unable to find and write BLE payload. Reason: \(error)", domain: .general, level: .error)

        let message: String?

        if let error = error as? BLECentralManager.BLECentralError {
            message = error.errorMessage
        } else {
            message = ErrorMessageManager.errorMessage(forError: error)
        }

        action = .showBLEFailureDialog(message: message)
    }

    // MARK: - Handlers

    private func makeDeeplink() throws -> URL? {

        let list = selectedIDs
            .compactMap { selectedID in contacts.first { $0.id == selectedID }}
            .compactMap { $0.internalModel }
            .map { ContactListDeeplink.Contact(alias: $0.alias ?? "", hex: $0.hex ) }

        let model = ContactListDeeplink(list: list)

        return try DeepLinkFormatter.deeplink(model: model)
    }

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

extension ContactBookModel.ShareType {

    var image: UIImage? {
        switch self {
        case .qr:
            return Theme.shared.images.qrButton?.withRenderingMode(.alwaysTemplate)
        case .link:
            return .icons.link
        case .ble:
            return .icons.bluetooth
        }
    }

    var text: String? {
        switch self {
        case .qr:
            return localized("contact_book.share_bar.buttons.qr")
        case .link:
            return localized("contact_book.share_bar.buttons.link")
        case .ble:
            return localized("contact_book.share_bar.buttons.ble")
        }
    }
}

private extension BLECentralManager.BLECentralError {

    var errorMessage: String? {
        switch self {
        case .turnedOff:
            return localized("error.ble.central.turned_off")
        case .unauthorized:
            return localized("error.ble.central.unauthorized")
        case .unsupported:
            return localized("error.ble.central.unsupported")
        case .unknown:
            return localized("error.ble.central.unknown")
        case .connectionError:
            return localized("error.ble.central.connection_error")
        case .processInterrupted:
            return localized("error.ble.central.process_interrupted")
        case .writeFailedCharacteristicNotFound:
            return localized("error.ble.central.write_failed_characteristic_not_found")
        }
    }
}
