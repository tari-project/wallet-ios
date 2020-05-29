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

class HomeViewController: UIViewController, FloatingPanelControllerDelegate {

    private static let GRABBER_WIDTH: Double = 55.0
    private static let PANEL_BORDER_CORNER_RADIUS: CGFloat = 15.0
    private static let INTRO_TO_WALLET_USER_DEFAULTS_KEY = "walletHasBeenIntroduced"

    private let navigationBar = UIView()
    private var navigationBarBottomConstraint: NSLayoutConstraint?

    private let bottomFadeView = FadedOverlayView()
    private var bottomFadeBottomConstraint: NSLayoutConstraint?

    private let balanceLabel = UILabel()
    private let balanceValueLabel = AnimatedBalanceLabel()

    private lazy var tableViewContainer = TransactionHistoryContainer(child: transactionTableVC)
    private lazy var transactionTableVC = TransactionsTableViewController(style: .grouped, backgroundState: isFirstIntroToWallet ? .intro : .empty)

    private let floatingPanelController = FloatingPanelController()
    private lazy var grabberHandle = UIView(frame: grabberRect(width: HomeViewController.GRABBER_WIDTH))

    private var hapticEnabled = false
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var keyServer: KeyServer?
    private var selectedTransaction: TransactionProtocol?

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
        if UserDefaults.standard.string(forKey: HomeViewController.INTRO_TO_WALLET_USER_DEFAULTS_KEY) == nil {
            return true
        }

        return false
    }

    private var isTransactionViewFullScreen: Bool = false {
        didSet {
            showHideFullScreen()
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    private var isShowingSendButton: Bool = false {
        didSet {
            showHideSendButton()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        styleNavigatorBar(isHidden: true)
        overrideUserInterfaceStyle = .light
        setup()
        refreshBalance()
        setupKeyServer()
        Tracker.shared.track("/home", "Home - Transaction List")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshBalance()
        TariEventBus.onMainThread(self, eventType: .balanceUpdate) { [weak self] (_) in
            guard let self = self else { return }
            self.refreshBalance()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
            guard let self = self else { return }
            self.isShowingSendButton = self.isShowingSendButton == true
        })

        checkClipboardForBaseNode()
        deepLinker.checkDeepLink()

        checkImportSecondUtxo()
        bottomFadeView.applyFade(Theme.shared.colors.transactionTableBackground!)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        TariEventBus.unregister(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isTransactionViewFullScreen ? .darkContent : .lightContent
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

        let errorTitle = String(format: NSLocalizedString("Failed to claim %@", comment: "Home view airdrop"), TariSettings.shared.network.currencyDisplayTicker)

        do {
            try keyServer.requestDrop(onSuccess: { () in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
                    guard let _ = self else { return }

                    let title = String(format: NSLocalizedString("You just got some %@!", comment: "Home view airdrop"), TariSettings.shared.network.currencyDisplayTicker)
                    let description = String(format: NSLocalizedString("Try sending a bit of %@ back to Tari Bot. It’s always better to give than to receive (and you’ll see how the wallet works too).", comment: "Home view airdrop"), TariSettings.shared.network.currencyDisplayTicker)

                    UserFeedback.shared.callToAction(
                        title: title,
                        description: description,
                        actionTitle: String(
                            format: NSLocalizedString(
                                "Send %@",
                                comment: "Home view airdrop"
                            ),
                            TariSettings.shared.network.currencyDisplayTicker
                        ),
                        cancelTitle: NSLocalizedString("Try it later", comment: "Home view airdrop"),
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
                    UserFeedback.shared.error(title: errorTitle, description: "", error: error)
                }
            }
        } catch {
            UserFeedback.shared.error(title: errorTitle, description: "Could not setup key server.", error: error)
        }
    }

    //If we have a second stored utxo, import it
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

    private func refreshBalance() {
        guard let wallet = TariLib.shared.tariWallet else {
            UserFeedback.shared.error(title: NSLocalizedString("Wallet not initialized", comment: "Home screen"), description: "")
            return
        }

        let (totalMicroTari, error) = wallet.totalMicroTari
        guard error == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Balance update failed", comment: "Home screen"),
                description: "",
                error: error
            )
            return
        }

        let balanceValueString = totalMicroTari!.formatted
        let balanceLabelAttributedText = NSMutableAttributedString(
            string: balanceValueString,
            attributes: [
                NSAttributedString.Key.font: Theme.shared.fonts.homeScreenTotalBalanceValueLabel!,
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.homeScreenTotalBalanceValueLabel!,
                NSAttributedString.Key.kern: -1.43

            ]
        )

        let lastNumberOfDigitsToFormat = MicroTari.ROUNDED_FRACTION_DIGITS + 1
        balanceLabelAttributedText.addAttributes(
            [
                NSAttributedString.Key.font: Theme.shared.fonts.homeScreenTotalBalanceValueLabelDecimals!,
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.homeScreenTotalBalanceValueLabel!,
                NSAttributedString.Key.kern: -0.57
            ],
            range: NSRange(location: balanceValueString.count - lastNumberOfDigitsToFormat, length: lastNumberOfDigitsToFormat)
        )

        balanceValueLabel.attributedText = balanceLabelAttributedText
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
        if isTransactionViewFullScreen {
            //Don't show header for first intro
            guard !isFirstIntroToWallet else {
                self.isShowingSendButton = false
                //Wait before auto pulling down
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 3.0 + CATransaction.animationDuration(),
                    execute: {
                        [weak self] in
                        guard let self = self else { return }
                        if self.isTransactionViewFullScreen {
                            self.floatingPanelController.move(to: .tip, animated: true)

                        }
                })
                return
            }

            self.isShowingSendButton = false
            UIView.animate(withDuration: CATransaction.animationDuration(), delay: 0, options: .curveEaseIn, animations: {
                self.floatingPanelController.surfaceView.cornerRadius = 0
                self.grabberHandle.frame = self.grabberRect(width: 0)
                self.grabberHandle.alpha = 0
                self.view.layoutIfNeeded()
            })
        } else {

            let delayRequest = isFirstIntroToWallet ? 2.75 : 0.0

            DispatchQueue.main.asyncAfter(deadline: .now() + delayRequest, execute: { [weak self] in
                self?.requestKeyServerTokens()
            })

            //User swipes down for the first time
            if isFirstIntroToWallet {
                UserDefaults.standard.set(true, forKey: HomeViewController.INTRO_TO_WALLET_USER_DEFAULTS_KEY)
            }

            navigationController?.setNavigationBarHidden(true, animated: true)
            self.isShowingSendButton = true
            self.navigationItem.title = ""

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                self.floatingPanelController.surfaceView.cornerRadius = HomeViewController.PANEL_BORDER_CORNER_RADIUS
                self.grabberHandle.frame = self.grabberRect(width: HomeViewController.GRABBER_WIDTH)
                self.grabberHandle.alpha = 1
                self.view.layoutIfNeeded()
            })
        }
    }

    private func showHideSendButton() {
        if isShowingSendButton {
            UIView.animate(withDuration: CATransaction.animationDuration(), delay: 0.1, options: .curveEaseIn, animations: {
                self.bottomFadeView.backgroundColor?.withAlphaComponent(0.5)
                self.bottomFadeBottomConstraint?.constant = 0
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: CATransaction.animationDuration(), delay: 0.1, options: .curveEaseIn, animations: {
                self.bottomFadeView.backgroundColor?.withAlphaComponent(0.0)
                self.bottomFadeBottomConstraint?.constant = 120
                self.view.layoutIfNeeded()
            })
        }
    }

    private func showFloatingPanel() {
        view.addSubview(floatingPanelController.view)
        floatingPanelController.view.frame = view.bounds
        addChild(floatingPanelController)
        DispatchQueue.main.asyncAfter(deadline: .now() + CATransaction.animationDuration(), execute: { [weak self] in
            guard let self = self else { return }
            self.floatingPanelController.show(animated: true) {
                self.didMove(toParent: self)
            }
        })
    }

    private func hideFloatingPanel() {
        floatingPanelController.removePanelFromParent(animated: true)
    }

    func onSend(pubKey: PublicKey? = nil, deepLinkParams: DeepLinkParams? = nil) {
        let sendVC = AddRecipientViewController()

        //This is used by the deep link manager
        if let publicKey = pubKey {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: { [weak self] in
                guard let _ = self else { return }
                sendVC.deepLinkParams = deepLinkParams
                sendVC.onAdd(publicKey: publicKey)
            })
        }

        self.navigationController?.pushViewController(sendVC, animated: true)
    }
}

// MARK: - Actions
extension HomeViewController {
    @objc func onProfileShow(_ sender: Any) {
        let vc = ProfileViewController()
        self.present(vc, animated: true, completion: nil)
    }

    @objc private func onStoreModalShow(_ sender: Any) {
        UserFeedback.shared.callToActionStore()
    }

    @objc private func onSendAction(_ sender: Any) {
        onSend()
    }

    @objc private func closeButtonAction(_ sender: Any) {
        transactionTableVC.scrollToTop()
        floatingPanelController.move(to: .tip, animated: true)
        animateNavBar(progress: 0.0, buttonAction: true)
    }
}

// MARK: - TransactionTableDelegateMethods
extension HomeViewController: TransactionsTableViewDelegate {
    func onTransactionSelect(_ transaction: Any) {
        selectedTransaction = transaction as? TransactionProtocol
        let transactionVC = TransactionViewController()
        transactionVC.transaction = selectedTransaction
        self.navigationController?.pushViewController(transactionVC, animated: true)
    }

    func onScrollDirectionChange(_ direction: ScrollDirection) {
        if isTransactionViewFullScreen {
            if direction == .up {
                self.isShowingSendButton = true
            } else if direction == .down {
                self.isShowingSendButton = false
            }
        }
    }
}

// MARK: - Floating panel setup delegate methods
extension HomeViewController {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return HomeViewFloatingPanelLayout(navBarHeight: navBarHeight, initialFullScreen: isFirstIntroToWallet)
    }

    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return HomeViewFloatingPanelBehavior()
    }

    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        self.impactFeedbackGenerator.prepare()
    }

    func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
        if vc.position == .full {
            isTransactionViewFullScreen = true
        } else if vc.position == .tip || vc.position == .half {
            if hapticEnabled {
                self.impactFeedbackGenerator.impactOccurred()
            }
            hapticEnabled = true
            isTransactionViewFullScreen = false
        }
    }

    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        let progress = getCurrentProgress(floatingController: vc)
        animateNavBar(progress: progress)

        guard !isFirstIntroToWallet else {
            return
        }

        if progress == 0.0 {
            return
        }

        self.floatingPanelController.surfaceView.cornerRadius = HomeViewController.PANEL_BORDER_CORNER_RADIUS - (HomeViewController.PANEL_BORDER_CORNER_RADIUS * progress)

        if floatingPanelController.position == .tip && !isTransactionViewFullScreen {
            bottomFadeBottomConstraint?.constant = bottomFadeView.bounds.height * progress
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            })
        }

        if progress > 0.5 {
            floatingPanelController.surfaceView.shadowColor = .clear
        } else {
            floatingPanelController.surfaceView.shadowColor = .black
        }
    }

    func  floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        let progress: CGFloat = targetPosition == .tip ? 0.0 : 1.0
        floatingPanelController.surfaceView.shadowColor = targetPosition == .tip ? .black : .clear
        animateNavBar(progress: progress)
    }

    private func getCurrentProgress(floatingController: FloatingPanelController) -> CGFloat {
        let y = floatingController.surfaceView.frame.origin.y
        let tipY = floatingController.originYOfSurface(for: .tip)
        let progress = CGFloat(max(0.0, min((tipY  - y) / navBarHeight, 1.0)))

        return progress
    }

    private func animateNavBar(progress: CGFloat, buttonAction: Bool = false) {
        if progress >= 0.0 && progress <= 1.0 {
            navigationBarBottomConstraint?.constant = navBarHeight * progress
            let duration = buttonAction ? CATransaction.animationDuration() : 0.1

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn, animations: { [weak self] in
                self?.dimmingLayer.opacity = Float(progress / 1.5)
                self?.view.layoutIfNeeded()
            })
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
        setupNavigationBar()
        setupFloatingPanel()
        setupFadeView()
    }

    private func setupTopButtons() {
        let iconSize: CGFloat = 30

        let profileButton = UIButton(type: .custom)
        profileButton.setImage(Theme.shared.images.profileIcon, for: .normal)
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(profileButton, belowSubview: navigationBar)

        profileButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        profileButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        profileButton.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        profileButton.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        profileButton.addTarget(self, action: #selector(onProfileShow), for: .touchUpInside)

        let storeButton = UIButton(type: .custom)
        storeButton.setImage(Theme.shared.images.storeButton, for: .normal)
        storeButton.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(storeButton, belowSubview: navigationBar)
        storeButton.topAnchor.constraint(equalTo: profileButton.topAnchor).isActive = true
        storeButton.trailingAnchor.constraint(equalTo: profileButton.leadingAnchor, constant: -10).isActive = true
        storeButton.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        storeButton.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        storeButton.addTarget(self, action: #selector(onStoreModalShow), for: .touchUpInside)
    }

    private func setupBalanceLabel() {
        view.addSubview(balanceLabel)

        balanceLabel.text = NSLocalizedString("Available Balance", comment: "Home screen balance label")
        balanceLabel.font = Theme.shared.fonts.homeScreenTotalBalanceLabel
        balanceLabel.textColor = Theme.shared.colors.homeScreenTotalBalanceLabel

        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40).isActive = true
        balanceLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25).isActive = true
        balanceLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 25).isActive = true
    }

    private func setupBalanceValueLabel() {
        let balanceContainer = UIView()
        balanceContainer.backgroundColor = .clear

        view.addSubview(balanceContainer)

        balanceContainer.translatesAutoresizingMaskIntoConstraints = false
        balanceContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25).isActive = true
        balanceContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 25).isActive = true
        balanceContainer.heightAnchor.constraint(equalToConstant: 54).isActive = true
        balanceContainer.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor).isActive = true

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
        navigationBarTitle.text = NSLocalizedString("Transactions", comment: "Transactions nav bar heading")
        navigationBarTitle.font = Theme.shared.fonts.navigationBarTitle

        navigationBarTitle.translatesAutoresizingMaskIntoConstraints = false
        navigationBarTitle.centerXAnchor.constraint(equalTo: navigationBarContainer.centerXAnchor).isActive = true
        navigationBarTitle.centerYAnchor.constraint(equalTo: navigationBarContainer.centerYAnchor).isActive = true

        let xMarkButton = UIButton()
        xMarkButton.addTarget(self, action: #selector(closeButtonAction(_:)), for: .touchUpInside)
        xMarkButton.setImage(Theme.shared.images.close, for: .normal)

        navigationBarContainer.addSubview(xMarkButton)

        xMarkButton.translatesAutoresizingMaskIntoConstraints = false
        xMarkButton.centerYAnchor.constraint(equalTo: navigationBarContainer.centerYAnchor).isActive = true
        xMarkButton.leadingAnchor.constraint(equalTo: navigationBarContainer.leadingAnchor, constant: 20.0).isActive = true
        xMarkButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        xMarkButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
    }

    private func setupFloatingPanel() {
        floatingPanelController.delegate = self
        transactionTableVC.actionDelegate = self

        floatingPanelController.set(contentViewController: tableViewContainer)

        floatingPanelController.surfaceView.cornerRadius = HomeViewController.PANEL_BORDER_CORNER_RADIUS
        floatingPanelController.surfaceView.shadowColor = .black
        floatingPanelController.surfaceView.shadowRadius = 22

        setupGrabber(floatingPanelController)
        floatingPanelController.contentMode = .static

        showFloatingPanel()
    }

    private func setupGrabber(_ floatingPanelController: FloatingPanelController) {
        grabberHandle.layer.cornerRadius = 2.5
        grabberHandle.backgroundColor = Theme.shared.colors.floatingPanelGrabber
        floatingPanelController.surfaceView.grabberHandle.isHidden = true
        floatingPanelController.surfaceView.addSubview(grabberHandle)
    }

    private func setupFadeView() {
        view.addSubview(bottomFadeView)

        bottomFadeView.translatesAutoresizingMaskIntoConstraints = false
        bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomFadeView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        bottomFadeBottomConstraint = bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomFadeBottomConstraint?.isActive = true

        let sendButton = ActionButton()
        view.addSubview(sendButton)
        let title =  String(format: NSLocalizedString("Send %@",
                                                      comment: "Floating send Tari button on home screen"),
                            TariSettings.shared.network.currencyDisplayTicker )
        sendButton.setTitle(title, for: .normal)
        sendButton.addTarget(self, action: #selector(onSendAction(_:)), for: .touchUpInside)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.widthAnchor.constraint(equalToConstant: 163).isActive = true
        sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: bottomFadeView.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true

        bottomFadeView.alpha = 0.0
        sendButton.alpha = 0.0

        UIView.animate(withDuration: CATransaction.animationDuration(), delay: 0.5, options: .curveLinear, animations: { [weak self] in
            self?.bottomFadeView.alpha = 1.0
            sendButton.alpha = 1.0
        })
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

        animateBackgroundColors(fromColors: gradientLayer.colors as? [CGColor], toColors: backgroundGradient, duration: duration)
    }

    private func animateBackgroundColors(fromColors: [CGColor]?, toColors: [CGColor]?, duration: TimeInterval) {
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
