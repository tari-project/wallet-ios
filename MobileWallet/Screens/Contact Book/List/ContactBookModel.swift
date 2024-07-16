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

    enum DialogType {
        case bleContactSharingWaitingForReceiverDialog
        case bleContactSharingSuccessDialog
        case bleFailureDialog(message: String?)
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
        case show(dialog: DialogType)
        case showMenu(model: ContactsManager.Model)
    }

    fileprivate enum SectionType: Int {
        case internalContacts
        case externalContacts
    }

    // MARK: - View Model

    @Published var searchText: String = ""
    @Published var contentMode: ContentMode = .normal

    @Published private(set) var contactsList: [ContactBookContactListView.Section] = []
    @Published private(set) var favoriteContactsList: [ContactBookContactListView.Section] = []
    @Published private(set) var selectedIDs: Set<UUID> = []
    @Published private(set) var areContactsAvailable: Bool = false
    @Published private(set) var areFavoriteContactsAvailable: Bool = false
    @Published private(set) var errorModel: MessageModel?
    @Published private(set) var action: Action?
    @Published private(set) var isPermissionGranted: Bool = false
    @Published private(set) var isSharePossible: Bool = false

    // MARK: - Properties

    @Published private var contactModels: [[ContactsManager.Model]] = []

    private let contactsManager = ContactsManager()

    private weak var bleTask: BLECentralTask?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        $contactModels
            .sink { [weak self] in self?.handle(contactModels: $0) }
            .store(in: &cancellables)

        let contactsPublisher = Publishers.CombineLatest($contactModels, $searchText)
            .compactMap { [weak self] in self?.filter(contactsSections: $0, searchText: $1) }
            .compactMap { [weak self] in self?.map(contactsSections: $0) }
            .share()

        contactsPublisher
            .assignPublisher(to: \.contactsList, on: self)
            .store(in: &cancellables)

        contactsPublisher
            .compactMap { $0.map { ContactBookContactListView.Section(title: $0.title, items: $0.items.filter { $0.isFavorite })}}
            .map { $0.filter { !$0.items.isEmpty }}
            .assignPublisher(to: \.favoriteContactsList, on: self)
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
                let tariContactModels = contactsManager.tariContactModels.filter { $0.internalModel?.addressComponents.isUnknownAddress == false }
                contactModels = [tariContactModels, contactsManager.externalModels]
            } catch {
                errorModel = ErrorMessageManager.errorModel(forError: error)
            }

            isPermissionGranted = contactsManager.isPermissionGranted
        }
    }

    func performAction(contactID: UUID, menuItemID: UInt) {

        guard let model = contact(contactID: contactID), let menuItem = MenuItem(rawValue: menuItemID) else { return }

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

    func toggleSelection(contactID: UUID) {

        guard let model = contact(contactID: contactID), model.hasIntrenalModel else { return }

        guard selectedIDs.contains(contactID) else {
            selectedIDs.insert(contactID)
            return
        }

        selectedIDs.remove(contactID)
    }

    func unlink(contact: ContactsManager.Model) {

        guard let emojiID = contact.internalModel?.addressComponents.fullEmoji.obfuscatedText, let name = contact.externalModel?.fullname else { return }

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

    func cancelBLETask() {
        bleTask?.cancel()
    }

    func selectContact(contactID: UUID) {
        guard let model = contact(contactID: contactID) else { return }
        action = .showMenu(model: model)
    }

    // MARK: - Actions

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

        let bleTask = BLECentralTask(service: BLEConstants.contactBookService.uuid, characteristic: BLEConstants.contactBookService.characteristics.contactsShare)
        self.bleTask?.cancel()
        self.bleTask = bleTask

        action = .show(dialog: .bleContactSharingWaitingForReceiverDialog)

        Task {
            do {
                guard try await bleTask.findAndWrite(payload: payload) else { return }
                action = .show(dialog: .bleContactSharingSuccessDialog)
            } catch {
                handle(bleError: error)
            }
        }
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

    // MARK: - Handlers

    private func handle(bleError error: Error) {

        Logger.log(message: "Unable to finish BLE task. Reason: \(error)", domain: .general, level: .error)

        let message: String?

        if let error = error as? BLECentralManager.BLECentralError {
            message = error.errorMessage
        } else {
            message = ErrorMessageManager.errorMessage(forError: error)
        }

        action = .show(dialog: .bleFailureDialog(message: message))
    }

    private func makeDeeplink() throws -> URL? {

        let allModels = contactModels.flatMap { $0 }
        let list = selectedIDs
            .compactMap { selectedID in allModels.first { $0.id == selectedID }}
            .compactMap { $0.internalModel }
            .map { ContactListDeeplink.Contact(alias: $0.alias ?? "", hex: $0.addressComponents.fullRaw ) } // FIXME: Deeplinks doesn't support base58 and TariAddressComponents yet

        let model = ContactListDeeplink(list: list)

        return try DeepLinkFormatter.deeplink(model: model)
    }

    private func filter(contactsSections: [[ContactsManager.Model]], searchText: String) -> [[ContactsManager.Model]] {

        guard !searchText.isEmpty else { return contactsSections }

        return contactsSections.map {
            $0.filter {
                guard $0.name.range(of: searchText, options: .caseInsensitive) == nil else { return true }
                guard let internalModel = $0.internalModel else { return false }
                guard internalModel.addressComponents.fullEmoji.range(of: searchText, options: .caseInsensitive) == nil else { return true }
                return internalModel.addressComponents.fullRaw.range(of: searchText, options: .caseInsensitive) != nil
            }
        }
    }

    private func map(contactsSections: [[ContactsManager.Model]]) -> [ContactBookContactListView.Section] {
        contactsSections
            .enumerated()
            .reduce(into: [ContactBookContactListView.Section]()) { result, data in

                let section = SectionType(rawValue: data.offset)
                guard !data.element.isEmpty else { return }

                let items: [ContactBookCell.ViewModel] = data.element.map {
                    ContactBookCell.ViewModel(
                        id: $0.id,
                        addressViewModel: $0.contactBookCellAddressViewModel,
                        isFavorite: $0.isFavorite,
                        contactTypeImage: $0.type.image,
                        isSelectable: section?.isSelectable ?? false
                    )
                }

                result.append(ContactBookContactListView.Section(title: section?.title, items: items))
            }
    }

    private func handle(contactModels: [[ContactsManager.Model]]) {
        let models = contactModels.flatMap { $0 }
        areContactsAvailable = !models.isEmpty
        areFavoriteContactsAvailable = models.first { $0.isFavorite } != nil
    }

    // MARK: - Helpers

    private func contact(contactID: UUID) -> ContactsManager.Model? {
        contactModels.flatMap { $0 }.first { $0.id == contactID }
    }
}

extension ContactBookModel.ShareType {

    var image: UIImage? {
        switch self {
        case .qr:
            return .Icons.General.QR
        case .link:
            return .Icons.General.link
        case .ble:
            return .Icons.General.bluetooth
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

private extension ContactBookModel.SectionType {

    var title: String? {
        switch self {
        case .internalContacts:
            return nil
        case .externalContacts:
            return localized("contact_book.section.phone_contacts")
        }
    }

    var isSelectable: Bool { self == .internalContacts }
}
