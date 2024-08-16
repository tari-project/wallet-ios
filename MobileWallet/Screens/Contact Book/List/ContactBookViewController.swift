//  ContactBookViewController.swift

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

final class ContactBookViewController: SecureViewController<ContactBookView>, OverlayPresentable {

    // MARK: - Properties

    private let model: ContactBookModel
    private let pagerViewController = TariPagerViewController()

    private let contactsPageViewController = ContactBookContactListViewController()
    private let favoritesPageViewController = ContactBookContactListViewController()

    private weak var qrCodePopUpContentView: PopUpQRContentView?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: ContactBookModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPages()
        setupSharingOptions()
        setupCallbacks()
        hideKeyboardWhenTappedAroundOrSwipedDown()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.fetchContacts()
    }

    // MARK: - Setups

    private func setupPages() {

        guard let pagerView = pagerViewController.view else { return }

        mainView.setup(pagerView: pagerView)

        pagerViewController.pages = [
            TariPagerViewController.Page(title: localized("contact_book.pager.tab.contacts"), controller: contactsPageViewController),
            TariPagerViewController.Page(title: localized("contact_book.pager.tab.favorites"), controller: favoritesPageViewController)
        ]

        favoritesPageViewController.placeholderViewModel = ContactBookListPlaceholder.ViewModel(
            image: .Images.ContactBook.Placeholders.favourites,
            titleComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.section.favorites.placeholder.title.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("contact_book.section.favorites.placeholder.title.part2.bold"), style: .bold)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.section.favorites.placeholder.message.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("contact_book.section.favorites.placeholder.message.part2.bold"), style: .bold),
                StylizedLabel.StylizedText(text: localized("contact_book.section.favorites.placeholder.message.part3"), style: .normal)
            ],
            actionButtonTitle: nil,
            actionButtonCallback: nil
        )
    }

    private func setupSharingOptions() {
        let models = ContactBookModel.ShareType.allCases.map { ContactBookShareBar.ViewModel(identifier: $0.rawValue, image: $0.image, text: $0.text) }
        mainView.setupShareBar(models: models)
    }

    private func setupCallbacks() {

        model.$contactsList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.contactsPageViewController.models = $0 }
            .store(in: &cancellables)

        model.$selectedIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.contactsPageViewController.selectedRows = $0
                self?.favoritesPageViewController.selectedRows = $0
            }
            .store(in: &cancellables)

        model.$favoriteContactsList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.favoritesPageViewController.models = $0 }
            .store(in: &cancellables)

        model.$areContactsAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.contactsPageViewController.isPlaceholderVisible = !$0 }
            .store(in: &cancellables)

        model.$areFavoriteContactsAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.favoritesPageViewController.isPlaceholderVisible = !$0 }
            .store(in: &cancellables)

        Publishers.CombineLatest(model.$isPermissionGranted, model.$areContactsAvailable)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updatePlaceholders(isPermissionGranted: $0, areContactsAvailable: $1) }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        model.$errorModel
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)

        model.$contentMode
            .sink { [weak self] in self?.handle(contentMode: $0) }
            .store(in: &cancellables)

        model.$isSharePossible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.isShareButtonEnabled = $0 }
            .store(in: &cancellables)

        mainView.searchText
            .receive(on: DispatchQueue.main)
            .assign(to: \.searchText, on: model)
            .store(in: &cancellables)

        mainView.onShareModeButtonTap = { [weak self] in
            self?.model.contentMode = .shareContacts
        }

        mainView.onAddContactButtonTap = { [weak self] in
            self?.moveToAddContactScreen()
        }

        mainView.onCancelShareModeButtonTap = { [weak self] in
            self?.model.contentMode = .normal
        }

        mainView.onShareButtonTap = { [weak self] in
            guard let identifier = self?.mainView.selectedShareOptionID, let shareType = ContactBookModel.ShareType(rawValue: identifier) else { return }
            self?.model.shareSelectedContacts(shareType: shareType)
        }

        contactsPageViewController.onContactRowTap = { [weak self] contactID, isEditing in
            self?.handleSelectRow(contactID: contactID, isEditing: isEditing)
        }

        favoritesPageViewController.onContactRowTap = { [weak self] contactID, isEditing in
            self?.handleSelectRow(contactID: contactID, isEditing: isEditing)
        }

        contactsPageViewController.onFooterTap = { [weak self] in
            self?.openAppSettings()
        }
    }

    // MARK: - Updates

    private func updatePlaceholders(isPermissionGranted: Bool, areContactsAvailable: Bool) {

        contactsPageViewController.isFooterVisible = !isPermissionGranted && areContactsAvailable

        guard isPermissionGranted else {

            contactsPageViewController.placeholderViewModel = ContactBookListPlaceholder.ViewModel(
                image: .Images.ContactBook.Placeholders.list,
                titleComponents: [
                    StylizedLabel.StylizedText(text: localized("contact_book.section.list.placeholder.title.part1"), style: .normal),
                    StylizedLabel.StylizedText(text: localized("contact_book.section.list.placeholder.title.part2.bold"), style: .bold)
                ],
                messageComponents: [
                    StylizedLabel.StylizedText(text: localized("contact_book.section.list.placeholder.without_permission.message.part1"), style: .normal),
                    StylizedLabel.StylizedText(text: localized("contact_book.section.list.placeholder.without_permission.message.part2.bold"), style: .bold),
                    StylizedLabel.StylizedText(text: localized("contact_book.section.list.placeholder.without_permission.message.part3"), style: .normal)
                ],
                actionButtonTitle: localized("contact_book.section.list.placeholder.button"),
                actionButtonCallback: { [weak self] in self?.openAppSettings() }
            )

            return
        }

        contactsPageViewController.placeholderViewModel = ContactBookListPlaceholder.ViewModel(
            image: .Images.ContactBook.Placeholders.list,
            titleComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.section.list.placeholder.title.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("contact_book.section.list.placeholder.title.part2.bold"), style: .bold)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.section.list.placeholder.message.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("contact_book.section.list.placeholder.message.part2.bold"), style: .bold),
                StylizedLabel.StylizedText(text: localized("contact_book.section.list.placeholder.message.part3"), style: .normal)
            ],
            actionButtonTitle: nil,
            actionButtonCallback: nil
        )
    }

    // MARK: - Handlers

    private func handle(action: ContactBookModel.Action) {
        switch action {
        case let .sendTokens(paymentInfo):
            moveToSendTokensScreen(paymentInfo: paymentInfo)
        case let .link(model):
            moveToLinkContactsScreen(model: model)
        case let .unlink(model: model):
            showUnlinkConfirmationDialog(model: model)
        case let .showUnlinkSuccess(address, name):
            showUnlinkSuccessDialog(address: address, name: name)
        case let .showDetails(model):
            moveToContactDetails(model: model)
        case .showQRDialog:
            showQrCodeDialog()
        case let .shareQR(image):
            showQrCodeInDialog(qrCode: image)
        case let .shareLink(link):
            showLinkShareDialog(link: link)
        case let .show(dialog):
            handle(dialog: dialog)
        case let .showMenu(model):
            showMenu(model: model)
        }
    }

    private func handle(contentMode: ContactBookModel.ContentMode) {
        switch contentMode {
        case .normal:
            mainView.isInSelectionMode = false
            contactsPageViewController.isInSharingMode = false
            favoritesPageViewController.isInSharingMode = false
        case .shareContacts:
            mainView.isInSelectionMode = true
            contactsPageViewController.isInSharingMode = true
            favoritesPageViewController.isInSharingMode = true
        }
    }

    private func handle(dialog: ContactBookModel.DialogType) {
        switch dialog {
        case .bleContactSharingWaitingForReceiverDialog:
            showBLEDialog(type: .scanForContactListReceiver(onCancel: { [weak self] in self?.model.cancelBLETask() }))
        case .bleContactSharingSuccessDialog:
            showBLEDialog(type: .successContactSharing)
        case let .bleFailureDialog(message):
            showBLEDialog(type: .failure(message: message))
        }
    }

    private func handleSelectRow(contactID: UUID, isEditing: Bool) {
        guard isEditing else {
            model.selectContact(contactID: contactID)
            return
        }
        model.toggleSelection(contactID: contactID)
    }

    // MARK: - Actions

    private func moveToAddContactScreen() {
        let controller = AddContactConstructor.bulidScene(onSuccess: .moveToDetails)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func moveToSendTokensScreen(paymentInfo: PaymentInfo) {
        Task { @MainActor in
            AppRouter.presentSendTransaction(paymentInfo: paymentInfo)
        }
    }

    private func moveToLinkContactsScreen(model: ContactsManager.Model) {
        let controller = LinkContactsConstructor.buildScene(contactModel: model)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func moveToContactDetails(model: ContactsManager.Model) {
        let controller = ContactDetailsConstructor.buildScene(model: model)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func showUnlinkConfirmationDialog(model: ContactsManager.Model) {
        guard let address = model.internalModel?.addressComponents.formattedShortAddress, let name = model.externalModel?.fullname else { return }
        PopUpPresenter.showUnlinkConfirmationDialog(address: address, name: name, confirmationCallback: { [weak self] in self?.model.unlink(contact: model) })
    }

    private func showUnlinkSuccessDialog(address: String, name: String) {
        PopUpPresenter.showUnlinkSuccessDialog(address: address, name: name)
    }

    private func openAppSettings() {
        AppRouter.openAppSettings()
    }

    private func showQrCodeDialog() {
        qrCodePopUpContentView = PopUpPresenter.showQRCodeDialog(title: localized("contact_book.pop_ups.qr.title"))
    }

    private func showQrCodeInDialog(qrCode: UIImage) {
        qrCodePopUpContentView?.qrCode = qrCode
    }

    private func showLinkShareDialog(link: URL) {
        let controller = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = mainView.navigationBar
        present(controller, animated: true)
    }

    private func showBLEDialog(type: PopUpPresenter.BLEDialogType) {
        PopUpPresenter.showBLEDialog(type: type)
    }

    private func showMenu(model: ContactsManager.Model) {

        let overlay = RotaryMenuOverlay(model: model)

        overlay.onMenuButtonTap = { [weak self] contactID, menuItemID in
            self?.dismiss(animated: true) {
                self?.model.performAction(contactID: contactID, menuItemID: menuItemID)
            }
        }

        show(overlay: overlay)
    }
}
