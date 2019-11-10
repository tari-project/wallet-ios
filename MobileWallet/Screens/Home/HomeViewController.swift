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
    @IBOutlet weak var sendButton: UIButton!

    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var balanceValueLabel: UILabel!

    private var fpc: FloatingPanelController!
    private var selectedTransaction: Transaction?

    override func viewDidLoad() {
        setup()
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        //updateBalance()
    }

    private func setup() {
        view.backgroundColor = Theme.shared.colors.homeBackground

        sendButton.setTitle(NSLocalizedString("Send Tari", comment: "Floating send Tari button on home screen"), for: .normal)

        balanceLabel.text = NSLocalizedString("Total Balance", comment: "Home screen balance label")
        balanceLabel.font = Theme.shared.fonts.homeScreenTotalBalanceLabel
        balanceLabel.textColor = Theme.shared.colors.homeScreenTotalBalanceLabel
        balanceValueLabel.font = Theme.shared.fonts.homeScreenTotalBalanceValueLabel
        balanceValueLabel.textColor = Theme.shared.colors.homeScreenTotalBalanceValueLabel
        balanceValueLabel.minimumScaleFactor = 0.5
        balanceValueLabel.adjustsFontSizeToFitWidth = true

       // print(balanceValueLabel.layoutMarginsGuide)

        print("'\(dummyBalance.displayStringWithNegativeOperator)'")
        print("'30 818,50'")
        balanceValueLabel.text = dummyBalance.displayStringWithNegativeOperator // "30 818,50" //"\(dummyBalance.displayStringWithNegativeOperator)" // "Fuck fuck fuck fuck fuck" //dummyBalance.displayStringWithNegativeOperator

       // print(balanceValueLabel.layoutMarginsGuide)

        setupFloatingPanel()
        setupNavigatorBar()
        showFloatingPanel()
    }

//    private func updateBalance() {
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
//            self.balanceValueLabel.text = dummyBalance.displayStringWithNegativeOperator
//            self.balanceValueLabel.layoutIfNeeded()
//        })
//
//    }

    private func setupNavigatorBar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)

        if let navBar = navigationController?.navigationBar {
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
        let transactionTableVC = TransactionsTableViewController()
        transactionTableVC.actionDelegate = self

        fpc.set(contentViewController: transactionTableVC)

        //TODO move custom styling setup into generic function
        fpc.surfaceView.cornerRadius = 36
        fpc.surfaceView.shadowColor = .black
        fpc.surfaceView.shadowRadius = 22

        // Track a scroll view(or the siblings) in the content view controller.
        fpc.track(scrollView: transactionTableVC.tableView)
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

            //TODO Show search bar
        } else {
            //TODO Hide search bar
        }
    }
}
