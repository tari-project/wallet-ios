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

protocol TransactionSelectedDelegate {
    func onTransactionSelect(_: Transaction)
}

class HomeViewController: UIViewController, FloatingPanelControllerDelegate, TransactionSelectedDelegate {
    @IBOutlet weak var sendButton: SendButton!
    @IBOutlet weak var sendButtonBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var balanceValueLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var valueIcon: UIImageView!

    private var fpc: FloatingPanelController!
    private var selectedTransaction: Transaction?
    private var maxSendButtonBottomConstraint: CGFloat = 50
    private var minSendButtonBottomConstraint: CGFloat = -20
    private var isAnimatingButton = false
    private var hapticEnabled = false

    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    override func viewDidLoad() {
        setup()
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.sendButtonBottomConstraint.constant = self.minSendButtonBottomConstraint
        super.viewWillAppear(animated)
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
    }

    private func setupNavigatorBar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)

        if let navController = navigationController {
            let navBar = navController.navigationBar
//            navController.setNavigationBarHidden(true, animated: false)

            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()

            navBar.tintColor = Theme.shared.colors.navigationBarTint

            navBar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.navigationBarTint!,
                NSAttributedString.Key.font: Theme.shared.fonts.navigationBarTitle!
            ]

            let backImage = UIImage(systemName: "arrow.left") //TODO use own asset when available
            navBar.backIndicatorImage = backImage
            navBar.backIndicatorTransitionMaskImage = backImage
        }
    }

    private func setupFloatingPanel() {
        fpc = FloatingPanelController()

        fpc.delegate = self
        let transactionTableVC = TransactionsTableViewController(style: .grouped)
        transactionTableVC.actionDelegate = self

        fpc.set(contentViewController: transactionTableVC)

        //TODO move custom styling setup into generic function
        fpc.surfaceView.cornerRadius = 36
        fpc.surfaceView.shadowColor = .black
        fpc.surfaceView.shadowRadius = 22

        setGrabber(fpc)

        fpc.contentMode = .fitToBounds

        // Track a scroll view(or the siblings) in the content view controller.
        fpc.track(scrollView: transactionTableVC.tableView)
    }

    private func setGrabber(_ fpc: FloatingPanelController) {
        let grabberWidth = 55.0
        let grabberHandel: UIView = UIView.init(
            frame: CGRect(
                x: Double(self.view.frame.size.width) / 2 - grabberWidth / 2,
                y: 20,
                width: grabberWidth,
                height: 5)
            )
        grabberHandel.layer.cornerRadius = 2.5
        grabberHandel.backgroundColor = Theme.shared.colors.floatingPanelGrabber
        fpc.surfaceView.grabberHandle.isHidden = true
        fpc.surfaceView.addSubview(grabberHandel)
    }

    private func showFloatingPanel() {
        view.addSubview(fpc.view)
        fpc.view.frame = view.bounds
        addChild(fpc)

        //Move send button to in front of panel
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
        print("Send")
    }

    // MARK: - Navigation

    func onTransactionSelect(_ transaction: Transaction) {
        selectedTransaction = transaction
        self.performSegue(withIdentifier: "HomeToTransactionDetails", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let transactionVC = segue.destination as! TransactionViewController
        transactionVC.transaction = selectedTransaction
    }

    // MARK: - Floating panel setup delegate methods

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return HomeViewFloatingPanelLayout()
    }

    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return HomeViewFloatingPanelBehavior()
    }

    func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
        if vc.position == .full {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.sendButtonBottomConstraint.constant = self.minSendButtonBottomConstraint
                self.view.layoutIfNeeded()
            }, completion: { (_) in
            })
        } else if vc.position == .tip || vc.position == .half {
            if hapticEnabled {
                self.impactFeedbackGenerator.impactOccurred()
            }
            hapticEnabled = true

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                self.sendButtonBottomConstraint.constant = self.maxSendButtonBottomConstraint
                self.view.layoutIfNeeded()
            }, completion: { (_) in

            })
        }
    }

    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        self.impactFeedbackGenerator.prepare()

        let y = vc.surfaceView.frame.origin.y
        let tipY = vc.originYOfSurface(for: .tip)

        let progress = CGFloat(max(0.0, min((tipY  - y) / 44.0, 1.0)))

        if progress == 0.0 {
            return
        }

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
            self.sendButtonBottomConstraint.constant = (self.minSendButtonBottomConstraint) * progress
            self.view.layoutIfNeeded()
        })
    }
}
