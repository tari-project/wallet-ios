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

        model.$contacts
            .map {
                let actions: [MenuAction] = [.send, .favorite, .link, .details]
                let menuItems = actions.map { $0.buttonViewModel }
                return $0.map { ContactBookContactListView.ViewModel(id: $0.id, name: $0.name, avatar: $0.avatar, isFavorite: $0.isFavorite, menuItems: menuItems)
            }}
            .sink { [weak self] in self?.contactsPageViewController.models = $0 }
            .store(in: &cancellables)

        model.$favoriteContacts
            .map { $0.map { ContactBookContactListView.ViewModel(id: $0.id, name: $0.name, avatar: $0.avatar, isFavorite: $0.isFavorite, menuItems: []) }}
            .sink { [weak self] in self?.favoritesPageViewController.models = $0 }
            .store(in: &cancellables)

        model.$recipientPaymentInfo
            .compactMap { $0 }
            .sink { [weak self] in self?.moveToSendTokensScreen(paymentInfo: $0) }
            .store(in: &cancellables)

        model.$errorModel
            .compactMap { $0 }
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)

        mainView.searchText
            .assign(to: \.searchText, on: model)
            .store(in: &cancellables)

        contactsPageViewController.onButtonTap = { [weak self] in
            self?.model.performAction(contactID: $0, actionID: $1)
        }

        favoritesPageViewController.onButtonTap = { [weak self] in
            self?.model.performAction(contactID: $0, actionID: $1)
        }
    }

    // MARK: - Actions

    private func moveToSendTokensScreen(paymentInfo: PaymentInfo) {
        let controller = AddAmountViewController(paymentInfo: paymentInfo, deeplink: nil)
        navigationController?.pushViewController(controller, animated: true)
    }
}
