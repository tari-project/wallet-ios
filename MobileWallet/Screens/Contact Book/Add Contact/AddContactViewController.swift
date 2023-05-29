//  AddContactViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 15/03/2023
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

final class AddContactViewController: UIViewController {

    enum NavigationActionType {
        case moveToDetails
        case moveBack
    }

    // MARK: - Properties

    private let model: AddContactModel
    private let mainView = AddContactView()

    private let navigationActionType: NavigationActionType
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: AddContactModel, navigationActionType: NavigationActionType) {
        self.model = model
        self.navigationActionType = navigationActionType
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

        model.$errorText
            .sink { [weak self] in self?.mainView.errorText = $0 }
            .store(in: &cancellables)

        model.$isDataValid
            .sink { [weak self] in self?.mainView.isDoneButtonEnabled = $0 }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        model.$errorMessage
            .compactMap { $0 }
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)

        mainView.searchView.textField.bind(withSubject: model.searchTextSubject, storeIn: &cancellables)

        mainView.contactName
            .assignPublisher(to: \.contactName, on: model)
            .store(in: &cancellables)

        mainView.onSearchTextFieldFocusState = { [weak self] in
            self?.model.isSearchTextFormatted = !$0
        }

        mainView.onQRCodeButtonTap = { [weak self] in
            self?.showQRScanner()
        }

        mainView.onDoneButtonTap = { [weak self] in
            self?.model.createContact()
        }
    }

    // MARK: - Handlers

    private func handle(action: AddContactModel.Action) {
        switch action {
        case let .showDetails(model):
            navigateToNextScreen(model: model)
        case .popBack:
            navigationController?.popViewController(animated: true)
        }
    }

    private func showQRScanner() {
        let scanViewController = ScanViewController(scanResourceType: .publicKey)
        scanViewController.actionDelegate = self
        scanViewController.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .automatic :.popover
        present(scanViewController, animated: true, completion: nil)
    }

    // MARK: - Navigation

    private func navigateToNextScreen(model: ContactsManager.Model) {
        switch navigationActionType {
        case .moveToDetails:
            moveToContactDetails(model: model)
        case .moveBack:
            moveBack()
        }
    }

    private func moveToContactDetails(model: ContactsManager.Model) {
        let controller = ContactDetailsConstructor.buildScene(model: model)
        navigationController?.pushViewController(controller, animated: true)
        navigationController?.remove(controller: self)
    }

    private func moveBack() {
        navigationController?.popViewController(animated: true)
    }
}

extension AddContactViewController: ScanViewControllerDelegate {

    func onScan(deeplink: TransactionsSendDeeplink) {
        model.handle(deeplink: deeplink)
    }

    func onScan(deeplink: ContactListDeeplink) {
        model.handle(deeplink: deeplink)
    }
}
