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
    @IBOutlet weak var sendButton: SendButton!
    @IBOutlet weak var sendButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomFadeView: FadedOverlayView!
    @IBOutlet weak var bottomFadeViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var balanceValueLabel: AnimatedBalanceLabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
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
    private let PANEL_BORDER_CORNER_RADIUS: CGFloat = 36.0
    private let GRABBER_WIDTH: Double = 55.0
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let INTRO_TO_WALLET_USER_DEFAULTS_KEY = "walletHasBeenIntroduced"

    var isFirstIntroToWallet: Bool {
        if (UserDefaults.standard.string(forKey: INTRO_TO_WALLET_USER_DEFAULTS_KEY) == nil) {
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

    private var isShowingSendButton: Bool = true {
        didSet {
            showHideSendButton()
        }
    }

    override func viewDidLoad() {
        overrideUserInterfaceStyle = .light

        setup()
        super.viewDidLoad()

        self.refreshBalance()
        TariEventBus.onMainThread(self, eventType: .balanceUpdate) { [weak self] (_) in
            guard let self = self else {
                return
            }

            self.refreshBalance()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        sendButtonBottomConstraint.constant = minSendButtonBottomConstraint
        defaultBottomFadeViewHeight = bottomFadeViewHeightConstraint.constant
        bottomFadeViewHeightConstraint.constant = 0

        //Check if we're coming back from a segue
        if !isTransactionViewFullScreen {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }

        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //Make sure the button animates into view when we navigate back to this controller
        isShowingSendButton = isShowingSendButton == true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        TariEventBus.unregister(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isTransactionViewFullScreen ? .darkContent : .lightContent
    }

    private func setup() {
        maxSendButtonBottomConstraint = sendButtonBottomConstraint.constant
        minSendButtonBottomConstraint = -view.safeAreaInsets.bottom - sendButton.frame.height - sendButtonBottomConstraint.constant - 20

        valueIcon.image = Theme.shared.images.currencySymbol
        view.backgroundColor = Theme.shared.colors.homeScreenBackground
        sendButton.setTitle(NSLocalizedString("Send Tari", comment: "Floating send Tari button on home screen"), for: .normal)
        balanceLabel.text = NSLocalizedString("Available Balance", comment: "Home screen balance label")
        balanceLabel.font = Theme.shared.fonts.homeScreenTotalBalanceLabel
        balanceLabel.textColor = Theme.shared.colors.homeScreenTotalBalanceLabel

        //Balance has multiple font sizes

        setupFloatingPanel()
        setupNavigatorBar()
        showFloatingPanel()

        backgroundImageView.alpha = 0.0
        backgroundImageView.image = Theme.shared.images.homeBackgroundImage
        UIView.animate(
            withDuration: 0.6,
            delay: 0.25,
            options: .curveEaseIn,
            animations: {
                self.backgroundImageView.alpha = 1.0
            }
        )

        bottomFadeView.applyFade(Theme.shared.colors.transactionTableBackground!)
        sendButton.applyShadow()
    }

    private func requestTestnetTokens() {
        do {
            let tempKeyServer = try TestnetKeyServer(wallet: TariLib.shared.tariWallet!)
            try tempKeyServer.requestDrop(onSuccess: { () in
                DispatchQueue.main.async { [weak self] in
                    guard let _ = self else { return }
                    UserFeedback.shared.callToAction(
                        title: NSLocalizedString("You got some Tari!", comment: "Home view testnet airdrop"),
                        description: NSLocalizedString("TariBot has just sent you some Tari. To give the wallet a quick test, try sending TariBot back some Tari to see how it works.", comment: "Home view testnet airdrop"),
                        cancelTitle: NSLocalizedString("I’ll try it later", comment: "Home view testnet airdrop"),
                        actionTitle: NSLocalizedString("Send Tari", comment: "Home view testnet airdrop"),
                        onAction: {
                            guard let self = self else { return }
                            self.onSend()
                        }
                    )
                }
            }) { (error) in
                DispatchQueue.main.async {
                    UserFeedback.shared.error(title: "Failed to claim testnet tokens", description: "", error: error)
                }
            }
        } catch {
            UserFeedback.shared.error(title: "Failed to claim testnet tokens", description: "Could not setup key server.", error: error)
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

    private func setupNavigatorBar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)

        if let navController = navigationController {
            let navBar = navController.navigationBar

            navBar.barTintColor = Theme.shared.colors.navigationBarBackground
            navBar.setBackgroundImage(UIImage(color: Theme.shared.colors.navigationBarBackground!), for: .default)

            navBar.isTranslucent = true

            navigationController?.setNavigationBarHidden(true, animated: false)
            navBar.tintColor = Theme.shared.colors.navigationBarTint

            navBar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.navigationBarTint!,
                NSAttributedString.Key.font: Theme.shared.fonts.navigationBarTitle!
            ]

            //Remove border
            navBar.shadowImage = UIImage()

            //TODO fix size
            navBar.backIndicatorImage = Theme.shared.images.backArrow
            navBar.backIndicatorTransitionMaskImage = Theme.shared.images.backArrow

            let closeButtonItem = UIBarButtonItem.customNavBarItem(target: self, image: Theme.shared.images.close!, action: #selector(closeFullScreen))

            self.navigationItem.leftBarButtonItem = closeButtonItem
        }
    }

    @objc private func closeFullScreen() {
        setBackgroundColor(isNavColor: false)
        transactionTableVC.scrollToTop()
        self.fpc.move(to: .tip, animated: true)
    }

    private func setupFloatingPanel() {
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

    private func grabberRect(width: Double) -> CGRect {
        return CGRect(
            x: (Double(self.view.frame.size.width) / 2) - (width / 2),
            y: 20,
            width: width,
            height: 5
        )
    }

    private func setupGrabber(_ fpc: FloatingPanelController) {
        grabberHandle = UIView(frame: grabberRect(width: GRABBER_WIDTH))
        grabberHandle.layer.cornerRadius = 2.5
        grabberHandle.backgroundColor = Theme.shared.colors.floatingPanelGrabber
        fpc.surfaceView.grabberHandle.isHidden = true
        fpc.surfaceView.addSubview(grabberHandle)
    }

    private func showHideFullScreen() {
        if isTransactionViewFullScreen {
            //Don't show header for first intro
            guard !isFirstIntroToWallet else {
                self.isShowingSendButton = false
                transactionTableVC.showIntroContent(true)
                return
            }

            navigationController?.setNavigationBarHidden(false, animated: true)
            self.setBackgroundColor(isNavColor: true)

            self.isShowingSendButton = false

            self.navigationItem.title = NSLocalizedString("Transactions", comment: "Transactions nav bar heading")

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                self.fpc.surfaceView.cornerRadius = 0
                self.grabberHandle.frame = self.grabberRect(width: 0)
                self.grabberHandle.alpha = 0
                self.view.layoutIfNeeded()
            })
        } else {
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

    private func setBackgroundColor(isNavColor: Bool) {
        if isNavColor {
            UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn, animations: {
                self.view.backgroundColor = Theme.shared.colors.navigationBarBackground
            })
        } else {
            UIView.animate(withDuration: 0.1) {
                self.view.backgroundColor = Theme.shared.colors.homeScreenBackground
            }
        }
    }

    private func showHideSendButton() {
        if isShowingSendButton {
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
        bottomFadeView.superview?.bringSubviewToFront(bottomFadeView)
        sendButton.superview?.bringSubviewToFront(sendButton)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
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

    func onSend() {
        let sendVC = AddRecipientViewController()
        self.navigationController?.pushViewController(sendVC, animated: true)
    }

    @IBAction func onProfileAction(_ sender: Any) {
        let storyboard = UIStoryboard.init(name: "Profile", bundle: nil)
        if let vc = storyboard.instantiateViewController(identifier: "ProfileViewController") as? ProfileViewController {
            self.present(vc, animated: true, completion: nil)
        }
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
