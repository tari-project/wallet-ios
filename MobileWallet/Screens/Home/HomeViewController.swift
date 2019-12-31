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
    @IBOutlet weak var balanceValueLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var valueIcon: UIImageView!

    private let transactionTableVC = TransactionsTableViewController(style: .grouped)
    private var fpc: FloatingPanelController!
    private var grabberHandle: UIView!
    private var selectedTransaction: Transaction?
    private var maxSendButtonBottomConstraint: CGFloat = 50
    private var minSendButtonBottomConstraint: CGFloat = -20
    private var defaultBottomFadeViewHeight: CGFloat = 0
    private var isAnimatingButton = false
    private var hapticEnabled = false
    private let PANEL_BORDER_CORNER_RADIUS: CGFloat = 36.0
    private let GRABBER_WIDTH: Double = 55.0
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

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
        balanceValueLabel.textColor = Theme.shared.colors.homeScreenTotalBalanceValueLabel

        balanceValueLabel.adjustsFontSizeToFitWidth = true

        //Balance has multiple font sizes
        let balanceValueString = dummyBalance.displayStringWithNegativeOperator
        let balanceLabelAttributedText = NSMutableAttributedString(
            string: balanceValueString,
            attributes: [
                NSAttributedString.Key.font: Theme.shared.fonts.homeScreenTotalBalanceValueLabel!
            ]
        )

        balanceLabelAttributedText.addAttributes(
            [
                NSAttributedString.Key.font: Theme.shared.fonts.homeScreenTotalBalanceValueLabelDecimals!,
                NSAttributedString.Key.baselineOffset: balanceValueLabel.bounds.size.height - 4
            ],
            range: NSRange(location: balanceValueString.count - 3, length: 3) //Always last 3 chars as the decimal places
        )

        balanceValueLabel.attributedText = balanceLabelAttributedText
        balanceValueLabel.minimumScaleFactor = 0.3
        balanceValueLabel.lineBreakMode = .byTruncatingTail
        balanceValueLabel.numberOfLines = 1

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
    }

    private func setupNavigatorBar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)

        if let navController = navigationController {
            let navBar = navController.navigationBar

            navBar.barTintColor = Theme.shared.colors.navigationBarBackground
            navBar.isTranslucent = false

            navigationController?.setNavigationBarHidden(true, animated: false)
            navBar.tintColor = Theme.shared.colors.navigationBarTint

            navBar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.navigationBarTint!,
                NSAttributedString.Key.font: Theme.shared.fonts.navigationBarTitle!
            ]

            //Remove border
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()

            //TODO fix size
            navBar.backIndicatorImage = Theme.shared.images.backArrow
            navBar.backIndicatorTransitionMaskImage = Theme.shared.images.backArrow

            let closeButtonItem = UIBarButtonItem.customNavBarItem(target: self, image: Theme.shared.images.close!, action: #selector(closeFullScreen))

            self.navigationItem.leftBarButtonItem = closeButtonItem
        }
    }

    @objc private func closeFullScreen() {
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
            navigationController?.setNavigationBarHidden(false, animated: true)
            self.isShowingSendButton = false
            self.navigationItem.title = NSLocalizedString("Transactions", comment: "Transactions nav bar heading")

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                self.fpc.surfaceView.cornerRadius = 0
                self.grabberHandle.frame = self.grabberRect(width: 0)
                self.grabberHandle.alpha = 0
                self.view.layoutIfNeeded()
            })
        } else {
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
        self.performSegue(withIdentifier: "HomeToSend", sender: nil)
    }

    // MARK: - TransactionTableDelegateMethods

    func onTransactionSelect(_ transaction: Transaction) {
        selectedTransaction = transaction
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
        if let identifier = segue.identifier {
            if identifier == "HomeToTransactionDetails" {
                let transactionVC = segue.destination as! TransactionViewController
                transactionVC.transaction = selectedTransaction
            }
        }
    }

    // MARK: - Floating panel setup delegate methods

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return HomeViewFloatingPanelLayout()
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
        let y = vc.surfaceView.frame.origin.y
        let tipY = vc.originYOfSurface(for: .tip)

        let progress = CGFloat(max(0.0, min((tipY  - y) / 44.0, 1.0)))

        if progress == 0.0 {
            return
        }

        //TODO figure out why corner radius can't animate out but can in
        self.fpc.surfaceView.cornerRadius = self.PANEL_BORDER_CORNER_RADIUS - (self.PANEL_BORDER_CORNER_RADIUS * progress)

        if fpc.position == .tip && !isTransactionViewFullScreen {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.sendButtonBottomConstraint.constant = (self.minSendButtonBottomConstraint) * progress
                self.view.layoutIfNeeded()
            })
        }
    }
}
