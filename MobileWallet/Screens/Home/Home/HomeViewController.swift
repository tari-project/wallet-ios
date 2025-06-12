//  HomeViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 22/06/2023
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

final class HomeViewController: SecureViewController<HomeView> {

    // MARK: - Properties

    private let model: HomeModel
    private var cancellables = Set<AnyCancellable>()

    var showWalletRestoredOnPresentation = false
    var showWalletSyncedOnPresentation = false

    var didShowOverlays = false
    // MARK: - Initialisers

    init(model: HomeModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        model.runManagers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.updateData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mainView.startAnimations()
        model.executeQueuedShortcut()
        model.fetchMiningStatus()

        showOverlay()
    }

    private func showOverlay() {
        if didShowOverlays == true {
            return
        }

        // Add an extra safeguard - ONLY show welcome overlays if the flag is explicitly set
        let shouldShowWelcome = UserDefaults.standard.bool(forKey: "ShouldShowWelcomeOverlay")
        if !shouldShowWelcome && !showWalletRestoredOnPresentation && !showWalletSyncedOnPresentation {
            return
        }

        didShowOverlays = true
        if showWalletRestoredOnPresentation {
            showWalletRestoredOnPresentation = false
            showOverlay(for: .restored)
            // Set flag to false after showing the overlay
            UserDefaults.standard.set(false, forKey: "ShouldShowWelcomeOverlay")
        } else if showWalletSyncedOnPresentation {
            showWalletSyncedOnPresentation = false
            showOverlay(for: .synced)
            // Set flag to false after showing the overlay
            UserDefaults.standard.set(false, forKey: "ShouldShowWelcomeOverlay")
        } else {
            NotificationManager.shared.shouldPromptForNotifications { shouldPrompt in
                DispatchQueue.main.async {
                    if shouldPrompt {
                        self.showOverlay(for: .notifications)
                    } else {
                        NotificationManager.shared.registerWithAPNS()
                    }
                }
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mainView.stopAnimations()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
                mainView.update(theme: ThemeCoordinator.shared.theme)
            }
        }
    }

    // MARK: - Setups

    private func setupCallbacks() {
        setupModelCallbacks()

        mainView.onConnetionStatusButtonTap = { [weak self] in
            self?.showConectionStatusPopUp()
        }

        mainView.onQRCodeScannerButtonTap = { [weak self] in
            self?.showQRCodeScanner()
        }

        mainView.onAvatarButtonTap = {
            AppRouter.moveToProfile()
        }

        mainView.onAmountHelpButtonTap = { [weak self] in
            self?.showAmountHelpPopUp()
        }

        mainView.onTransactionCellTap = { [weak self] in
            self?.model.select(transactionID: $0)
        }

        mainView.onSendButtonTap = { [weak self] in
            let controller = AddRecipientConstructor.buildScene()
            let navigationController = AlwaysPoppableNavigationController(rootViewController: controller)
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.modalPresentationStyle = .fullScreen
            self?.present(navigationController, animated: true)
        }

        mainView.onReceiveButtonTap = { [weak self] in
            let controller = ReceiveConstructor.buildScene()
            let navigationController = AlwaysPoppableNavigationController(rootViewController: controller)
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.modalPresentationStyle = .fullScreen
            self?.present(navigationController, animated: true)
        }

        mainView.onStartMiningTap = { [weak self] in
            self?.showOverlay(for: .startMining)
        }

        mainView.onDisclaimerButtonTap = { [weak self] in
            UserDefaults.standard.set(true, forKey: "ShouldShowDisclaimerOverlay")
            self?.showOverlay(for: .disclaimer)
        }
    }

    private func setupModelCallbacks() {
        model.$connectionStatusIcon
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.connectionStatusIcon = $0 }
            .store(in: &cancellables)

        mainView.isSyncInProgress = false
        // model.$isSyncInProgress
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] in self?.mainView.isSyncInProgress = $0 }
        //     .store(in: &cancellables)

        model.$totalBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.balance = $0 }
            .store(in: &cancellables)

        model.$activeMiners
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.activeMiners = $0 }
            .store(in: &cancellables)

        model.$availableBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.availableBalance = $0 }
            .store(in: &cancellables)

        model.$username
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.username = $0 }
            .store(in: &cancellables)

        model.$isMiningActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.activeMinersView.setMiningActive($0) }
            .store(in: &cancellables)

        model.$recentTransactions
            .receive(on: DispatchQueue.main)
            .map { $0.map { HomeViewTransactionCell.ViewModel(id: $0.id, titleComponents: $0.titleComponents, timestamp: $0.timestamp, amount: $0.amountModel) }}
            .sink { [weak self] in self?.mainView.transactions = $0 }
            .store(in: &cancellables)

        model.$selectedTransaction
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.moveToTransactionDetails(transaction: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func showOverlay(for overlay: Overlay) {
        let overlayViewController = OverlayViewController()

        overlayViewController.onCloseButtonTap = { [weak self] in
            overlayViewController.dismiss(animated: true)
        }

        overlayViewController.onPromptButtonTap = { [weak self] in
            self?.model.runNotifications(registerOnly: false, completion: {
                DispatchQueue.main.async {
                    overlayViewController.dismiss(animated: true)
                }
            })
        }

        overlayViewController.onNoPromptClose = { [weak self] in
            self?.model.runNotifications(registerOnly: true, completion: {
                DispatchQueue.main.async {
                    overlayViewController.dismiss(animated: true)
                }
            })
        }

        overlayViewController.onStartMiningButtonTap = { [weak self] in
            overlayViewController.dismiss(animated: true)
            if let url = URL(string: "https://tari.com/") {
                UIApplication.shared.open(url)
            }
        }

        overlayViewController.activeOverlay = overlay
        if overlay == .disclaimer {
            overlayViewController.totalBalance = mainView.balance
            overlayViewController.availableBalance = mainView.availableBalance
        }

        overlayViewController.transitioningDelegate = overlayViewController
        overlayViewController.modalPresentationStyle = .custom
        present(overlayViewController, animated: false, completion: nil)
    }

    private func showConectionStatusPopUp() {
        AppConnectionHandler.shared.connectionMonitor.showDetailsPopup()
    }

    private func showQRCodeScanner() {
        AppRouter.presentQrCodeScanner(expectedDataTypes: [], disabledDataTypes: [], onExpectedDataScan: nil)
    }

    private func moveToTransactionList() {
        let controller = TransactionHistoryConstructor.buildScene()
        navigationController?.pushViewController(controller, animated: true)
    }

    private func moveToTransactionDetails(transaction: Transaction) {
        let controller = TransactionDetailsConstructor.buildScene(transaction: transaction)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func showAmountHelpPopUp() {

        let popUpModel = PopUpDialogModel(
            title: localized("home.pop_up.amount_help.title"),
            message: localized("home.pop_up.amount_help.message"),
            buttons: [
                PopUpDialogButtonModel(title: localized("home.pop_up.amount_help.buttons.open_url"), type: .normal, callback: {
                    guard let url = URL(string: TariSettings.shared.tariLabsUniversityUrl) else { return }
                    UIApplication.shared.open(url)
                }),
                PopUpDialogButtonModel(title: localized("common.close"), type: .text)
            ],
            hapticType: .none
        )

        PopUpPresenter.showPopUp(model: popUpModel)
    }
}
