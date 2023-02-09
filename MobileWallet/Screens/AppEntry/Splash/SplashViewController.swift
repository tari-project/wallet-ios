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

final class SplashViewController: UIViewController {

    // MARK: - Properties

    private let model: SplashViewModel
    private let mainView = SplashView()
    private let authenticationContext = LAContext()

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

    // MARK: - Setups

    private func setupCallbacks() {

        model.$status
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(status: $0) }
            .store(in: &cancellables)

        model.$networkName
            .compactMap { $0 }
            .map { localized("splash.button.select_network", arguments: $0) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.selectNetworkButtonTitle = $0 }
            .store(in: &cancellables)

        model.$appVersion
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.versionText = $0 }
            .store(in: &cancellables)

        model.$isWalletExist
            .map { $0 ? localized("splash.button.open_wallet") : localized("splash.button.create_wallet") }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.createWalletButtonTitle = $0 }
            .store(in: &cancellables)

        model.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)

        mainView.onCreateWalletButtonTap = { [weak self] in
            self?.model.startWallet()
        }

        mainView.onSelectNetworkButtonTap = { [weak self] in
            self?.showNetworkListPopup()
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

    private func moveToNextScreen() {
        switch TariSettings.shared.walletSettings.configurationState {
        case .notConfigured:
            moveToOnboardingScreen(startFromLocalAuth: false)
        case .initialized:
            moveToOnboardingScreen(startFromLocalAuth: true)
        case .authorized, .ready:
            moveToHomeScreen()
        }
    }

    private func moveToRestoreWalletScreen() {
        navigationController?.pushViewController(RestoreWalletViewController(), animated: true)
    }

    private func moveToOnboardingScreen(startFromLocalAuth: Bool) {
        mainView.playLogoAnimation {
            AppRouter.transitionToOnboardingScreen(startFromLocalAuth: startFromLocalAuth)
        }
    }

    private func moveToHomeScreen() {
        authenticationContext.authenticateUser { [weak self] in
            self?.mainView.playLogoAnimation { AppRouter.transitionToHomeScreen() }
        }
    }

    // MARK: - Helpers

    private func handle(status: SplashViewModel.StatusModel) {

        switch (status.status, status.statusRepresentation) {
        case (.idle, .content):
            mainView.isCreateWalletButtonSpinnerVisible = false
            mainView.updateLayout(showInterface: true, animated: animateTransitions)
        case (.idle, .logo):
            mainView.updateLayout(showInterface: false, animated: animateTransitions)
            model.startWallet()
        case (.working, .content):
            mainView.isCreateWalletButtonSpinnerVisible = true
        case (.working, .logo):
            mainView.updateLayout(showInterface: false, animated: animateTransitions)
        case (.success, .content):
            mainView.updateLayout(showInterface: false, animated: animateTransitions) { [weak self] in
                self?.moveToNextScreen()
            }
        case (.success, .logo):
            moveToNextScreen()
        }

        guard !animateTransitions else { return }
        animateTransitions = true
    }
}
