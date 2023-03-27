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

final class ContactBookViewController: UIViewController {

    // MARK: - Properties

    private let model: ContactBookModel
    private let mainView = ContactBookView()
    private let pagerViewController = TariPagerViewController()

    private let contactsPageViewController = ContactBookContactListViewController()
    private let favoritesPageViewController = ContactBookContactListViewController()

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

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPages()
        setupCallbacks()
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
            image: .contactBook.placeholders.favoritesContactsList,
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

    private func setupCallbacks() {

        model.$contactsList
            .compactMap { [weak self] in self?.map(sections: $0) }
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
            .compactMap { [weak self] in self?.map(sections: $0) }
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

        model.$isPermissionGranted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updatePlaceholders(isPermissionGranted: $0) }
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

        mainView.onCancelShareModelButtonTap = { [weak self] in
            self?.model.contentMode = .normal
        }

        contactsPageViewController.onButtonTap = { [weak self] in
            self?.model.performAction(contactID: $0, menuItemID: $1)
        }

        contactsPageViewController.onRowTap = { [weak self] in
            self?.model.toggle(contactID: $0)
        }

        favoritesPageViewController.onButtonTap = { [weak self] in
            self?.model.performAction(contactID: $0, menuItemID: $1)
        }

        favoritesPageViewController.onRowTap = { [weak self] in
            self?.model.toggle(contactID: $0)
        }

        contactsPageViewController.onFooterTap = { [weak self] in
            self?.openAppSettings()
        }
    }

    // MARK: - Updates

    private func updatePlaceholders(isPermissionGranted: Bool) {

        contactsPageViewController.isFooterVisible = !isPermissionGranted

        guard isPermissionGranted else {

            contactsPageViewController.placeholderViewModel = ContactBookListPlaceholder.ViewModel(
                image: .contactBook.placeholders.contactsList,
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
            image: .contactBook.placeholders.contactsList,
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
        case let .showUnlinkSuccess(emojiID, name):
            showUnlinkSuccessDialog(emojiID: emojiID, name: name)
        case let .showDetails(model):
            moveToContactDetails(model: model)
        }
    }

    private func map(sections: [ContactBookModel.ContactSection]) -> [ContactBookContactListView.Section] {
        sections.map {
            let items = $0.viewModels.map {
                let menuItems = $0.menuItems.map { $0.buttonViewModel }
                return ContactBookCell.ViewModel(id: $0.id, name: $0.name, avatarText: $0.avatar, avatarImage: $0.avatarImage, isFavorite: $0.isFavorite, menuItems: menuItems, contactTypeImage: $0.type.image)
            }
            return ContactBookContactListView.Section(title: $0.title, items: items)
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

    // MARK: - Actions

    private func moveToAddContactScreen() {
        let controller = AddContactConstructor.bulidScene()
        navigationController?.pushViewController(controller, animated: true)
    }

    private func moveToSendTokensScreen(paymentInfo: PaymentInfo) {
        AppRouter.presentSendTransaction(paymentInfo: paymentInfo)
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
        guard let emojiID = model.internalModel?.emojiID.obfuscatedText, let name = model.externalModel?.fullname else { return }
        PopUpPresenter.showUnlinkConfirmationDialog(emojiID: emojiID, name: name, confirmationCallback: { [weak self] in self?.model.unlink(contact: model) })
    }

    private func showUnlinkSuccessDialog(emojiID: String, name: String) {
        PopUpPresenter.showUnlinkSuccessDialog(emojiID: emojiID, name: name)
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private extension ContactBookModel.MenuItem {

    var buttonViewModel: ContactCapsuleMenu.ButtonViewModel { ContactCapsuleMenu.ButtonViewModel(id: rawValue, icon: icon) }

    private var icon: UIImage? {
        switch self {
        case .send:
            return .icons.send
        case .addToFavorites:
            return .icons.star.filled
        case .removeFromFavorites:
            return .icons.star.border
        case .link:
            return .icons.link
        case .unlink:
            return .icons.unlink
        case .details:
            return .icons.profile
        }
    }
}
