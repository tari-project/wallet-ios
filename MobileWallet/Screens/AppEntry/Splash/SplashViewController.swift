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
    private var continueButtonVisible = false
    private var continueButton: StylisedButton?

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
            showAuthenticationWithContinueOption(state: state)
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

    private func showAuthenticationWithContinueOption(state: AppRouter.WalletState) {
        // Skip auth on simulator, quicker for development
        guard !AppValues.general.isSimulator else {
            successAuth()
            return
        }

        // Make sure views are visible
        view.isHidden = false
        mainView.isHidden = false

        // Use the new authentication method with explicit failure handling
        localAuth.authenticateUserWithFailureHandling(
            onSuccess: { [weak self] in
                self?.successAuth()
            },
            onFailure: { [weak self] in
                // Handle the cancellation/failure by showing continue button
                DispatchQueue.main.async {
                    self?.showContinueButton(state: state)
                }
            }
        )
    }

    private func showContinueButton(state: AppRouter.WalletState) {
        guard !continueButtonVisible else { return }
        continueButtonVisible = true

        // Ensure the view is visible
        view.isHidden = false
        mainView.isHidden = false

        // Hide wallet creation and restore buttons and the label container
        mainView.importWallet.isHidden = true
        mainView.createWallet.isHidden = true
        mainView.importWalletLabelContainer.isHidden = true

        // Create and add Continue button
        let button = StylisedButton(withStyle: .primary, withSize: .large)
        button.setTitle(localized("common.continue"), for: .normal)
        button.onTap = { [weak self] in
            // Instead of moving directly to home screen, trigger authentication again
            self?.showAuthenticationAgain(state: state)
        }

        continueButton = button
        mainView.addSubview(button)

        // Log that we're adding the button
        Logger.log(message: "Adding Continue button after authentication cancellation", domain: .general, level: .info)

        // Position the button at the same position as the importWallet (Restore Wallet) button
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: mainView.importWallet.centerYAnchor),
            button.widthAnchor.constraint(equalTo: mainView.importWallet.widthAnchor),
            button.heightAnchor.constraint(equalTo: mainView.importWallet.heightAnchor)
        ])
    }

    private func showAuthenticationAgain(state: AppRouter.WalletState) {
        // Show authentication again when Continue button is tapped
        localAuth.authenticateUserWithFailureHandling(
            onSuccess: { [weak self] in
                // If authentication succeeds, proceed to home screen
                self?.successAuth()
            },
            onFailure: {
                // If authentication fails/cancels again, do nothing (keep the Continue button visible)
                Logger.log(message: "Authentication cancelled again from Continue button", domain: .general, level: .info)
            }
        )
    }

    private func moveToHomeScreen(startFromLocalAuth: Bool, state: AppRouter.WalletState) {
        // Remove the continue button if it exists
        continueButton?.removeFromSuperview()
        continueButton = nil
        continueButtonVisible = false

        // Restore visibility of wallet buttons
        mainView.importWallet.isHidden = false
        mainView.createWallet.isHidden = false
        mainView.importWalletLabelContainer.isHidden = false

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
            // Always transition to onboarding for recovered wallets
            AppRouter.transitionToOnboardingScreen(startFromLocalAuth: false)
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
                // Check if wallet DB actually exists - if not, always show creation screens
                if !Tari.shared.wallet(.main).isWalletDBExist {
                    AppRouter.transitionToOnboardingScreen(startFromLocalAuth: false)
                } else {
                    // Only transition to onboarding screens for new wallets or when wallet is not fully configured
                    let configState = TariSettings.shared.walletSettings.configurationState
                    if configState == .notConfigured {
                        AppRouter.transitionToOnboardingScreen(startFromLocalAuth: false)
                    } else {
                        // For existing wallets just go directly to the home screen
                        moveToNextScreen(state: .current)
                    }
                }
            case .successRestored:
                // Always transition to onboarding screens for restored wallets
                AppRouter.transitionToOnboardingScreen(startFromLocalAuth: false)
            case .successSync:
                moveToNextScreen(state: .newSynced)
            case .idle, .working:
            break
        }

        guard !animateTransitions else { return }
        animateTransitions = true
    }
}
