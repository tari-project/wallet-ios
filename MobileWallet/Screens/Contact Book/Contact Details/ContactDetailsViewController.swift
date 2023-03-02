//  ContactDetailsViewController.swift

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

import UIKit
import Combine

final class ContactDetailsViewController: UIViewController {

    // MARK: - Properties

    private let mainView = ContactDetailsView()
    private let model: ContactDetailsModel

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: ContactDetailsModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$viewModel
            .compactMap { $0 }
            .sink { [weak self] in
                self?.mainView.avatar = $0.avatar
                self?.mainView.emojiModel = EmojiIdView.ViewModel(emojiID: $0.emojiID, hex: $0.hex)
            }
            .store(in: &cancellables)

        model.$name
            .sink { [weak self] in self?.mainView.name = $0 }
            .store(in: &cancellables)

        model.$mainMenuItems
            .sink { [weak self] in
                let items = $0.map { $0.viewModel }
                self?.mainView.tableViewSections = [MenuTableView.Section(title: nil, items: items)]
            }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        mainView.onSelectRow = { [weak self] in
            self?.model.perform(actionID: $0)
        }

        mainView.onEditButtonTap = { [weak self] in
            self?.showEditForm()
        }
    }

    // MARK: - Handlers

    private func handle(action: ContactDetailsModel.Action) {
        switch action {
        case let .sendTokens(paymentInfo):
            moveToSendTokensScreen(paymentInfo: paymentInfo)
        case .removeContactConfirmation:
            showRemoveContactConfirmationDialog()
        case .endFlow:
            endFlow()
        }
    }

    // MARK: - Actions

    private func showEditForm() {

        var name: String?

        let models = [
            ContactBookFormView.TextFieldViewModel(placeholder: localized("contact_book.details.edit_form.text_field.name"), text: model.name, callback: { name = $0 })
        ]

        let formView = ContactBookFormView(textFieldsModels: models)
        let overlay = FormOverlay(formView: formView)

        overlay.onClose = { [weak self] in
            self?.model.update(name: name)
        }

        present(overlay, animated: true)
    }

    private func moveToSendTokensScreen(paymentInfo: PaymentInfo) {
        AppRouter.presentSendTransaction(paymentInfo: paymentInfo)
    }

    private func showRemoveContactConfirmationDialog() {

        let model = PopUpDialogModel(
            title: localized("contact_book.details.popup.delete_contact.title"),
            message: localized("contact_book.details.popup.delete_contact.message"),
            buttons: [
                PopUpDialogButtonModel(title: localized("contact_book.details.popup.delete_contact.button.ok"), type: .destructive, callback: { [weak self] in self?.model.removeContact() }),
                PopUpDialogButtonModel(title: localized("common.cancel"), type: .text)
            ],
            hapticType: .none)

        PopUpPresenter.showPopUp(model: model)
    }

    private func endFlow() {
        navigationController?.popViewController(animated: true)
    }
}

private extension ContactDetailsModel.MenuItem {

    var viewModel: MenuCell.ViewModel {
        switch self {
        case .send:
            return MenuCell.ViewModel(id: rawValue, title: localized("contact_book.details.menu.option.send"), isArrowVisible: true, isDestructive: false)
        case .addToFavorites:
            return MenuCell.ViewModel(id: rawValue, title: localized("contact_book.details.menu.option.add_to_favorites"), isArrowVisible: false, isDestructive: false)
        case .removeContact:
            return MenuCell.ViewModel(id: rawValue, title: localized("contact_book.details.menu.option.delete"), isArrowVisible: false, isDestructive: true)
        }
    }
}
