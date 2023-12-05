//  BaseContactViewPageManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 01/12/2023
	Using Swift 5.0
	Running on macOS 14.0

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

final class BaseContactViewPageManager {

    // MARK: - Properties

    @Published var contactsList: [ContactBookContactListView.Section] = []
    @Published var favoriteContactsList: [ContactBookContactListView.Section] = []

    var pagerView: UIView { pagerViewController.view }

    var onContactPageRowTap: ((_ identifier: UUID, _ isEditing: Bool) -> Void)? {
        get { contactsPageViewController.onContactRowTap }
        set { contactsPageViewController.onContactRowTap = newValue }
    }

    var onFavoritesContactPageRowTap: ((_ identifier: UUID, _ isEditing: Bool) -> Void)? {
        get { favoritesPageViewController.onContactRowTap }
        set { favoritesPageViewController.onContactRowTap = newValue }
    }

    private let pagerViewController = TariPagerViewController()
    private let contactsPageViewController = ContactBookContactListViewController()
    private let favoritesPageViewController = ContactBookContactListViewController()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initalisers

    init(contactsPlaceholderModel: ContactBookListPlaceholder.ViewModel, favoritesContactsPlaceholderModel: ContactBookListPlaceholder.ViewModel) {
        setupPages(contactsPlaceholderModel: contactsPlaceholderModel, favoritesContactsPlaceholderModel: favoritesContactsPlaceholderModel)
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupPages(contactsPlaceholderModel: ContactBookListPlaceholder.ViewModel, favoritesContactsPlaceholderModel: ContactBookListPlaceholder.ViewModel) {

        pagerViewController.pages = [
            TariPagerViewController.Page(title: localized("contact_book.pager.tab.contacts"), controller: contactsPageViewController),
            TariPagerViewController.Page(title: localized("contact_book.pager.tab.favorites"), controller: favoritesPageViewController)
        ]

        contactsPageViewController.placeholderViewModel = contactsPlaceholderModel
        favoritesPageViewController.placeholderViewModel = favoritesContactsPlaceholderModel
    }

    private func setupCallbacks() {

        $contactsList
            .sink { [weak self] in self?.contactsPageViewController.models = $0 }
            .store(in: &cancellables)

        $favoriteContactsList
            .sink { [weak self] in self?.favoritesPageViewController.models = $0 }
            .store(in: &cancellables)

        $contactsList
            .map(\.isEmpty)
            .sink { [weak self] in self?.contactsPageViewController.isPlaceholderVisible = $0 }
            .store(in: &cancellables)

        $favoriteContactsList
            .map(\.isEmpty)
            .sink { [weak self] in self?.favoritesPageViewController.isPlaceholderVisible = $0 }
            .store(in: &cancellables)
    }
}
