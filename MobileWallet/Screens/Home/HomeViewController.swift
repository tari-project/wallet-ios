//  HomeViewController.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/10/29
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
import FloatingPanel

enum ScrollDirection {
    case none
    case up
    case down
}

class HomeViewController: UIViewController {

    private static let GRABBER_WIDTH: Double = 55.0
    private static let PANEL_BORDER_CORNER_RADIUS: CGFloat = 15.0

    private let navigationBar = UIView()
    private var navigationBarBottomConstraint: NSLayoutConstraint?

    private let balanceLabel = UILabel()
    private let balanceValueLabel = AnimatedBalanceLabel()

    private lazy var txsTableVC: TxsListViewController = {
        let txController = TxsListViewController()
        txController.backgroundType =  isFirstIntroToWallet ? .intro : .empty
        return txController
    }()

    private let floatingPanelController = FloatingPanelController()
    private lazy var grabberHandle = UIView(frame: grabberRect(width: HomeViewController.GRABBER_WIDTH))

    private var hapticEnabled = false
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var keyServer: KeyServer?
    private var selectedTx: TxProtocol?

    private var lastFPCPosition: FloatingPanel.FloatingPanelPosition = .half

    private var balanceRefreshIsWaitingForWallet = false
    private var tableDataReloadIsWaitingForWallet = false
    private var networkCompatibilityCheckIsWaitingForWallet = false

    private lazy var dimmingLayer: CALayer = {
        let layer = CALayer()
        layer.frame = view.bounds
        layer.backgroundColor = UIColor.black.cgColor
        layer.opacity = 0.0
        view.layer.insertSublayer(layer, at: 1)
        return layer
    }()

    private lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        return gradient
    }()

    var isFirstIntroToWallet: Bool {
        return !UserDefaults.Key.walletHasBeenIntroduced.boolValue()
    }

    private var isTxViewFullScreen: Bool = false {
        didSet {
            showHideFullScreen()
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var navBarHeight: CGFloat {
        return (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0.0) + 56
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        styleNavigatorBar(isHidden: true)
        overrideUserInterfaceStyle = .light
        setup()
        setupKeyServer()
        Tracker.shared.track("/home", "Home - Transaction List")
        TariEventBus.onMainThread(self, eventType: .balanceUpdate) {
            [weak self] (_) in
            self?.safeRefreshBalance()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc func appMovedToForeground() {
        if TariLib.shared.walletState != .started {
            tableDataReloadIsWaitingForWallet = true
        } else {
            txsTableVC.tableView.beginRefreshing()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TariEventBus.onMainThread(self, eventType: .walletStateChanged) {
            [weak self]
            (sender) in
            let walletState = sender!.object as! TariLib.WalletState
            guard let self = self else { return }

            switch walletState {
            case .started:
                if self.balanceRefreshIsWaitingForWallet {
                    self.balanceRefreshIsWaitingForWallet = false
                    self.safeRefreshBalance()
                }
                if self.tableDataReloadIsWaitingForWallet {
                    self.tableDataReloadIsWaitingForWallet = false
                    self.txsTableVC.tableView.beginRefreshing()
                }
                if self.networkCompatibilityCheckIsWaitingForWallet {
                    self.networkCompatibilityCheckIsWaitingForWallet = false
                    self.safeCheckIncompatibleNetwork()
                }
            default:
                break
            }
        }
        safeRefreshBalance()
        deepLinker.checkDeepLink()
        checkImportSecondUtxo()
        safeCheckIncompatibleNetwork()
    }

    private func safeCheckIncompatibleNetwork() {
        if TariLib.shared.walletState != .started {
            networkCompatibilityCheckIsWaitingForWallet = true
            return
        }
        do {
            let persistedNetwork = try TariLib.shared.tariWallet?.getKeyValue(
                key: TariLib.KeyValueStorageKeys.network.rawValue
            )
            if TariNetwork(rawValue: persistedNetwork ?? "") != TariSettings.shared.network {
                // incompatible network
                displayIncompatibleNetworkDialog()
            } else {
                checkBackupPrompt(delay: 0)
            }
        } catch {
            // no-op
        }
    }

    private func displayIncompatibleNetworkDialog() {
        UserFeedback.shared.callToAction(
            title: localized("incompatible_network.title"),
            description: localized("incompatible_network.description"),
            descriptionBoldParts: [
                localized("incompatible_network.description.bold_part_1"),
                localized("incompatible_network.description.bold_part_2")
            ],
            actionTitle: localized("incompatible_network.confirm"),
            cancelTitle: localized("incompatible_network.cancel"),
            onAction: {
                [weak self] in
                self?.deleteWallet()
            },
            onCancel: {
                [weak self] in
                do {
                    try TariLib.shared.setCurrentNetworkKeyValue()
                } catch {
                    // ignore error
                }
                self?.checkBackupPrompt(delay: 2)
            }
        )
    }

    private func deleteWallet() {
        TariLib.shared.deleteWallet()
        BackupScheduler.shared.stopObserveEvents()
        // go back to splash screen
        let navigationController = AlwaysPoppableNavigationController(
            rootViewController: SplashViewController()
        )
        navigationController.setNavigationBarHidden(
            true,
            animated: false
        )
        UIApplication.shared.windows.first?.rootViewController = navigationController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        TariEventBus.unregister(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isTxViewFullScreen ? .darkContent : .lightContent
    }

    private func setupKeyServer() {
        do {
            keyServer = try KeyServer()
        } catch {
            TariLogger.error("Failed to initialise KeyServer")
        }
    }

    private func requestKeyServerTokens() {
        guard let keyServer = keyServer else {
            TariLogger.error("No KeyServer initialised")
            return
        }

        let errorTitle = String(
            format: localized("home.request_drop.error"),
            TariSettings.shared.network.currencyDisplayTicker
        )

        do {
            try keyServer.requestDrop(onSuccess: { () in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
                    guard let _ = self else { return }

                    let title = String(
                        format: localized("home.request_drop.title.with_param"),
                        TariSettings.shared.network.currencyDisplayTicker
                    )
                    let description = String(
                        format: localized("home.request_drop.description.with_param"),
                        TariSettings.shared.network.currencyDisplayTicker
                    )

                    UserFeedback.shared.callToAction(
                        title: title,
                        description: description,
                        actionTitle: String(
                            format: localized("common.send.with_param"),
                            TariSettings.shared.network.currencyDisplayTicker
                        ),
                        cancelTitle: localized("home.request_drop.try_later"),
                        onAction: { [weak self] in
                            guard let self = self else { return }
                            self.onSend()
                        }
                    )
                })

                DispatchQueue.main.async { [weak self] in
                    guard let _ = self else { return }

                }
            }) { (error) in
                DispatchQueue.main.async {
                    UserFeedback.shared.error(
                        title: errorTitle,
                        description: "",
                        error: error
                    )
                }
            }
        } catch {
            UserFeedback.shared.error(
                title: errorTitle,
                description: "Could not setup key server.",
                error: error
            )
        }
    }

    // If we have a second stored utxo, import it
    private func checkImportSecondUtxo() {
        guard let keyServer = keyServer else {
            TariLogger.error("No KeyServer initialised")
            return
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            do {
                try keyServer.importSecondUtxo {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        UserFeedback.shared.callToActionStore()
                    }
                }
            } catch {
                TariLogger.error("Failed to import 2nd UTXO", error: error)
            }
        }
    }

    private func safeRefreshBalance() {
        if TariLib.shared.walletState != .started {
            balanceRefreshIsWaitingForWallet = true
        } else {
            refreshBalance()
        }
    }

    private func refreshBalance() {
        let (totalMicroTari, error) = TariLib.shared.tariWallet!.totalMicroTari
        guard error == nil else {
            UserFeedback.shared.error(
                title: localized("home.error.update_balance"),
                description: "",
                error: error
            )
            return
        }

        let balanceValueString = totalMicroTari!.formatted
        let balanceLabelAttributedText = NSMutableAttributedString(
            string: balanceValueString,
            attributes: [
                NSAttributedString.Key.font: Theme.shared.fonts.homeScreenTotalBalanceValueLabel,
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.homeScreenTotalBalanceValueLabel!
            ]
        )

        let lastNumberOfDigitsToFormat = MicroTari.ROUNDED_FRACTION_DIGITS + 1
        balanceLabelAttributedText.addAttributes(
            [
                NSAttributedString.Key.font: Theme.shared.fonts.homeScreenTotalBalanceValueLabelDecimals,
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.homeScreenTotalBalanceValueLabel!,
                NSAttributedString.Key.baselineOffset: 5
            ],
            range: NSRange(
                location: balanceValueString.count - lastNumberOfDigitsToFormat,
                length: lastNumberOfDigitsToFormat
            )
        )

        balanceLabelAttributedText.addAttributes(
            [NSAttributedString.Key.kern: 1.1],
            range: NSRange(
                location: balanceValueString.count - lastNumberOfDigitsToFormat - 1,
                length: 1
            )
        )

        balanceValueLabel.attributedText = balanceLabelAttributedText

        checkBackupPrompt(delay: 2)
    }

    private func grabberRect(width: Double) -> CGRect {
        return CGRect(
            x: (Double(self.view.frame.size.width) / 2) - (width / 2),
            y: 20,
            width: width,
            height: 5
        )
    }

    private func showHideFullScreen() {
        if isTxViewFullScreen {
            // Don't show header for first intro
            guard !isFirstIntroToWallet else {
                // Wait before auto pulling down
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 3.0 + CATransaction.animationDuration()
                ) {
                    [weak self] in
                    guard let self = self else { return }
                    if self.isTxViewFullScreen {
                        self.floatingPanelController.move(to: .half, animated: true)

                    }
                }
                return
            }
            UIView.animate(
                withDuration: CATransaction.animationDuration(),
                delay: 0,
                options: .curveEaseIn,
                animations: {
                    [weak self] in
                    guard let self = self else { return }
                    self.floatingPanelController.surfaceView.cornerRadius = 0
                    self.grabberHandle.frame = self.grabberRect(width: 0)
                    self.grabberHandle.alpha = 0
                    self.view.layoutIfNeeded()
                }
            )
        } else {
            let delayRequest = isFirstIntroToWallet ? 2.75 : 0.0

            DispatchQueue.main.asyncAfter(
                deadline: .now() + delayRequest
            ) { [weak self] in
                self?.requestKeyServerTokens()
            }

            // User swipes down for the first time
            if isFirstIntroToWallet {
                UserDefaults.Key.walletHasBeenIntroduced.set(true)
            }

            navigationController?.setNavigationBarHidden(true, animated: true)
            self.navigationItem.title = ""

            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                options: .curveEaseIn,
                animations: {
                    [weak self] in
                    guard let self = self else { return }
                    self.floatingPanelController.surfaceView.cornerRadius = HomeViewController.PANEL_BORDER_CORNER_RADIUS
                    self.grabberHandle.frame = self.grabberRect(width: HomeViewController.GRABBER_WIDTH)
                    self.grabberHandle.alpha = 1
                    self.view.layoutIfNeeded()
                }
            )
        }
    }

    func onSend(pubKey: PublicKey? = nil, deepLinkParams: DeepLinkParams? = nil) {
        let sendVC = AddRecipientViewController()

        // This is used by the deep link manager
        if let publicKey = pubKey {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.75
            ) { [weak self] in
                guard let _ = self else { return }
                sendVC.deepLinkParams = deepLinkParams
                sendVC.onAdd(publicKey: publicKey)
            }
        }

        let navigationController = AlwaysPoppableNavigationController(rootViewController: sendVC)
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.modalPresentationStyle = .fullScreen
        UIApplication.shared.menuTabBarController?.present(navigationController, animated: true)
    }
}

// MARK: - Actions
extension HomeViewController {
    @objc private func onGiftButtonAction(_ sender: Any) {

    }

    @objc private func closeButtonAction(_ sender: Any) {
        txsTableVC.tableView.scrollToTop(animated: true)
        floatingPanelController.move(to: .half, animated: true)
        animateNavBar(progress: 0.0, buttonAction: true)
        updateTracking(progress: 0.0)
    }
}

// MARK: - TxTableDelegateMethods
extension HomeViewController: TxsTableViewDelegate {
    func onTxSelect(_ tx: Any) {
        selectedTx = tx as? TxProtocol
        let txVC = TxViewController()
        txVC.transaction = selectedTx
        self.navigationController?.pushViewController(txVC, animated: true)
    }

    func onScrollTopHit(_ isAtTop: Bool) {
        if isAtTop {
            if self.navigationBar.layer.shadowOpacity == 0.0 { return }
            UIView.animate(
                withDuration: CATransaction.animationDuration(),
                animations: {
                    [weak self] in
                    guard let self = self else { return }
                    self.navigationBar.layer.shadowOpacity = 0
                    self.view.layoutIfNeeded()
                }
            )
        } else {
            if self.navigationBar.layer.shadowOpacity == 0.1 { return }
            UIView.animate(
                withDuration: CATransaction.animationDuration(),
                animations: {
                    [weak self] in
                    guard let self = self else { return }
                    self.navigationBar.layer.shadowOpacity = 0.1
                    self.view.layoutIfNeeded()
                }
            )
        }
    }
}

// MARK: - Floating panel setup delegate methods
extension HomeViewController: FloatingPanelControllerDelegate {
    func floatingPanel(
        _ vc: FloatingPanelController,
        layoutFor newCollection: UITraitCollection
    ) -> FloatingPanelLayout? {
        return HomeViewFloatingPanelLayout(navBarHeight: navBarHeight)
    }

    func floatingPanel(
        _ vc: FloatingPanelController,
        behaviorFor newCollection: UITraitCollection
    ) -> FloatingPanelBehavior? {
        return FloatingPanelDefaultBehavior()
    }

    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        lastFPCPosition = vc.position
        txsTableVC.tableView.lockScrollView()
        self.impactFeedbackGenerator.prepare()
    }

    func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
        if vc.position == .full {
            isTxViewFullScreen = true
        } else if vc.position == .half {
            floatingPanelController.surfaceView.contentInsets = HomeViewFloatingPanelLayout.bottomHalfSurfaceViewInsets
            if hapticEnabled {
                self.impactFeedbackGenerator.impactOccurred()
            }
            hapticEnabled = true
            isTxViewFullScreen = false
        }
    }

    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        let progress = getCurrentProgress(floatingController: vc)
        animateNavBar(progress: max(progress, 0))
        animateSurfaceViewBottomInset(progress: max(progress, 0))

        guard !isFirstIntroToWallet else {
            return
        }

        if progress == 0.0 {
            return
        }

        self.floatingPanelController.surfaceView.cornerRadius =
            HomeViewController.PANEL_BORDER_CORNER_RADIUS
                - (HomeViewController.PANEL_BORDER_CORNER_RADIUS * max(progress, 0))

        if floatingPanelController.position == .half && !isTxViewFullScreen {
            UIView.animate(
                withDuration: 0.1,
                delay: 0,
                options: .curveEaseIn,
                animations: {
                    [weak self] in
                    guard let self = self else { return }
                    self.view.layoutIfNeeded()
                }
            )
        }

        if progress > 0.5 {
            floatingPanelController.surfaceView.shadowColor = .clear
        } else {
            floatingPanelController.surfaceView.shadowColor = .black
        }
    }

    func  floatingPanelDidEndDragging(
        _ vc: FloatingPanelController,
        withVelocity velocity: CGPoint,
        targetPosition: FloatingPanelPosition
    ) {
        let progress: CGFloat = targetPosition == .half ? 0.0 : 1.0
        floatingPanelController.surfaceView.shadowColor = targetPosition == .half ? .black : .clear
        animateNavBar(progress: progress)
        animateSurfaceViewBottomInset(progress: progress)
        if targetPosition == .half {
            updateTracking(progress: progress)
        }
    }

    func floatingPanelDidEndDecelerating(_ vc: FloatingPanelController) {
        let progress: CGFloat = vc.position == .half ? 0.0 : 1.0
        updateTracking(progress: progress)
    }

    private func getCurrentProgress(floatingController: FloatingPanelController) -> CGFloat {
        let y = floatingController.surfaceView.frame.origin.y
        let tipY = floatingController.originYOfSurface(for: .half)
        let delta = abs(
            floatingController.originYOfSurface(for: .full)
                - floatingController.originYOfSurface(for: .half)
        )
        if y > tipY { return tipY - y }
        let progress = CGFloat(max(0.0, min((tipY  - y) / delta, 1.0)))
        return progress
    }

    private func animateNavBar(progress: CGFloat, buttonAction: Bool = false) {
        if progress >= 0.0 && progress <= 1.0 {
            navigationBarBottomConstraint?.constant = navBarHeight * progress
            UIView.animate(
                withDuration: CATransaction.animationDuration(),
                delay: 0,
                options: .curveEaseIn,
                animations: {
                    [weak self] in
                    self?.dimmingLayer.opacity = Float(progress / 1.5)
                    self?.view.layoutIfNeeded()
                }
            )
        }
    }

    private func animateSurfaceViewBottomInset(progress: CGFloat) {
        let delta = abs(
            floatingPanelController.originYOfSurface(for: .full)
                - floatingPanelController.originYOfSurface(for: .half)
        )
        let bottomInset = HomeViewFloatingPanelLayout.bottomHalfSurfaceViewInsets.bottom - (delta * progress)
        floatingPanelController.surfaceView.contentInsets = UIEdgeInsets(
            top: HomeViewFloatingPanelLayout.bottomHalfSurfaceViewInsets.top,
            left: 0,
            bottom: bottomInset,
            right: 0
        )
    }

    private func updateTracking(progress: CGFloat) {
        if progress == 1 {
            floatingPanelController.track(scrollView: txsTableVC.tableView)
            txsTableVC.tableView.unlockScrollView()
        } else if progress <= 0 {
            floatingPanelController.track(scrollView: nil)
            txsTableVC.tableView.unlockScrollView()
        }
    }
}

// MARK: setup subview
extension HomeViewController {
    private func setup() {
        applyBackgroundGradient(duration: 2.5)
        setupTopButtons()
        setupBalanceLabel()
        setupBalanceValueLabel()
        setupFloatingPanel()
        setupNavigationBar()
    }

    private func setupTopButtons() {
        return // TODO place back when active
        let iconSize: CGFloat = 30

        let giftButton = UIButton(type: .custom)
        giftButton.setImage(Theme.shared.images.giftButton, for: .normal)
        giftButton.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(giftButton, belowSubview: navigationBar)
        giftButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        giftButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        giftButton.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        giftButton.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        giftButton.addTarget(self, action: #selector(onGiftButtonAction), for: .touchUpInside)
    }

    private func setupBalanceLabel() {
        view.addSubview(balanceLabel)

        balanceLabel.text = localized("home.available_balance")
        balanceLabel.font = Theme.shared.fonts.homeScreenTotalBalanceLabel
        balanceLabel.textColor = Theme.shared.colors.homeScreenTotalBalanceLabel

        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6).isActive = true
        balanceLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30).isActive = true
        balanceLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 25).isActive = true
    }

    private func setupBalanceValueLabel() {
        let balanceContainer = UIView()
        balanceContainer.backgroundColor = .clear

        view.addSubview(balanceContainer)

        balanceContainer.translatesAutoresizingMaskIntoConstraints = false
        balanceContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30).isActive = true
        balanceContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 25).isActive = true
        balanceContainer.heightAnchor.constraint(equalToConstant: 35).isActive = true
        balanceContainer.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: -1).isActive = true

        let valueIcon = UIImageView()
        valueIcon.image = Theme.shared.images.currencySymbol

        balanceContainer.addSubview(valueIcon)

        valueIcon.translatesAutoresizingMaskIntoConstraints = false
        valueIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        valueIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        valueIcon.centerYAnchor.constraint(equalTo: balanceContainer.centerYAnchor).isActive = true
        valueIcon.leadingAnchor.constraint(equalTo: balanceContainer.leadingAnchor).isActive = true

        balanceContainer.addSubview(balanceValueLabel)

        balanceValueLabel.animationSpeed = .slow
        balanceValueLabel.clipsToBounds = true

        balanceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceValueLabel.heightAnchor.constraint(equalToConstant: 47).isActive = true
        balanceValueLabel.centerYAnchor.constraint(equalTo: balanceContainer.centerYAnchor).isActive = true
        balanceValueLabel.leadingAnchor.constraint(equalTo: valueIcon.trailingAnchor, constant: 8).isActive = true
        balanceValueLabel.trailingAnchor.constraint(equalTo: balanceContainer.trailingAnchor).isActive = true
    }

    private func setupNavigationBar() {
        view.addSubview(navigationBar)
        navigationBar.backgroundColor = Theme.shared.colors.navigationBarBackground
        navigationBar.translatesAutoresizingMaskIntoConstraints = false

        navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: navBarHeight).isActive = true

        // Container view style
        navigationBar.layer.shadowOpacity = 0
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 5)
        navigationBar.layer.shadowRadius = 10
        navigationBar.layer.shadowColor = Theme.shared.colors.defaultShadow!.cgColor

        navigationBarBottomConstraint = navigationBar.bottomAnchor.constraint(equalTo: view.topAnchor)
        navigationBarBottomConstraint?.isActive = true

        let navigationBarContainer = UIView()
        navigationBarContainer.backgroundColor = .clear

        navigationBar.addSubview(navigationBarContainer)
        navigationBarContainer.translatesAutoresizingMaskIntoConstraints = false

        navigationBarContainer.heightAnchor.constraint(equalToConstant: 56).isActive = true
        navigationBarContainer.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        navigationBarContainer.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor).isActive = true
        navigationBarContainer.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor).isActive = true

        let navigationBarTitle = UILabel()
        navigationBarContainer.addSubview(navigationBarTitle)
        navigationBarTitle.text = localized("tx_list.title")
        navigationBarTitle.font = Theme.shared.fonts.navigationBarTitle
        navigationBarTitle.textColor = Theme.shared.colors.txListNavBar

        navigationBarTitle.translatesAutoresizingMaskIntoConstraints = false
        navigationBarTitle.centerXAnchor.constraint(equalTo: navigationBarContainer.centerXAnchor).isActive = true
        navigationBarTitle.bottomAnchor.constraint(equalTo: navigationBarContainer.bottomAnchor, constant: -20).isActive = true

        let xMarkButton = UIButton()
        xMarkButton.addTarget(self, action: #selector(closeButtonAction(_:)), for: .touchUpInside)
        xMarkButton.setImage(Theme.shared.images.close, for: .normal)

        navigationBarContainer.addSubview(xMarkButton)

        xMarkButton.translatesAutoresizingMaskIntoConstraints = false
        xMarkButton.centerYAnchor.constraint(equalTo: navigationBarTitle.centerYAnchor).isActive = true
        xMarkButton.leadingAnchor.constraint(equalTo: navigationBarContainer.leadingAnchor, constant: 14.0).isActive = true
        xMarkButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        xMarkButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
    }

    private func setupFloatingPanel() {
        floatingPanelController.delegate = self
        txsTableVC.actionDelegate = self

        floatingPanelController.set(contentViewController: txsTableVC)
        floatingPanelController.surfaceView.cornerRadius = HomeViewController.PANEL_BORDER_CORNER_RADIUS
        floatingPanelController.surfaceView.shadowColor = .black
        floatingPanelController.surfaceView.shadowRadius = 22
        floatingPanelController.surfaceView.contentInsets = HomeViewFloatingPanelLayout.bottomHalfSurfaceViewInsets

        setupGrabber(floatingPanelController)
        floatingPanelController.contentMode = .static
        floatingPanelController.addPanel(toParent: self)

        DispatchQueue.main.asyncAfter(deadline: .now() + CATransaction.animationDuration()) {
            self.floatingPanelController.move(to: self.isFirstIntroToWallet ? .full : .half, animated: true) {
                if !self.isFirstIntroToWallet {
                    DispatchQueue.main.async {
                        self.txsTableVC.tableView.beginRefreshing()
                    }
                }
            }
        }
    }

    private func setupGrabber(_ floatingPanelController: FloatingPanelController) {
        grabberHandle.layer.cornerRadius = 2.5
        grabberHandle.backgroundColor = Theme.shared.colors.floatingPanelGrabber
        floatingPanelController.surfaceView.grabberHandle.isHidden = true
        floatingPanelController.surfaceView.addSubview(grabberHandle)
    }
}
// MARK: Background color behavior
extension HomeViewController {
    private func applyBackgroundGradient(duration: TimeInterval) {
        let locations: [NSNumber] = [0.0, 0.06, 0.18, 0.3, 0.39, 0.51, 0.68, 0.89, 1.0]
        gradientLayer.locations = locations

        let backgroundGradient = [Theme.shared.colors.auroraGradient1!.cgColor,
                                  Theme.shared.colors.auroraGradient2!.cgColor,
                                  Theme.shared.colors.auroraGradient3!.cgColor,
                                  Theme.shared.colors.auroraGradient4!.cgColor,
                                  Theme.shared.colors.auroraGradient5!.cgColor,
                                  Theme.shared.colors.auroraGradient6!.cgColor,
                                  Theme.shared.colors.auroraGradient7!.cgColor,
                                  Theme.shared.colors.auroraGradient8!.cgColor,
                                  Theme.shared.colors.auroraGradient9!.cgColor]

        animateBackgroundColors(
            fromColors: gradientLayer.colors as? [CGColor],
            toColors: backgroundGradient,
            duration: duration
        )
    }

    private func animateBackgroundColors(fromColors: [CGColor]?,
                                         toColors: [CGColor]?,
                                         duration: TimeInterval) {
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = fromColors
        animation.toValue = toColors
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)

        gradientLayer.colors = toColors
        gradientLayer.add(animation, forKey: "animateGradientColorChange")
    }
}
