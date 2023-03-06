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
    }

    private func setupCallbacks() {

        model.$contactsList
            .compactMap { [weak self] in self?.map(sections: $0) }
            .sink { [weak self] in self?.contactsPageViewController.models = $0 }
            .store(in: &cancellables)

        model.$favoriteContactsList
            .compactMap { [weak self] in self?.map(sections: $0) }
            .sink { [weak self] in self?.favoritesPageViewController.models = $0 }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        model.$errorModel
            .compactMap { $0 }
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)

        mainView.searchText
            .assign(to: \.searchText, on: model)
            .store(in: &cancellables)

        contactsPageViewController.onButtonTap = { [weak self] in
            self?.model.performAction(contactID: $0, menuItemID: $1)
        }

        favoritesPageViewController.onButtonTap = { [weak self] in
            self?.model.performAction(contactID: $0, menuItemID: $1)
        }
    }

    // MARK: - Handlers

    private func handle(action: ContactBookModel.Action) {
        switch action {
        case let .sendTokens(paymentInfo):
            moveToSendTokensScreen(paymentInfo: paymentInfo)
        case let .showDetails(model):
            moveToContactDetails(model: model)
        }
    }

    private func map(sections: [ContactBookModel.ContactSection]) -> [ContactBookContactListView.Section] {
        sections.map {
            let items = $0.viewModels.map {
                let menuItems = $0.menuItems.map { $0.buttonViewModel }
                return ContactBookContactListView.ViewModel(id: $0.id, name: $0.name, avatar: $0.avatar, isFavorite: $0.isFavorite, menuItems: menuItems)
            }
            return ContactBookContactListView.Section(title: $0.title, items: items)
        }
    }

    // MARK: - Actions

    private func moveToSendTokensScreen(paymentInfo: PaymentInfo) {
        AppRouter.presentSendTransaction(paymentInfo: paymentInfo)
    }

    private func moveToContactDetails(model: ContactsManager.Model) {
        let controller = ContactDetailsConstructor.buildScene(model: model)
        navigationController?.pushViewController(controller, animated: true)
    }
}

private extension ContactBookModel.MenuItem {

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
