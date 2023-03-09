//  LinkContactsViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 07/03/2023
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

final class LinkContactsViewController: UIViewController {

    // MARK: - Properties

    let model: LinkContactsModel
    let mainView = LinkContactsView()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: LinkContactsModel) {
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
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$name
            .compactMap { $0 }
            .sink { [weak self] in self?.mainView.name = $0 }
            .store(in: &cancellables)

        model.$models
            .map { $0.map { ContactBookCell.ViewModel(id: $0.id, name: $0.name, avatar: $0.avatar, isFavorite: false, menuItems: []) }}
            .sink { [weak self] in self?.mainView.viewModels = $0 }
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

        mainView.searchText
            .assign(to: \.searchText, on: model)
            .store(in: &cancellables)

        mainView.onSelectRow = { [weak self] in
            self?.model.selectModel(index: $0)
        }
    }

    // MARK: - Handlers

    private func handle(action: LinkContactsModel.Action) {

        switch action {
        case let .showConfirmation(emojiID, name):
            showConfirmationDialog(emojiID: emojiID, name: name)
        case let .showSuccess(emojiID, name):
            showSuccessDialog(emojiID: emojiID, name: name)
        }
    }

    // MARK: - Actions

    private func showConfirmationDialog(emojiID: String, name: String) {

        let model = PopUpDialogModel(
            title: localized("contact_book.link_contacts.popup.confirmation.title"),
            message: localized("contact_book.link_contacts.popup.confirmation.message", arguments: emojiID, name),
            buttons: [
                PopUpDialogButtonModel(title: localized("common.confirm"), type: .normal, callback: { [weak self] in self?.model.linkContacts() }),
                PopUpDialogButtonModel(title: localized("common.cancel"), type: .text, callback: { [weak self] in self?.model.cancelLinkContacts() })
            ],
            hapticType: .none
        )

        PopUpPresenter.showPopUp(model: model)
    }

    private func showSuccessDialog(emojiID: String, name: String) {

        let model = PopUpDialogModel(
            title: localized("contact_book.link_contacts.popup.success.title"),
            message: localized("contact_book.link_contacts.popup.success.message", arguments: emojiID, name),
            buttons: [
                PopUpDialogButtonModel(title: localized("common.close"), type: .text)
            ],
            hapticType: .none
        )

        PopUpPresenter.showPopUp(model: model)
        navigationController?.popViewController(animated: true)
    }
}
