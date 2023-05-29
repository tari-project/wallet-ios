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
import TariCommon

enum ScrollDirection {
    case none
    case up
    case down
}

final class HomeViewController: DynamicThemeViewController {

    // MARK: - Constants

    private static let panelBorderCornerRadius: CGFloat = 15.0

    // MARK: - Properties

    private let model = HomeViewModel()
    private let mainView = HomeView()

    private var hapticEnabled = false
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var isNetworkCompatibilityChecked = false

    private var isFirstIntroToWallet: Bool {
        TariSettings.shared.walletSettings.configurationState != .ready
    }

    private var isTxViewFullScreen: Bool = false {
        didSet {
            showHideFullScreen()
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    private var grabberWidthConstraint: NSLayoutConstraint?
    private var navBarHeight: CGFloat { (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0.0) + 56.0 }

    private var cancellables: Set<AnyCancellable> = []

    private lazy var txsTableVC: TxsListViewController = {
        let txController = TxsListViewController()
        txController.backgroundType =  isFirstIntroToWallet ? .intro : .empty
        return txController
    }()

    private let floatingPanelController = FloatingPanelController()

    @View private var grabberHandle: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2.5
        return view
    }()

    private var isGrabberVisible: Bool = true {
        didSet {
            grabberWidthConstraint?.constant = isGrabberVisible ? 55.0 : 0.0
            grabberHandle.alpha = isGrabberVisible ? 1.0 : 0.0
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { isTxViewFullScreen ? .darkContent : .lightContent }

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFloatingPanel()
        setupViews()
        setupCallbacks()
        NotificationManager.shared.requestAuthorization()
        StagedWalletSecurityManager.shared.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ShortcutsManager.executeQueuedShortcut()
        checkIncompatibleNetwork()
    }

    // MARK: - Setups

    private func setupViews() {
        mainView.toolbarHeightConstraint?.constant = navBarHeight
        mainView.updateViewsOrder()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupFloatingPanel() {
        floatingPanelController.delegate = self
        txsTableVC.actionDelegate = self

        floatingPanelController.set(contentViewController: txsTableVC)
        floatingPanelController.surfaceView.cornerRadius = HomeViewController.panelBorderCornerRadius
        floatingPanelController.surfaceView.shadowColor = .static.black ?? .clear
        floatingPanelController.surfaceView.shadowRadius = 22.0
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

        floatingPanelController.surfaceView.grabberHandle.isHidden = true
        floatingPanelController.surfaceView.addSubview(grabberHandle)

        let grabberWidthConstraint = grabberHandle.widthAnchor.constraint(equalToConstant: 0.0)
        self.grabberWidthConstraint = grabberWidthConstraint

        let constraints = [
            grabberHandle.centerXAnchor.constraint(equalTo: floatingPanelController.surfaceView.grabberHandle.centerXAnchor),
            grabberHandle.topAnchor.constraint(equalTo: floatingPanelController.surfaceView.topAnchor, constant: 20.0),
            grabberWidthConstraint,
            grabberHandle.heightAnchor.constraint(equalToConstant: 5.0)
        ]

        isGrabberVisible = true

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        model.$connectionStatusImage
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.connectionStatusIcon = $0 }
            .store(in: &cancellables)

        model.$balance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.update(balance: $0) }
            .store(in: &cancellables)

        model.$availableBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.update(avaiableToSpendAmount: $0) }
            .store(in: &cancellables)

        mainView.onOnCloseButtonTap = { [weak self] in
            self?.txsTableVC.tableView.scrollToTop(animated: true)
            self?.floatingPanelController.move(to: .half, animated: true)
            self?.animateNavBar(progress: 0.0)
            self?.updateTracking(progress: 0.0)
        }

        mainView.onAmountHelpButtonTap = { [weak self] in
            self?.showHelpDialog()
        }

        mainView.onConnectionStatusButtonTap = { [weak self] in
            self?.showConectionStatusPopUp()
        }

        mainView.utxosWalletButton.onTap = { [weak self] in
            self?.moveToUtxosWallet()
        }
    }

    // MARK: - Actions

    private func checkIncompatibleNetwork() {

        guard !isNetworkCompatibilityChecked else { return }
        isNetworkCompatibilityChecked = true

        guard model.isNetworkCompatible else {
            showIncompatibleNetworkDialog()
            return
        }
    }

    private func showIncompatibleNetworkDialog() {
        let popUpModel = PopUpDialogModel(
            title: localized("incompatible_network.title"),
            message: localized("incompatible_network.description"),
            buttons: [
                PopUpDialogButtonModel(title: localized("incompatible_network.confirm"), type: .normal, callback: { [weak self] in self?.deleteWallet() }),
                PopUpDialogButtonModel(title: localized("incompatible_network.cancel"), type: .text, callback: { [weak self] in
                    self?.model.updateCompatibleNetworkName()
                })
            ],
            hapticType: .error
        )
        PopUpPresenter.showPopUp(model: popUpModel)
    }

    private func deleteWallet() {
        model.deleteWallet()
        AppRouter.transitionToSplashScreen()
    }

    private func showConectionStatusPopUp() {
        Tari.shared.connectionMonitor.showDetailsPopup()
    }

    private func update(balance: String) {

        guard let textColor = UIColor.static.white else { return }

        let balanceLabelAttributedText = NSMutableAttributedString(
            string: balance,
            attributes: [
                .font: Theme.shared.fonts.homeScreenTotalBalanceValueLabel,
                .foregroundColor: textColor
            ]
        )

        let lastNumberOfDigitsToFormat = MicroTari.roundedFractionDigits + 1

        balanceLabelAttributedText.addAttributes(
            [
                .font: Theme.shared.fonts.homeScreenTotalBalanceValueLabelDecimals,
                .foregroundColor: textColor,
                .baselineOffset: 5.0
            ],
            range: NSRange(location: balance.count - lastNumberOfDigitsToFormat, length: lastNumberOfDigitsToFormat)
        )

        balanceLabelAttributedText.addAttributes(
            [NSAttributedString.Key.kern: 1.1],
            range: NSRange(location: balance.count - lastNumberOfDigitsToFormat - 1, length: 1)
        )

        mainView.balanceValueLabel.attributedText = balanceLabelAttributedText
    }

    private func update(avaiableToSpendAmount: String) {

        let text = NSAttributedString(string: avaiableToSpendAmount, attributes: [
            .font: Theme.shared.fonts.homeScreenTotalBalanceValueLabelDecimals,
            .foregroundColor: UIColor.static.white ?? UIColor()
        ])

        mainView.avaiableFoundsValueLabel.attributedText = text
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        floatingPanelController.surfaceView.backgroundColor = theme.backgrounds.primary
        grabberHandle.backgroundColor = theme.icons.inactive
    }

    // MARK: - Other

    private func showHideFullScreen() {
        if isTxViewFullScreen {
            // Don't show header for first intro
            guard !isFirstIntroToWallet else {
                // Wait before auto pulling down
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 3.0 + CATransaction.animationDuration()
                ) { [weak self] in
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
                animations: { [weak self] in
                    self?.floatingPanelController.surfaceView.cornerRadius = 0
                    self?.isGrabberVisible = false
                    self?.view.layoutIfNeeded()
                }
            )
        } else {

            // User swipes down for the first time
            if isFirstIntroToWallet {
                TariSettings.shared.walletSettings.configurationState = .ready
            }

            navigationController?.setNavigationBarHidden(true, animated: true)
            self.navigationItem.title = ""

            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                options: .curveEaseIn,
                animations: { [weak self] in
                    self?.floatingPanelController.surfaceView.cornerRadius = HomeViewController.panelBorderCornerRadius
                    self?.isGrabberVisible = true
                    self?.view.layoutIfNeeded()
                }
            )
        }
    }
}

// MARK: - TxTableDelegateMethods
extension HomeViewController: TxsTableViewDelegate {

    func onTxSelect(_ tx: Transaction) {
        let controller = TransactionDetailsConstructor.buildScene(transaction: tx)
        navigationController?.pushViewController(controller, animated: true)
    }

    func onScrollTopHit(_ isAtTop: Bool) {
        if isAtTop {
            if mainView.topToolbar.layer.shadowOpacity == 0.0 { return }
            UIView.animate(
                withDuration: CATransaction.animationDuration(),
                animations: { [weak self] in
                    guard let self = self else { return }
                    self.mainView.topToolbar.layer.shadowOpacity = 0
                    self.view.layoutIfNeeded()
                }
            )
        } else {
            if mainView.topToolbar.layer.shadowOpacity == 0.1 { return }
            UIView.animate(
                withDuration: CATransaction.animationDuration(),
                animations: { [weak self] in
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
            HomeViewController.panelBorderCornerRadius
                - (HomeViewController.panelBorderCornerRadius * max(progress, 0))

        if floatingPanelController.position == .half && !isTxViewFullScreen {
            UIView.animate(
                withDuration: 0.1,
                delay: 0,
                options: .curveEaseIn,
                animations: { [weak self] in
                    guard let self = self else { return }
                    self.view.layoutIfNeeded()
                }
            )
        }

        if progress > 0.5 {
            floatingPanelController.surfaceView.shadowColor = .clear
        } else {
            floatingPanelController.surfaceView.shadowColor = .static.black ?? .clear
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

    private func animateNavBar(progress: CGFloat) {
        if progress >= 0.0 && progress <= 1.0 {
            mainView.toolbarBottomConstraint?.constant = navBarHeight * progress
            UIView.animate(
                withDuration: CATransaction.animationDuration(),
                delay: 0,
                options: .curveEaseIn,
                animations: { [weak self] in
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

    private func showHelpDialog() {

        let popUpModel = PopUpDialogModel(
            title: localized("home.info.amount_help.title"),
            message: localized("home.info.amount_help.description"),
            buttons: [
                PopUpDialogButtonModel(title: localized("home.info.amount_help.action_button"), type: .normal, callback: {
                    guard let url = URL(string: TariSettings.shared.tariLabsUniversityUrl) else { return }
                    UIApplication.shared.open(url)
                }),
                PopUpDialogButtonModel(title: localized("feedback_view.close"), type: .text)
            ],
            hapticType: .none
        )

        PopUpPresenter.showPopUp(model: popUpModel)
    }

    private func moveToUtxosWallet() {
        let controller = UTXOsWalletConstructor.buildScene()
        navigationController?.pushViewController(controller, animated: true)
    }
}

private extension PopUpPresenter {

    static func showStorePopUp() {

        let headerSection = PopUpImageHeaderView()

        headerSection.imageHeight = 180.0
        headerSection.imageView.image = Theme.shared.images.storeModal
        headerSection.label.attributedText = storePopUpTitle()

        let contentSection = PopUpComponentsFactory.makeContentView(message: localized("store_modal.description", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol))
        let buttonsSection = PopUpComponentsFactory.makeButtonsView(models: [
            PopUpDialogButtonModel(title: localized("store_modal.action"), icon: Theme.shared.images.storeIcon, type: .normal, callback: { openStoreWebpage() }),
            PopUpDialogButtonModel(title: localized("store_modal.cancel"), type: .text)
        ])

        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        popUp.topOffset = 86.0

        show(popUp: popUp, configuration: .dialog(hapticType: .none))
    }

    private static func storePopUpTitle() -> NSAttributedString {

        let boldedText = localized("store_modal.title.part.2")
        let text = localized("store_modal.title.part.1", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol) + boldedText
        let title = NSMutableAttributedString(string: text)

        if let startIndex = text.indexDistance(of: boldedText) {
            let range = NSRange(location: startIndex, length: boldedText.count)
            title.addAttribute(.font, value: Theme.shared.fonts.feedbackPopupHeavy, range: range)
        }

        return title
    }

    private static func openStoreWebpage() {
        guard let url = URL(string: TariSettings.shared.storeUrl) else { return }
        WebBrowserPresenter.open(url: url)
        Logger.log(message: "Opened store link", domain: .general, level: .verbose)
    }
}
