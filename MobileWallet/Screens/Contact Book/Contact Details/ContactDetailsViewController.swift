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

    private var needUpdate = false
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$editButtonName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.navigationBar.rightButton.setTitle($0, for: .normal) }
            .store(in: &cancellables)

        model.$name
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.name = $0 }
            .store(in: &cancellables)

        model.$viewModel
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in

                if let avatarImage = $0.avatarImage {
                    self?.mainView.avatar = .image(avatarImage)
                } else {
                    self?.mainView.avatar = .text($0.avatarText)
                }

                self?.mainView.emojiModel = EmojiIdView.ViewModel(emojiID: $0.emojiID, hex: $0.hex)
                self?.mainView.updateFooter(image: $0.contactType.image, text: $0.contactType.text)
            }
            .store(in: &cancellables)

        model.$yat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.yat = $0 }
            .store(in: &cancellables)

        model.$menuSections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.mainView.tableViewSections = $0.map { MenuTableView.Section(title: $0.title, items: $0.items.map { $0.viewModel }) }
            }
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
        case let .moveToLinkContactScreen(model):
            moveToLinkContactScreen(model: model)
        case let .showUnlinkConfirmationDialog(emojiID, name):
            showUnlinkConfirmationDialog(emojiID: emojiID, name: name)
        case let .showUnlinkSuccessDialog(emojiID, name):
            showUnlinkSuccessDialog(emojiID: emojiID, name: name)
        case .removeContactConfirmation:
            showRemoveContactConfirmationDialog()
        case .endFlow:
            endFlow()
        }
    }

    // MARK: - Actions

    private func updateData() {
        guard needUpdate else {
            needUpdate = true
            return
        }
        model.updateData()
    }

    private func showEditForm() {

        var nameComponents: [String] = model.nameComponents
        var yat: String = model.yat ?? ""
        let models: [ContactBookFormView.TextFieldViewModel]

        if model.hasSplittedName {
            models = [
                ContactBookFormView.TextFieldViewModel(placeholder: localized("contact_book.details.edit_form.text_field.first_name"), text: nameComponents[0], isEmojiKeyboardVisible: false, callback: { nameComponents[0] = $0 }),
                ContactBookFormView.TextFieldViewModel(placeholder: localized("contact_book.details.edit_form.text_field.last_name"), text: nameComponents[1], isEmojiKeyboardVisible: false, callback: { nameComponents[1] = $0 }),
                ContactBookFormView.TextFieldViewModel(placeholder: localized("contact_book.details.edit_form.text_field.yat"), text: yat, isEmojiKeyboardVisible: true, callback: { yat = $0 })
            ]
        } else {
            models = [
                ContactBookFormView.TextFieldViewModel(placeholder: localized("contact_book.details.edit_form.text_field.name"), text: nameComponents[0], isEmojiKeyboardVisible: false, callback: { nameComponents[0] = $0 })
            ]
        }

        let formView = ContactBookFormView(textFieldsModels: models)
        let overlay = FormOverlay(formView: formView)

        overlay.onClose = { [weak self] in
            self?.model.update(nameComponents: nameComponents, yat: yat)
        }

        present(overlay, animated: true)
    }

    private func moveToSendTokensScreen(paymentInfo: PaymentInfo) {
        AppRouter.presentSendTransaction(paymentInfo: paymentInfo)
    }

    private func moveToLinkContactScreen(model: ContactsManager.Model) {
        let controller = LinkContactsConstructor.buildScene(contactModel: model)
        navigationController?.pushViewController(controller, animated: true)
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

    private func showUnlinkConfirmationDialog(emojiID: String, name: String) {
        PopUpPresenter.showUnlinkConfirmationDialog(emojiID: emojiID, name: name) { [weak self] in
            self?.model.unlinkContact()
        }
    }

    private func showUnlinkSuccessDialog(emojiID: String, name: String) {
        PopUpPresenter.showUnlinkSuccessDialog(emojiID: emojiID, name: name)
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
        case .removeFromFavorites:
            return MenuCell.ViewModel(id: rawValue, title: localized("contact_book.details.menu.option.remove_from_favorites"), isArrowVisible: false, isDestructive: false)
        case .linkContact:
            return MenuCell.ViewModel(id: rawValue, title: localized("contact_book.details.menu.option.link"), isArrowVisible: true, isDestructive: false)
        case .unlinkContact:
            return MenuCell.ViewModel(id: rawValue, title: localized("contact_book.details.menu.option.unlink"), isArrowVisible: true, isDestructive: false)
        case .removeContact:
            return MenuCell.ViewModel(id: rawValue, title: localized("contact_book.details.menu.option.delete"), isArrowVisible: false, isDestructive: true)
        case .btcWallet:
            return MenuCell.ViewModel(id: rawValue, title: localized("contact_book.details.menu.option.bitcoin"), isArrowVisible: true, isDestructive: false)
        case .ethWallet:
            return MenuCell.ViewModel(id: rawValue, title: localized("contact_book.details.menu.option.ethereum"), isArrowVisible: true, isDestructive: false)
        case .xmrWallet:
            return MenuCell.ViewModel(id: rawValue, title: localized("contact_book.details.menu.option.monero"), isArrowVisible: true, isDestructive: false)
        }
    }
}
