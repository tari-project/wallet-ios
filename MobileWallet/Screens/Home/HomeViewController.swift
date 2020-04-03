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

    private let transactionTableVC = TransactionsTableViewController(style: .grouped)
    private var fpc: FloatingPanelController!
    private var grabberHandle: UIView!
    private var selectedTransaction: Any?
    private var maxSendButtonBottomConstraint: CGFloat = 50
    private var minSendButtonBottomConstraint: CGFloat = -20
    private var defaultBottomFadeViewHeight: CGFloat = 0
    private var isAnimatingButton = false
    private var hapticEnabled = false
    private let PANEL_BORDER_CORNER_RADIUS: CGFloat = 15.0
    private let GRABBER_WIDTH: Double = 55.0
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let INTRO_TO_WALLET_USER_DEFAULTS_KEY = "walletHasBeenIntroduced"
    fileprivate let BACKGROUND_GRADIENT_LAYER_NAME = "background-gradient"
    fileprivate let backgroundGradients = [
        Theme.shared.colors.gradient2!.cgColor,
        Theme.shared.colors.gradient1!.cgColor
    ]
    fileprivate var backgroundColorIsNavColor = false
    fileprivate let initialBackgroundColorView = UIView()
    private var testnetKeyServer: TestnetKeyServer?

    var isFirstIntroToWallet: Bool {
        if UserDefaults.standard.string(forKey: INTRO_TO_WALLET_USER_DEFAULTS_KEY) == nil {
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

        setupTestnetKeyServer()
    }

    override func viewWillAppear(_ animated: Bool) {
        styleNavigatorBar(isHidden: !isTransactionViewFullScreen)
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
        Deeplinker.checkDeepLink()

        checkImportSecondUtxo()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        TariEventBus.unregister(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isTransactionViewFullScreen ? .darkContent : .lightContent
    }

    private func setupTestnetKeyServer() {
        guard let wallet = TariLib.shared.tariWallet else {
            return
        }

        do {
            testnetKeyServer = try TestnetKeyServer(wallet: wallet)
        } catch {
            TariLogger.error("Failed to initialise TestnetKeyServer")
        }
    }

    private func requestTestnetTokens() {
        guard let keyServer = testnetKeyServer else {
            TariLogger.error("No TestnetKeyServer initialised")
            return
        }

        let errorTitle = String(format: NSLocalizedString("Failed to claim %@", comment: "Home view testnet airdrop"), TariSettings.shared.network.currencyDisplayName)

        do {
            try keyServer.requestDrop(onSuccess: { () in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                    guard let _ = self else { return }

                    let title = String(format: NSLocalizedString("You just got some %@!", comment: "Home view testnet airdrop"), TariSettings.shared.network.currencyDisplayName)
                    let description = String(format: NSLocalizedString("Try sending a bit of %@ back to Tari Bot. It’s always better to give than to receive (and you’ll see how the wallet works too).", comment: "Home view testnet airdrop"), TariSettings.shared.network.currencyDisplayName)

                    UserFeedback.shared.callToAction(
                        title: title,
                        description: description,
                        actionTitle: NSLocalizedString("Send Tari", comment: "Home view testnet airdrop"),
                        cancelTitle: NSLocalizedString("Try it later", comment: "Home view testnet airdrop"),
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
        guard let keyServer = testnetKeyServer else {
            TariLogger.error("No TestnetKeyServer initialised")
            return
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }

            do {
                try keyServer.importSecondUtxo {
                    DispatchQueue.main.async {
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
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.homeScreenTotalBalanceValueLabel!
            ]
        )

        let lastNumberOfDigitsToFormat = MicroTari.ROUNDED_FRACTION_DIGITS + 1
        balanceLabelAttributedText.addAttributes(
            [
                NSAttributedString.Key.font: Theme.shared.fonts.homeScreenTotalBalanceValueLabelDecimals!,
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.homeScreenTotalBalanceValueLabel!
                //NSAttributedString.Key.baselineOffset: balanceValueLabel.bounds.size.height - 4
            ],
            range: NSRange(location: balanceValueString.count - lastNumberOfDigitsToFormat, length: lastNumberOfDigitsToFormat) //Use fraction digits + 1 for "."
        )

        balanceValueLabel.attributedText = balanceLabelAttributedText
    }

    @objc private func closeFullScreen() {
        setBackgroundColor(isNavColor: false)
        transactionTableVC.scrollToTop()
        self.fpc.move(to: .tip, animated: true)
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
                        self.fpc.move(to: .tip, animated: true)
                    }
                })
                return
            }

            navigationController?.setNavigationBarHidden(false, animated: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self = self else { return }
                guard let navController = self.navigationController else { return }

                if !navController.isNavigationBarHidden {
                    self.setBackgroundColor(isNavColor: true)
                }
            }

            self.isShowingSendButton = false

            self.navigationItem.title = NSLocalizedString("Transactions", comment: "Transactions nav bar heading")

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                self.fpc.surfaceView.cornerRadius = 0
                self.grabberHandle.frame = self.grabberRect(width: 0)
                self.grabberHandle.alpha = 0
                self.view.layoutIfNeeded()
            })
        } else {
            syncBaseNode()
            requestTestnetTokens()
            //User swipes down for the first time
            if isFirstIntroToWallet {
                transactionTableVC.showIntroContent(false)
                UserDefaults.standard.set(true, forKey: INTRO_TO_WALLET_USER_DEFAULTS_KEY)
            }

            navigationController?.setNavigationBarHidden(true, animated: true)
            self.isShowingSendButton = true
            self.navigationItem.title = ""

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                self.fpc.surfaceView.cornerRadius = self.PANEL_BORDER_CORNER_RADIUS
                self.grabberHandle.frame = self.grabberRect(width: self.GRABBER_WIDTH)
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
        view.addSubview(fpc.view)
        fpc.view.frame = view.bounds
        addChild(fpc)

        //Move send button to in front of panel
        bottomFadeView.superview?.bringSubviewToFront(self.bottomFadeView)
        sendButton.superview?.bringSubviewToFront(self.sendButton)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
            guard let self = self else { return }
            self.fpc.show(animated: true) {
                self.didMove(toParent: self)
            }
        })
    }

    private func hideFloatingPanel() {
        fpc.removePanelFromParent(animated: true)
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
        selectedTransaction = transaction
        //TODO on next VC check the type https://stackoverflow.com/questions/24091882/checking-if-an-object-is-a-given-type-in-swift
        self.performSegue(withIdentifier: "HomeToTransactionDetails", sender: nil)
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

    // MARK: - Floating panel setup delegate methods

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
        self.setBackgroundColor(isNavColor: false)

        guard !isFirstIntroToWallet else {
            return
        }

        let y = vc.surfaceView.frame.origin.y
        let tipY = vc.originYOfSurface(for: .tip)

        let progress = CGFloat(max(0.0, min((tipY  - y) / 44.0, 1.0)))

        if progress == 0.0 {
            return
        }

        self.fpc.surfaceView.cornerRadius = self.PANEL_BORDER_CORNER_RADIUS - (self.PANEL_BORDER_CORNER_RADIUS * progress)

        if fpc.position == .tip && !isTransactionViewFullScreen {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.sendButtonBottomConstraint.constant = (self.minSendButtonBottomConstraint) * progress
                self.view.layoutIfNeeded()
            })
        }
    }
}

extension HomeViewController {
    fileprivate func setup() {
        setupTopButtons()

        maxSendButtonBottomConstraint = sendButtonBottomConstraint.constant
        minSendButtonBottomConstraint = -view.safeAreaInsets.bottom - sendButton.frame.height - sendButtonBottomConstraint.constant - 20

        valueIcon.image = Theme.shared.images.currencySymbol

        applyBackgroundGradient(
            from: [Theme.shared.colors.gradient1!.cgColor, Theme.shared.colors.gradient1!.cgColor],
            to: self.backgroundGradients,
            duration: 2.5
        )

        sendButton.setTitle(NSLocalizedString("Send Tari", comment: "Floating send Tari button on home screen"), for: .normal)
        balanceLabel.text = NSLocalizedString("Available Balance", comment: "Home screen balance label")
        balanceLabel.font = Theme.shared.fonts.homeScreenTotalBalanceLabel
        balanceLabel.textColor = Theme.shared.colors.homeScreenTotalBalanceLabel

        setupFloatingPanel()
        styleNavigatorBar(isHidden: !isTransactionViewFullScreen)
        setNavigationBarLeftCloseButton(action: #selector(closeFullScreen))
        showFloatingPanel()

        bottomFadeView.applyFade(Theme.shared.colors.transactionTableBackground!)

        sendButton.isHidden = true
        bottomFadeView.isHidden = true

        balanceValueLabel.animationSpeed = .slow
    }

    fileprivate func setupFloatingPanel() {
        fpc = FloatingPanelController()

        fpc.delegate = self

        transactionTableVC.actionDelegate = self

        fpc.set(contentViewController: transactionTableVC)

        //TODO move custom styling setup into generic function
        fpc.surfaceView.cornerRadius = PANEL_BORDER_CORNER_RADIUS
        fpc.surfaceView.shadowColor = .black
        fpc.surfaceView.shadowRadius = 22

        setupGrabber(fpc)

        fpc.contentMode = .fitToBounds

        // Track a scroll view(or the siblings) in the content view controller.
        fpc.track(scrollView: transactionTableVC.tableView)
    }

    fileprivate func setupGrabber(_ fpc: FloatingPanelController) {
        grabberHandle = UIView(frame: grabberRect(width: GRABBER_WIDTH))
        grabberHandle.layer.cornerRadius = 2.5
        grabberHandle.backgroundColor = Theme.shared.colors.floatingPanelGrabber
        fpc.surfaceView.grabberHandle.isHidden = true
        fpc.surfaceView.addSubview(grabberHandle)
    }

    fileprivate func setBackgroundColor(isNavColor: Bool) {
        guard backgroundColorIsNavColor != isNavColor else { return }

        backgroundColorIsNavColor = isNavColor

        if isNavColor {
            self.applyBackgroundGradient(
                from: self.backgroundGradients,
                to: [Theme.shared.colors.navigationBarBackground!.cgColor, Theme.shared.colors.navigationBarBackground!.cgColor],
                duration: 0.2
            )
        } else {
            self.applyBackgroundGradient(
                from: [Theme.shared.colors.navigationBarBackground!.cgColor, Theme.shared.colors.navigationBarBackground!.cgColor],
                to: self.backgroundGradients,
                duration: 0.1
            )
        }
    }

    private func applyBackgroundGradient(from fromColors: [CGColor], to toColors: [CGColor], duration: TimeInterval) {
        //If there is a gradient set, remove it first
        if let sublayers = view.layer.sublayers {
            for layer in sublayers {
                if layer.name == BACKGROUND_GRADIENT_LAYER_NAME {
                     layer.removeFromSuperlayer()
                }
            }
        }

        let GRADIENT_ANGLE: Double = 180

        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = fromColors
        gradient.locations = [0.0, 0.9]
        gradient.name = BACKGROUND_GRADIENT_LAYER_NAME

        let x: Double! = GRADIENT_ANGLE / 360.0
        let a = pow(sinf(Float(2 * Double.pi * ((x + 0.75) / 2.0))), 2.0)
        let b = pow(sinf(Float(2 * Double.pi * ((x + 0.0) / 2))), 2)
        let c = pow(sinf(Float(2 * Double.pi * ((x + 0.25) / 2))), 2)
        let d = pow(sinf(Float(2 * Double.pi * ((x + 0.5) / 2))), 2)

        gradient.endPoint = CGPoint(x: CGFloat(c), y: CGFloat(d))
        gradient.startPoint = CGPoint(x: CGFloat(a), y: CGFloat(b))

        view.layer.insertSublayer(gradient, at: 0)

        let gradientChangeAnimation = CABasicAnimation(keyPath: "colors")
        gradientChangeAnimation.duration = duration
        gradientChangeAnimation.toValue = toColors
        gradientChangeAnimation.fillMode = CAMediaTimingFillMode.forwards
        gradientChangeAnimation.isRemovedOnCompletion = false
        gradient.add(gradientChangeAnimation, forKey: "colorChange")
    }

    private func setupTopButtons() {
        let iconSize: CGFloat = 30

        let profileButton = UIButton(type: .custom)
        profileButton.setImage(Theme.shared.images.profileIcon, for: .normal)
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileButton)
        profileButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        profileButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        profileButton.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        profileButton.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        profileButton.addTarget(self, action: #selector(onProfileShow), for: .touchUpInside)

        let storeButton = UIButton(type: .custom)
        storeButton.setImage(Theme.shared.images.storeButton, for: .normal)
        storeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(storeButton)
        storeButton.topAnchor.constraint(equalTo: profileButton.topAnchor).isActive = true
        storeButton.trailingAnchor.constraint(equalTo: profileButton.leadingAnchor, constant: -10).isActive = true
        storeButton.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        storeButton.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        storeButton.addTarget(self, action: #selector(onStoreModalShow), for: .touchUpInside)
    }
}
