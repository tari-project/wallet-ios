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
import Combine

enum ScrollDirection {
    case none
    case up
    case down
}

final class HomeViewController: UIViewController {

    private static let GRABBER_WIDTH: Double = 55.0
    private static let PANEL_BORDER_CORNER_RADIUS: CGFloat = 15.0

    private lazy var txsTableVC: TxsListViewController = {
        let txController = TxsListViewController()
        txController.backgroundType =  isFirstIntroToWallet ? .intro : .empty
        return txController
    }()

    private let floatingPanelController = FloatingPanelController()
    private let tapOnKeyWindowGestureRecognizer = UITapGestureRecognizer()

    private lazy var grabberHandle = UIView(frame: grabberRect(width: HomeViewController.GRABBER_WIDTH))

    private var hapticEnabled = false
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var keyServer: KeyServer?
    private var selectedTx: TxProtocol?

    private var lastFPCPosition: FloatingPanel.FloatingPanelPosition = .half

    private var balanceRefreshIsWaitingForWallet = false
    private var tableDataReloadIsWaitingForWallet = false
    private var networkCompatibilityCheckIsWaitingForWallet = false

    var isFirstIntroToWallet: Bool {
        TariSettings.shared.walletSettings.configationState != .ready
    }

    private var isTxViewFullScreen: Bool = false {
        didSet {
            showHideFullScreen()
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var navBarHeight: CGFloat { (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0.0) + 56.0 }

    private let mainView = HomeView()
    private var cancelables: Set<AnyCancellable> = []

    override func loadView() {
        view = mainView
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
        setupConnectionStatusMonitor()
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
        enableWindowTapGesture()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disableWindowTapGesture()
    }

    private func safeCheckIncompatibleNetwork() {
        if TariLib.shared.walletState != .started {
            networkCompatibilityCheckIsWaitingForWallet = true
            return
        }
        do {
            let persistedNetwork = try TariLib.shared.tariWallet?.getKeyValue(key: TariLib.KeyValueStorageKeys.network.rawValue)
            if persistedNetwork != NetworkManager.shared.selectedNetwork.name {
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
            NetworkManager.shared.selectedNetwork.tickerSymbol
        )

        do {
            try keyServer.requestDrop(onSuccess: { () in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
                    guard let _ = self else { return }

                    let title = String(
                        format: localized("home.request_drop.title.with_param"),
                        NetworkManager.shared.selectedNetwork.tickerSymbol
                    )
                    let description = String(
                        format: localized("home.request_drop.description.with_param"),
                        NetworkManager.shared.selectedNetwork.tickerSymbol
                    )

                    UserFeedback.shared.callToAction(
                        title: title,
                        description: description,
                        actionTitle: String(
                            format: localized("common.send.with_param"),
                            NetworkManager.shared.selectedNetwork.tickerSymbol
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

        guard TariLib.shared.walletState == .started else {
            balanceRefreshIsWaitingForWallet = true
            return
        }

        do {
            try refreshBalance()
            try updateAvaiableToSpendAmount()
        } catch {
            UserFeedback.shared.error(title: localized("home.error.update_balance"), description: "", error: error)
        }
    }

    private func refreshBalance() throws {
        let (totalMicroTari, error) = TariLib.shared.tariWallet!.totalMicroTari
        if let error = error { throw error }

        let balanceValueString = totalMicroTari!.formatted
        let balanceLabelAttributedText = NSMutableAttributedString(
            string: balanceValueString,
            attributes: [
                .font: Theme.shared.fonts.homeScreenTotalBalanceValueLabel,
                .foregroundColor: Theme.shared.colors.homeScreenTotalBalanceValueLabel!
            ]
        )

        let lastNumberOfDigitsToFormat = MicroTari.ROUNDED_FRACTION_DIGITS + 1
        balanceLabelAttributedText.addAttributes(
            [
                .font: Theme.shared.fonts.homeScreenTotalBalanceValueLabelDecimals,
                .foregroundColor: Theme.shared.colors.homeScreenTotalBalanceValueLabel!,
                .baselineOffset: 5.0
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

        mainView.balanceValueLabel.attributedText = balanceLabelAttributedText

        checkBackupPrompt(delay: 2)
    }

    private func updateAvaiableToSpendAmount() throws {
        
        let value = try TariLib.shared.tariWallet!.balance().available
        let formattedValue = MicroTari(value).formatted
        let text = NSMutableAttributedString(string: formattedValue)

        text.addAttributes(
            [
                .font: Theme.shared.fonts.homeScreenTotalBalanceValueLabelDecimals,
                .foregroundColor: Theme.shared.colors.homeScreenTotalBalanceValueLabel!
            ],
            range: NSRange(location: 0, length: formattedValue.count)
        )

        mainView.avaiableFoundsValueLabel.attributedText = text
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
                TariSettings.shared.walletSettings.configationState = .ready
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

        DispatchQueue.main.async {
            UIApplication.shared.menuTabBarController?.present(navigationController, animated: true)
        }
    }

    // MARK: - Busness Logic

    private func setupConnectionStatusMonitor() {

        let initialState = handle(connectionState: ConnectionMonitor.shared.state)

        mainView.connectionIndicatorView.currentState = initialState.0
        mainView.tooltipView.text = initialState.1

        let connectionMonitorStatus = TariEventBus
            .events(forType: .connectionMonitorStatusChanged)
            .compactMap { $0.object as? ConnectionMonitorState }
            .compactMap { [weak self] in self?.handle(connectionState: $0) }

        connectionMonitorStatus
            .map(\.0)
            .sink { self.mainView.connectionIndicatorView.currentState = $0 }
            .store(in: &cancelables)

        connectionMonitorStatus
            .map(\.1)
            .assign(to: \.text, on: mainView.tooltipView)
            .store(in: &cancelables)
    }

    private func handle(connectionState: ConnectionMonitorState) -> (ConnectionIndicatorView.State, String?) {
        switch (connectionState.reachability, connectionState.torStatus, connectionState.baseNodeSyncStatus) {
        case (.offline, _, _):
            return (.disconnected, localized("connection_status.error.no_network_connection"))
        case (.unknown, _, _):
            return (.disconnected, localized("connection_status.error.unknown_network_connection_status"))
        case (_, .failed, _):
            return (.disconnected, localized("connection_status.error.disconnected_from_tor"))
        case (_, .connecting, _):
            return (.disconnected, localized("connection_status.error.connecting_with_tor"))
        case (_, .unknown, _):
            return (.disconnected, localized("connection_status.error.unknown_tor_connection_status"))
        case (_, _, .notInited):
            return (.disconnected, localized("connection_status.error.disconnected_from_base_node"))
        case (_, _, .pending):
            return (.connectedWithIssues, localized("connection_status.warning.sync_in_progress"))
        case (_, _, .failure):
            return (.connectedWithIssues, localized("connection_status.warning.sync_failed"))
        default:
            return (.connected, localized("connection_status.ok"))
        }
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
            if mainView.topToolbar.layer.shadowOpacity == 0.0 { return }
            UIView.animate(
                withDuration: CATransaction.animationDuration(),
                animations: {
                    [weak self] in
                    guard let self = self else { return }
                    self.mainView.topToolbar.layer.shadowOpacity = 0
                    self.view.layoutIfNeeded()
                }
            )
        } else {
            if mainView.topToolbar.layer.shadowOpacity == 0.1 { return }
            UIView.animate(
                withDuration: CATransaction.animationDuration(),
                animations: {
                    [weak self] in
                    guard let self = self else { return }
                    self.mainView.topToolbar.layer.shadowOpacity = 0.1
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
            mainView.toolbarBottomConstraint?.constant = navBarHeight * progress
            UIView.animate(
                withDuration: CATransaction.animationDuration(),
                delay: 0,
                options: .curveEaseIn,
                animations: {
                    [weak self] in
                    self?.mainView.dimmingLayer.opacity = Float(progress / 1.5)
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
        setupFloatingPanel()
        setupFeedbacks()
        mainView.toolbarHeightConstraint?.constant = navBarHeight
        mainView.updateViewsOrder()
    }

    private func setupFeedbacks() {

        mainView.connectionIndicatorView.onTap = { [weak self] in
            self?.mainView.isTooltipVisible = true
        }

        mainView.onOnCloseButtonTap = { [weak self] in
            self?.txsTableVC.tableView.scrollToTop(animated: true)
            self?.floatingPanelController.move(to: .half, animated: true)
            self?.animateNavBar(progress: 0.0, buttonAction: true)
            self?.updateTracking(progress: 0.0)
        }

        mainView.onAmountHelpButtonTap = {
            UserFeedback.shared
                .callToAction(
                    title: localized("home.info.amount_help.title"),
                    description: localized("home.info.amount_help.description"),
                    actionTitle: localized("home.info.amount_help.action_button"),
                    cancelTitle: localized("feedback_view.close"),
                    onAction: {
                        guard let url = URL(string: TariSettings.shared.tariLabsUniversityUrl) else { return }
                        UIApplication.shared.open(url)
                    }
                )
        }
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

    private func enableWindowTapGesture() {
        tapOnKeyWindowGestureRecognizer.delegate = self
        UIApplication.shared.keyWindow?.addGestureRecognizer(tapOnKeyWindowGestureRecognizer)
    }

    private func disableWindowTapGesture() {
        UIApplication.shared.keyWindow?.removeGestureRecognizer(tapOnKeyWindowGestureRecognizer)
    }
}

extension HomeViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let shouldBlockTouchEvent = touch.view === mainView.connectionIndicatorView && mainView.isTooltipVisible
        mainView.isTooltipVisible = false
        return shouldBlockTouchEvent
    }
}
