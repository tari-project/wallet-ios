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
import YatLib

final class ContactDetailsModel {

    struct MenuSection {
        let title: String?
        let items: [MenuItem]
    }

    enum MenuItem: UInt {
        case send
        case addToFavorites
        case removeFromFavorites
        case linkContact
        case unlinkContact
        case transactionsList
        case removeContact
        case btcWallet
        case ethWallet
        case xmrWallet
    }

    enum Action {
        case sendTokens(paymentInfo: PaymentInfo)
        case moveToLinkContactScreen(model: ContactsManager.Model)
        case showUnlinkConfirmationDialog(emojiID: String, name: String)
        case showUnlinkSuccessDialog(emojiID: String, name: String)
        case moveToTransactionsList(model: ContactsManager.Model)
        case removeContactConfirmation
        case endFlow
    }

    struct ViewModel {
        let avatarText: String?
        let avatarImage: UIImage?
        let addressComponents: TariAddressComponents
        let contactType: ContactsManager.ContactType
    }

    // MARK: - View Model

    @Published private(set) var isContactExist: Bool = false
    @Published private(set) var name: String?
    @Published private(set) var viewModel: ViewModel?
    @Published private(set) var yat: String?
    @Published private(set) var menuSections: [MenuSection] = []
    @Published private(set) var action: Action?
    @Published private(set) var errorModel: MessageModel?
    @Published private(set) var addressComponents: TariAddressComponents?

    var hasSplittedName: Bool { model.hasExternalModel }
    var nameComponents: [String] { model.nameComponents }

    // MARK: - Properties

    @Published private var model: ContactsManager.Model
    @Published private var connectedWallets: [YatRecordTag: String] = [:]
    @Published private var mainMenuItems: [MenuItem] = []
    @Published private var yatMenuItems: [MenuItem] = []

    private let contactsManager = ContactsManager()
    private var cancellables = Set<AnyCancellable>()

    init(model: ContactsManager.Model) {
        self.model = model
        setupCallbacks()
    }

    // MARK: - View Model

    // swiftlint:disable:next cyclomatic_complexity
    func perform(actionID: UInt) {

        guard let menuItem = MenuItem(rawValue: actionID) else { return }

        switch menuItem {
        case .send:
            performSendAction()
        case .linkContact:
            action = .moveToLinkContactScreen(model: model)
        case .unlinkContact:
            prepareForUnkinkAction()
        case .addToFavorites:
            update(isFavorite: true)
        case .removeFromFavorites:
            update(isFavorite: false)
        case .transactionsList:
            action = .moveToTransactionsList(model: model)
        case .removeContact:
            action = .removeContactConfirmation
        case .btcWallet:
            openAddress(type: .BTCAddress)
        case .ethWallet:
            openAddress(type: .ETHAddress)
        case .xmrWallet:
            openAddress(type: .XMRStandardAddress)
        }
    }

    // MARK: - Setups

    private func setupCallbacks() {

        $model
            .sink { [weak self] in self?.handle(model: $0) }
            .store(in: &cancellables)

        $yat
            .sink { [weak self] in self?.fetchYatData(yat: $0) }
            .store(in: &cancellables)

        $connectedWallets
            .compactMap { [weak self] in self?.makeYatMenuItems(connectedWallets: $0) }
            .assignPublisher(to: \.yatMenuItems, on: self)
            .store(in: &cancellables)

        Publishers.CombineLatest($mainMenuItems, $yatMenuItems)
            .compactMap { [weak self] in self?.makeMenuSections(mainMenuItems: $0, yatMenuItems: $1) }
            .assignPublisher(to: \.menuSections, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func updateData() {
        Task {
            do {
                try await contactsManager.fetchModels()
                model = contactsManager.updatedModel(model: model)
            } catch {
                errorModel = ErrorMessageManager.errorModel(forError: error)
            }
        }
    }

    func update(nameComponents: [String], yat: String) {
        update(nameComponents: nameComponents, isFavorite: model.isFavorite, yat: yat)
    }

    func unlinkContact() {

        guard let emojiID = model.internalModel?.addressComponents.fullEmoji.obfuscatedText, let name = model.externalModel?.fullname else { return }

        do {
            try contactsManager.unlink(contact: model)
            action = .showUnlinkSuccessDialog(emojiID: emojiID, name: name)
            updateData()
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func removeContact() {
        do {
            try contactsManager.remove(contact: model)
            action = .endFlow
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    private func update(isFavorite: Bool) {
        update(nameComponents: model.nameComponents, isFavorite: isFavorite, yat: yat ?? "")
    }

    private func update(nameComponents: [String], isFavorite: Bool, yat: String) {
        do {
            try contactsManager.update(nameComponents: nameComponents, isFavorite: isFavorite, yat: yat, contact: model)
            updateData()
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    private func updateData(model: ContactsManager.Model) {

        let avatarImage = model.avatarImage
        let avatarText = avatarImage == nil ? model.avatar : nil

        if let addressComponents = model.internalModel?.addressComponents {
            self.addressComponents = addressComponents
            viewModel = ViewModel(avatarText: avatarText, avatarImage: avatarImage, addressComponents: addressComponents, contactType: model.type)
        }

        var mainMenuItems: [MenuItem] = []

        if model.hasIntrenalModel {
            mainMenuItems.append(.send)
        }

        if model.isFFIContact, let internalModel = model.internalModel {
            mainMenuItems.append(internalModel.isFavorite ? .removeFromFavorites : .addToFavorites)
        }

        if model.type == .linked {
            mainMenuItems.append(.unlinkContact)
        } else {
            mainMenuItems.append(.linkContact)
        }

        if model.hasIntrenalModel {
            mainMenuItems.append(.transactionsList)
        }

        if model.isFFIContact || model.hasExternalModel {
            mainMenuItems.append(.removeContact)
        }

        self.mainMenuItems = mainMenuItems
    }

    private func performSendAction() {
        do {
            guard let paymentInfo = try model.paymentInfo else { return }
            action = .sendTokens(paymentInfo: paymentInfo)
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    private func prepareForUnkinkAction() {
        guard let emojiID = model.internalModel?.addressComponents.fullEmoji.obfuscatedText, let name = model.externalModel?.fullname else { return }
        action = .showUnlinkConfirmationDialog(emojiID: emojiID, name: name)
    }

    private func openAddress(type: YatRecordTag) {

        guard var address = connectedWallets[type] else { return }

        let prefix: String

        switch type {
        case .BTCAddress:
            prefix = "bitcoin:"
        case .ETHAddress:
            prefix = "ethereum:pay-"
            if !address.hasPrefix("0x") {
                address = "0x" + address
            }
        case .XMRStandardAddress:
            prefix = "monero:"
        default:
            return
        }

        guard let url = URL(string: [prefix, address].joined()) else { return }

        UIApplication.shared.open(url) { [weak self] isSuccess in
            guard !isSuccess else { return }
            self?.errorModel = MessageModel(title: localized("common.error"), message: localized("contact_book.details.popup.error.unable_to_open_url", arguments: type.walletName), type: .error)
        }
    }

    // MARK: - Yat

    private func fetchYatData(yat: String?) {

        guard let yat, !yat.isEmpty else {
            connectedWallets.removeAll()
            return
        }

        Yat.api.emojiID.lookupEmojiIDPublisher(emojiId: yat, tags: nil)
            .sink { [weak self] in
                self?.handle(yatCompletion: $0)
            } receiveValue: { [weak self] in
                self?.handle(yatResponse: $0)
            }
            .store(in: &cancellables)
    }

    private func handle(yatResponse: LookupResponse) {

        guard let result = yatResponse.result else { return }

        var connectedWallets = [YatRecordTag: String]()

        connectedWallets[.BTCAddress] = result.first { $0.tag == YatRecordTag.BTCAddress.rawValue }?.data.split(separator: "|").firstString
        connectedWallets[.ETHAddress] = result.first { $0.tag == YatRecordTag.ETHAddress.rawValue }?.data.split(separator: "|").firstString
        connectedWallets[.XMRStandardAddress] = result.first { $0.tag == YatRecordTag.XMRStandardAddress.rawValue }?.data.split(separator: "|").firstString

        self.connectedWallets = connectedWallets
    }

    private func handle(yatCompletion: Subscribers.Completion<APIError>) {
        switch yatCompletion {
        case .failure:
            connectedWallets.removeAll()
            errorModel = MessageModel(title: localized("common.error"), message: localized("contact_book.details.popup.error.invalid_yat_response"), type: .error)
        case .finished:
            break
        }
    }

    // MARK: - Handlers

    private func handle(model: ContactsManager.Model) {

        if model.type == .internalOrEmojiID, !model.isFFIContact {
            isContactExist = false
            name = nil
        } else {
            name = model.name
            isContactExist = true
        }

        yat = model.externalModel?.yat
        updateData(model: model)
    }

    private func makeMenuSections(mainMenuItems: [MenuItem], yatMenuItems: [MenuItem]) -> [MenuSection] {

        var menuSections = [MenuSection(title: nil, items: mainMenuItems)]

        if !yatMenuItems.isEmpty {
            menuSections.append(MenuSection(title: localized("contact_book.details.menu.section.connected_wallets"), items: yatMenuItems))
        }

        return menuSections
    }

    private func makeYatMenuItems(connectedWallets: [YatRecordTag: String]) -> [MenuItem] {

        var menuItems = [MenuItem]()

        if connectedWallets[.BTCAddress] != nil {
            menuItems.append(.btcWallet)
        }

        if connectedWallets[.ETHAddress] != nil {
            menuItems.append(.ethWallet)
        }

        if connectedWallets[.XMRStandardAddress] != nil {
            menuItems.append(.xmrWallet)
        }

        return menuItems
    }
}

private extension YatRecordTag {

    var walletName: String {
        switch self {
        case .BTCAddress:
            return localized("contact_book.details.wallet.bitcoin")
        case .ETHAddress:
            return localized("contact_book.details.wallet.ethereum")
        case .XMRStandardAddress:
            return localized("contact_book.details.wallet.monero")
        default:
            return ""
        }
    }
}
