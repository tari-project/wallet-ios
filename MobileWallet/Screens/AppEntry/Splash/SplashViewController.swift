//  SplashViewController.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/05
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
import LocalAuthentication
import Combine

final class SplashViewController: UIViewController, OverlayPresentable {

    // MARK: - Properties

    private let localAuth = LAContext()
    private let model: SplashViewModel
    private let mainView = SplashView()

    private var cancellables = Set<AnyCancellable>()
    private var animateTransitions = false

    // MARK: - Initialisers

    init(model: SplashViewModel) {
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
        if !model.recoverWalletIfNeeded() {
            view.isHidden = true
            if !model.openWalletIfExists() {
                view.isHidden = false
            }
        }
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$status
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(statusModel: $0) }
            .store(in: &cancellables)

        model.$networkName
            .compactMap { $0 }
            .map { localized("splash.button.create_wallet", arguments: $0) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.createWalletButtonTitle = $0 }
            .store(in: &cancellables)

        model.$appVersion
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.versionText = $0 }
            .store(in: &cancellables)

        model.$isWalletExist
            .map { $0 ? localized("splash.button.import_wallet") : localized("splash.button.import_wallet") }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.importWalletButtonTitle = $0 }
            .store(in: &cancellables)

        model.$isRecoveryInProgress
            .filter { $0 }
            .sink { [weak self] _ in self?.showRecoveryProgress() }
            .store(in: &cancellables)

        model.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)

        mainView.onCreateWalletButtonTap = { [weak self] in
            self?.model.createWallet()
        }

        mainView.onRestoreWalletButtonTap = { [weak self] in
            self?.moveToRestoreWalletScreen()
        }
    }

    private func showNetworkListPopup() {

        let headerSection = PopUpHeaderWithSubtitle()

        headerSection.titleLabel.text = localized("splash.action_sheet.select_network.title")
        headerSection.subtitleLabel.text = localized("splash.action_sheet.select_network.description")

        var buttonsModels = model.allNetworkNames
            .enumerated()
            .map { [weak self] index, networkName in
                PopUpDialogButtonModel(title: networkName, type: .normal, callback: { self?.model.selectNetwork(onIndex: index) })
            }

        buttonsModels.append(PopUpDialogButtonModel(title: localized("common.cancel"), type: .text))

        let buttonsSection = PopUpComponentsFactory.makeButtonsView(models: buttonsModels)

        let popUp = TariPopUp(headerSection: headerSection, contentSection: nil, buttonsSection: buttonsSection)

        PopUpPresenter.show(popUp: popUp)
    }

    // MARK: - Actions

    private func moveToNextScreen(state: AppRouter.WalletState) {
        switch TariSettings.shared.walletSettings.configurationState {
        case .notConfigured:
            moveToHomeScreen(startFromLocalAuth: false, state: state)
        case .initialized:
            moveToHomeScreen(startFromLocalAuth: true, state: state)
        case .authorized, .ready:
            moveToHomeScreen(startFromLocalAuth: false, state: state)
        }
    }

    private func moveToRestoreWalletScreen() {
        navigationController?.pushViewController(RestoreWalletViewController(), animated: true)
    }

    private func successAuth() {
        TariSettings.shared.walletSettings.configurationState = .authorized
        AppRouter.transitionToHomeScreen(state: .current)
    }

    private func moveToHomeScreen(startFromLocalAuth: Bool, state: AppRouter.WalletState) {
        if startFromLocalAuth {
            localAuth.authenticateUser(onSuccess: successAuth)
        } else {
            TariSettings.shared.walletSettings.configurationState = .authorized
            AppRouter.transitionToHomeScreen(state: state)
        }
    }

    private func showRecoveryProgress() {
        let overlay = SeedWordsRecoveryProgressViewController()

        overlay.onSuccess = {
            self.localAuth.authenticateUser(onSuccess: self.successAuth)
        }

        overlay.onFailure = { [weak self] in
            self?.model.deleteWallet()
        }

        show(overlay: overlay)
    }

    // MARK: - Helpers

    private func handle(statusModel: SplashViewModel.StatusModel) {
        if #available(iOS 16.0, *) {
            handle(status: statusModel)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.handle(status: statusModel)
            }
        }
    }

    private func handle(status: SplashViewModel.StatusModel) {
        switch status.status {
            case .success:
                moveToNextScreen(state: .current)
            case .successRestored:
                moveToNextScreen(state: .newRestored)
            case .successSync:
                moveToNextScreen(state: .newSynced)
            case .idle, .working:
            break
        }

        guard !animateTransitions else { return }
        animateTransitions = true
    }
}
