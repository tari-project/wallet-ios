//  ProfileViewController.swift

/*
	Package MobileWallet
	Created by Gabriel Lupu on 04/02/2020
	Using Swift 5.0
	Running on macOS 10.15

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
import YatLib

final class ProfileViewController: UIViewController {

    // MARK: - Properties

    private let mainView = ProfileView()
    private let model = ProfileModel()

    private weak var qrCodePopUpContentView: PopUpQRContentView?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.updateYatIdData()
    }

    // MARK: - Setups

    private func setupBindings() {

        model.$emojiData
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.update(emojiID: $0.emojiID, hex: $0.hex, copyText: $0.copyText, tooltopText: $0.tooltipText) }
            .store(in: &cancellables)

        model.$description
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: mainView.middleLabel)
            .store(in: &cancellables)

        model.$isReconnectButtonVisible
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isHidden, on: mainView.reconnectYatButton)
            .store(in: &cancellables)

        model.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.show(error: $0) }
            .store(in: &cancellables)

        model.$yatButtonState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(yatButtonState: $0) }
            .store(in: &cancellables)

        model.$yatAddress
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showYatOnboardingFlow(publicKey: $0) }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        mainView.yatButton.onTap = { [weak self] in
            self?.model.toggleVisibleData()
        }

        mainView.reconnectYatButton.onTap = { [weak self] in
            self?.model.reconnectYat()
        }

        mainView.onEditButtonTap = { [weak self] in
            self?.showEditNameForm()
        }

        mainView.onQrCodeButtonTap = { [weak self] in
            self?.model.generateQrCode()
        }

        mainView.onLinkButtonTap = { [weak self] in
            self?.model.generateLink()
        }

        mainView.onBleButtonTap = { [weak self] in
            self?.model.shareContactUsingBLE()
        }
    }

    // MARK: - Actions

    private func handle(yatButtonState: ProfileModel.YatButtonState) {
        switch yatButtonState {
        case  .hidden:
            mainView.hideYatButton()
        case .loading:
            mainView.showYatButtonSpinner()
        case .off:
            mainView.isYatButtonOn = false
        case .on:
            mainView.isYatButtonOn = true
        }
    }

    private func show(error: MessageModel) {
        PopUpPresenter.show(message: error)
    }

    private func showYatOnboardingFlow(publicKey: String) {
        Yat.integration.showOnboarding(onViewController: self, records: [
            YatRecordInput(tag: .XTRAddress, value: publicKey)
        ])
    }

    private func handle(action: ProfileModel.Action) {

        switch action {
        case .showQRPopUp:
            showQrCodeDialog()
        case let .shareQR(image):
            showQrCodeInDialog(qrCode: image)
        case let .shareLink(url):
            showLinkShareDialog(link: url)
        case .showBLEWaitingForReceiverDialog:
            showBLEDialog(type: .scan)
        case .showBLESuccessDialog:
            showBLEDialog(type: .success)
        case let .showBLEFailureDialog(message):
            showBLEDialog(type: .failure(message: message))
        }
    }

    private func showEditNameForm() {

        var name = model.name

        let models = [
            ContactBookFormView.TextFieldViewModel(
                placeholder: localized("profile_view.form.text_field.name.placeholder"),
                text: name,
                isEmojiKeyboardVisible: false,
                callback: { name = $0 }
            )
        ]

        FormOverlayPresenter.showForm(title: localized("profile_view.form.title"), textFieldModels: models, presenter: self, onClose: { [weak self] in
            self?.model.name = name
        })
    }

    private func showQrCodeDialog() {
        qrCodePopUpContentView = PopUpPresenter.showQRCodeDialog(title: localized("contact_book.pop_ups.qr.title"))
    }

    private func showQrCodeInDialog(qrCode: UIImage) {
        qrCodePopUpContentView?.qrCode = qrCode
    }

    private func showBLEDialog(type: PopUpPresenter.BLEDialogType) {
        PopUpPresenter.showBLEDialog(type: type) { [weak self] _ in
            self?.model.cancelBLESharing()
        }
    }

    private func showLinkShareDialog(link: URL) {
        let controller = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = mainView.navigationBar
        present(controller, animated: true)
    }
}
