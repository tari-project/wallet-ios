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

final class ProfileViewController: SecureViewController<ProfileView> {

    // MARK: - Properties

    private let model = ProfileModel()
    private weak var qrCodePopUpContentView: PopUpQRContentView?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(backButtonType: NavigationBar.BackButtonType) {
        super.init(nibName: nil, bundle: nil)
        mainView.backButtonType = backButtonType
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        model.updateYatIdData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$name
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.update(username: $0) }
            .store(in: &cancellables)

        model.$addressType
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(addressType: $0) }
            .store(in: &cancellables)

        model.$isYatOutOfSync
            .receive(on: DispatchQueue.main)
            .assign(to: \.isOutOfSyncLabelVisible, on: mainView)
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
            .sink { [weak self] in self?.showYatOnboardingFlow(rawAddress: $0) }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        mainView.yatButton.onTap = { [weak self] in
            self?.model.toggleVisibleData()
        }

        mainView.onEditButtonTap = { [weak self] in
            self?.showEditNameForm()
        }

        mainView.onWalletButtonTap = { [weak self] in
            self?.moveToUTXOsWallet()
        }

        mainView.onConnectYatButtonTap = { [weak self] in
            self?.model.reconnectYat()
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

        guard let addressComponents = model.addressComponents else { return }
        mainView.onViewDetailsButtonTap = AddressViewDefaultActions.showDetailsAction(addressComponents: addressComponents)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.model.updateYatIdData() }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func handle(addressType: ProfileModel.AddressType) {
        switch addressType {
        case let .address(components):
            let viewModel = AddressView.ViewModel(prefix: components.networkAndFeatures, text: .truncated(prefix: components.spendKeyPrefix, suffix: components.spendKeySuffix), isDetailsButtonVisible: true)
            mainView.update(addressViewModel: viewModel, isTariAddress: true)
        case let .yat(yat):
            let viewModel = AddressView.ViewModel(prefix: nil, text: .single(yat), isDetailsButtonVisible: false)
            mainView.update(addressViewModel: viewModel, isTariAddress: false)
        }
    }

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

    private func showYatOnboardingFlow(rawAddress: String) {
        Yat.integration.showOnboarding(onViewController: self, records: [
            YatRecordInput(tag: .XTMAddress, value: rawAddress)
        ])
    }

    private func moveToUTXOsWallet() {
        let controller = UTXOsWalletConstructor.buildScene()
        navigationController?.pushViewController(controller, animated: true)
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
            showBLEDialog(type: .scanForContactListReceiver(onCancel: { [weak self] in self?.model.cancelBLESharing() }))
        case .showBLESuccessDialog:
            showBLEDialog(type: .successContactSharing)
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
        PopUpPresenter.showBLEDialog(type: type)
    }

    private func showLinkShareDialog(link: URL) {
        let controller = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = mainView.navigationBar
        present(controller, animated: true)
    }
}
