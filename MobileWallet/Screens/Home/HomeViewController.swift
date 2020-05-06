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
    case up
    case down
}

class HomeViewController: UIViewController, FloatingPanelControllerDelegate, TransactionsTableViewDelegate {
    @IBOutlet weak var sendButton: ActionButton!
    @IBOutlet weak var sendButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomFadeView: FadedOverlayView!
    @IBOutlet weak var bottomFadeViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var balanceValueLabel: AnimatedBalanceLabel!
    @IBOutlet weak var valueIcon: UIImageView!

    private static let GRABBER_WIDTH: Double = 55.0
    private static let PANEL_BORDER_CORNER_RADIUS: CGFloat = 15.0

    private static let INTRO_TO_WALLET_USER_DEFAULTS_KEY = "walletHasBeenIntroduced"

    private let floatingPanelController = FloatingPanelController()
    private var grabberHandle: UIView!
    private var selectedTransaction: TransactionProtocol?
    private var maxSendButtonBottomConstraint: CGFloat = 50
    private var minSendButtonBottomConstraint: CGFloat = -20
    private var defaultBottomFadeViewHeight: CGFloat = 0
    private var isAnimatingButton = false
    private var hapticEnabled = false
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private var keyServer: KeyServer?

    private let transactionTableVC = TransactionsTableViewController(style: .grouped)
    private lazy var tableViewContainer: TransactionHistoryContainer = {
        let container = TransactionHistoryContainer(child: transactionTableVC)
        return container
    }()

    //Navigation Bar
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var navigationBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var navigationBarTitle: UILabel!
    @IBOutlet weak var navigationBarBottomConstraint: NSLayoutConstraint!

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
        overrideUserInterfaceStyle = .light

        setup()
        super.viewDidLoad()

        self.refreshBalance()

        Tracker.shared.track("/home", "Home - Transaction List")

        setupKeyServer()
    }

    override func viewWillAppear(_ animated: Bool) {
        sendButtonBottomConstraint.constant = minSendButtonBottomConstraint
        defaultBottomFadeViewHeight = bottomFadeViewHeightConstraint.constant
        bottomFadeViewHeightConstraint.constant = 0

        if !isTransactionViewFullScreen {
            setNeedsStatusBarAppearanceUpdate()
        }

        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.refreshBalance()

        isTransactionViewFullScreen = isTransactionViewFullScreen == true

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
        transactionTableVC.refreshTable()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        TariEventBus.unregister(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isTransactionViewFullScreen ? .darkContent : .lightContent
    }

    private func setupKeyServer() {
        guard let wallet = TariLib.shared.tariWallet else {
            return
        }

        do {
            keyServer = try KeyServer(wallet: wallet)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
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
                //NSAttributedString.Key.baselineOffset: balanceValueLabel.bounds.size.height - 4
            ],
            range: NSRange(location: balanceValueString.count - lastNumberOfDigitsToFormat, length: lastNumberOfDigitsToFormat) //Use fraction digits + 1 for "."
        )

        balanceValueLabel.attributedText = balanceLabelAttributedText
    }

    @IBAction func closeButtonAction(_ sender: Any) {
        transactionTableVC.scrollToTop()
        floatingPanelController.move(to: .tip, animated: true)
        animateNavBar(progress: 0.0)
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
                transactionTableVC.showIntroContent(true)
                //Wait before auto pulling down
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak self] in
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
            requestKeyServerTokens()
            //User swipes down for the first time
            if isFirstIntroToWallet {
                transactionTableVC.showIntroContent(false)
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

    private func syncBaseNode() {
        do {
            if let wallet = TariLib.shared.tariWallet {
                try wallet.syncBaseNode()
            }
        } catch {
            UserFeedback.shared.error(title: "Base node error", description: "Could not sync to base node", error: error)
        }
    }

    private func showHideSendButton() {
        if isShowingSendButton {
            sendButton.isHidden = false
            bottomFadeView.isHidden = false

            UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn, animations: {
                self.sendButtonBottomConstraint.constant = self.maxSendButtonBottomConstraint
                self.bottomFadeView.backgroundColor?.withAlphaComponent(0.5)
                self.bottomFadeViewHeightConstraint.constant = self.defaultBottomFadeViewHeight
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn, animations: {
                self.sendButtonBottomConstraint.constant = self.minSendButtonBottomConstraint
                self.bottomFadeView.backgroundColor?.withAlphaComponent(0.0)
                self.bottomFadeViewHeightConstraint.constant = 0
                self.view.layoutIfNeeded()
            })
        }
    }

    private func showFloatingPanel() {
        view.addSubview(floatingPanelController.view)
        floatingPanelController.view.frame = view.bounds
        addChild(floatingPanelController)

        //Move send button to in front of panel
        bottomFadeView.superview?.bringSubviewToFront(self.bottomFadeView)
        sendButton.superview?.bringSubviewToFront(self.sendButton)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
            guard let self = self else { return }
            self.floatingPanelController.show(animated: true) {
                self.didMove(toParent: self)
            }
        })
    }

    private func hideFloatingPanel() {
        floatingPanelController.removePanelFromParent(animated: true)
    }

    @IBAction func onSendAction(_ sender: Any) {
        onSend()
    }

    func onSend(pubKey: PublicKey? = nil) {
        let sendVC = AddRecipientViewController()

        //This is used by the deep link manager
        if let publicKey = pubKey {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
                guard let _ = self else { return }
                sendVC.onAdd(publicKey: publicKey)
            })
        }

        self.navigationController?.pushViewController(sendVC, animated: true)
    }

    @objc func onProfileShow(_ sender: Any) {
        let vc = ProfileViewController()
        self.present(vc, animated: true, completion: nil)
    }

    @objc func onStoreModalShow(_ sender: Any) {
        UserFeedback.shared.callToActionStore()
    }

    // MARK: - TransactionTableDelegateMethods

    func onTransactionSelect(_ transaction: Any) {
        selectedTransaction = transaction as? TransactionProtocol
        performSegue(withIdentifier: "HomeToTransactionDetails", sender: nil)
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

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //TODO move segue identifiers to enum
        if let transactionVC = segue.destination as? TransactionViewController {
            transactionVC.transaction = selectedTransaction
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
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.sendButtonBottomConstraint.constant = (self.minSendButtonBottomConstraint) * progress
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

    private func animateNavBar(progress: CGFloat) {
        if progress >= 0.0 && progress <= 1.0 {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.navigationBarBottomConstraint.constant = -self.navBarHeight * progress
                self.dimmingLayer.opacity = Float(progress / 1.5)
                self.view.layoutIfNeeded()
            })
        }
    }
}

// MARK: Setup UI
extension HomeViewController {
    private func setup() {
        setupTopButtons()
        applyNavigationBarSettings()

        maxSendButtonBottomConstraint = sendButtonBottomConstraint.constant
        minSendButtonBottomConstraint = -view.safeAreaInsets.bottom - sendButton.frame.height - sendButtonBottomConstraint.constant - 20

        valueIcon.image = Theme.shared.images.currencySymbol

        applyBackgroundGradient(duration: 2.5)

        sendButton.setTitle(
            String(
                format: NSLocalizedString(
                    "Send %@",
                    comment: "Floating send Tari button on home screen"
                ),
                TariSettings.shared.network.currencyDisplayTicker
            ),
            for: .normal
        )
        balanceLabel.text = NSLocalizedString("Available Balance", comment: "Home screen balance label")
        balanceLabel.font = Theme.shared.fonts.homeScreenTotalBalanceLabel
        balanceLabel.textColor = Theme.shared.colors.homeScreenTotalBalanceLabel

        setupFloatingPanel()
        showFloatingPanel()

        bottomFadeView.applyFade(Theme.shared.colors.transactionTableBackground!)

        sendButton.isHidden = true
        bottomFadeView.isHidden = true
        balanceValueLabel.animationSpeed = .slow
    }

    private func applyNavigationBarSettings() {
        navigationBarTitle.text = NSLocalizedString("Transactions", comment: "Transactions nav bar heading")
        navigationBarHeightConstraint.constant = navBarHeight
    }

    private func setupFloatingPanel() {
        floatingPanelController.delegate = self
        transactionTableVC.actionDelegate = self

        floatingPanelController.set(contentViewController: tableViewContainer)

        //TODO move custom styling setup into generic function
        floatingPanelController.surfaceView.cornerRadius = HomeViewController.PANEL_BORDER_CORNER_RADIUS
        floatingPanelController.surfaceView.shadowColor = .black
        floatingPanelController.surfaceView.shadowRadius = 22

        setupGrabber(floatingPanelController)
        floatingPanelController.contentMode = .static
    }

    private func setupGrabber(_ floatingPanelController: FloatingPanelController) {
        grabberHandle = UIView(frame: grabberRect(width: HomeViewController.GRABBER_WIDTH))
        grabberHandle.layer.cornerRadius = 2.5
        grabberHandle.backgroundColor = Theme.shared.colors.floatingPanelGrabber
        floatingPanelController.surfaceView.grabberHandle.isHidden = true
        floatingPanelController.surfaceView.addSubview(grabberHandle)
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
