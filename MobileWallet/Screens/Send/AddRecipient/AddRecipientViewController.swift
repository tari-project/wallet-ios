//  AddRecipientViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 21/07/2023
	Using Swift 5.0
	Running on macOS 13.4

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

final class AddRecipientViewController: SecureViewController<AddRecipientView> {

    // MARK: - Properties

    var onContactSelected: ((PaymentInfo) -> Void)?

    private let model = AddRecipientModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAroundOrSwipedDown()
        setupViews()
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$listSections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.viewModels = $0 }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        model.$canMoveToNextStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.nextScreen(shouldContinue: $0) }
            .store(in: &cancellables)

        model.$isYatFound
            .receive(on: DispatchQueue.main)
            .assign(to: \.isYatLogoVisible, on: mainView)
            .store(in: &cancellables)

        model.$isAddressPreviewAvaiable
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPreviewButtonVisible, on: mainView)
            .store(in: &cancellables)

        model.$walletAddressPreview
            .receive(on: DispatchQueue.main)
            .assign(to: \.previewText, on: mainView.searchView)
            .store(in: &cancellables)

        model.$errorMessage
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.errorMessage = $0 }
            .store(in: &cancellables)

        mainView.onQrCodeScannerButtonTap = { [weak self] in
            self?.openScanner()
        }

        mainView.onYatPreviewButtonTap = { [weak self] in
            self?.model.toogleYatPreview()
        }

        mainView.onBluetoothRowTap = { [weak self] in
            self?.model.fetchTransactionDataViaBLE()
        }

        mainView.onRowTap = { [weak self] in
            self?.model.select(elementID: $0)
        }

        mainView.searchView.textField.bind(withSubject: model.searchText, storeIn: &cancellables)
    }

    func setupViews() {
        mainView.navigationBar.title = "Send"
    }
    // MARK: - Handlers

    private func nextScreen(shouldContinue: Bool) {
        if shouldContinue {
            self.model.requestContinue()
        }
    }

    private func handle(action: AddRecipientModel.Action) {
        switch action {
        case let .sendTokens(paymentInfo):
            AppRouter.presentSendTransaction(paymentInfo: paymentInfo, presenter: self.navigationController)
            onContactSelected?(paymentInfo)
        case let .show(dialog):
            handle(dialog: dialog)
        }
    }

    private func handle(dialog: AddRecipientModel.DialogType) {
        switch dialog {
        case .bleTransactionWaitingForReceiverDialog:
            showBLEDialog(type: .scanForTransactionData(onCancel: { [weak self] in self?.model.cancelBLETask() }))
        case let .bleTransactionConfirmationDialog(receiverName):
            showBLEDialog(type: .confirmTransactionData(
                receiverName: receiverName,
                onConfirmation: { [weak self] in self?.model.confirmIncomingTransaction() },
                onReject: { [weak self] in self?.model.cancelIncomingTransaction() }
            ))
        case let .bleFailureDialog(message):
            showBLEDialog(type: .failure(message: message))
        }
    }

    // MARK: - Actions

    private func openScanner() {
        AppRouter.presentQrCodeScanner(expectedDataTypes: [.deeplink(.transactionSend), .deeplink(.profile)], disabledDataTypes: []) { [weak self] in
            self?.model.handle(qrCodeData: $0)
        }
    }

    private func showBLEDialog(type: PopUpPresenter.BLEDialogType) {
        PopUpPresenter.showBLEDialog(type: type)
    }
}
