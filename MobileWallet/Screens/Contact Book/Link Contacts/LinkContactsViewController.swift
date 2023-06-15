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
import ContactsUI

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.fetchData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$name
            .compactMap { $0 }
            .sink { [weak self] in self?.mainView.name = $0 }
            .store(in: &cancellables)

        model.$models
            .map { $0.map { ContactBookCell.ViewModel(id: $0.id, name: $0.name, avatarText: $0.avatar, avatarImage: $0.avatarImage, isFavorite: false, contactTypeImage: nil, isSelectable: false) }}
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

        model.$placeholder
            .receive(on: DispatchQueue.main)
            .map { [weak self] in self?.mapPlaceholderViewModel(model: $0) }
            .sink { [weak self] in self?.mainView.placeholderViewModel = $0 }
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
        case .moveToAddContact:
            moveToAddContact()
        case .moveToPhoneBook:
            moveToAddExternalContact()
        case .moveToPermissionSettings:
            openAppSettings()
        }
    }

    private func mapPlaceholderViewModel(model: LinkContactsModel.PlaceholderModel?) -> ContactBookListPlaceholder.ViewModel? {

        guard let model else { return nil }

        var titleComponents: [StylizedLabel.StylizedText] = []
        var messageComponents: [StylizedLabel.StylizedText] = []

        if let title = model.title {
            titleComponents = [StylizedLabel.StylizedText(text: title, style: .normal)]
        }

        if let message = model.message {
            messageComponents = [StylizedLabel.StylizedText(text: message, style: .normal)]
        }

        return ContactBookListPlaceholder.ViewModel(
            image: .contactBook.placeholders.linkList,
            titleComponents: titleComponents,
            messageComponents: messageComponents,
            actionButtonTitle: model.buttonTitle,
            actionButtonCallback: { [weak self] in self?.model.performPlaceholderAction() }
        )
    }

    // MARK: - Actions

    private func showConfirmationDialog(emojiID: String, name: String) {

        let model = PopUpDialogModel(
            titleComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.link_contacts.popup.confirmation.title"), style: .normal)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.link_contacts.popup.confirmation.message.part1", arguments: emojiID), style: .normal),
                StylizedLabel.StylizedText(text: name, style: .bold)
            ],
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
            titleComponents: [StylizedLabel.StylizedText(
                text: localized("contact_book.link_contacts.popup.success.title"), style: .normal)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.link_contacts.popup.success.message.part1", arguments: emojiID), style: .normal),
                StylizedLabel.StylizedText(text: name, style: .bold)
            ],
            buttons: [
                PopUpDialogButtonModel(title: localized("common.close"), type: .text)
            ],
            hapticType: .none
        )

        PopUpPresenter.showPopUp(model: model)
        navigationController?.popViewController(animated: true)
    }

    private func moveToAddContact() {
        let controller = AddContactConstructor.bulidScene(onSuccess: .moveBack)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func moveToAddExternalContact() {
        let controller = CNContactViewController(forNewContact: nil)
        controller.delegate = self
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
    }

    private func openAppSettings() {
        AppRouter.openAppSettings()
    }
}

extension LinkContactsViewController: CNContactViewControllerDelegate {

    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true)
    }
}
