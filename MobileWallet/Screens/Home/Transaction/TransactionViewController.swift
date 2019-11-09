//  TransactionViewController.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/07
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

class TransactionViewController: UIViewController {
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var currencySymbol: UIImageView!

    var transaction: Transaction?

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        setValues()
    }

    private func setup() {
        view.backgroundColor = Theme.shared.colors.appBackground

        setupHeader()
        setupValueView()
    }

    private func setupHeader() {
        if let navBar = navigationController?.navigationBar {
            let backImage = UIImage(systemName: "arrow.left") //TODO use own asset when available
            navBar.backIndicatorImage = backImage
            navBar.backIndicatorTransitionMaskImage = backImage
            navBar.tintColor = Theme.shared.colors.navigationBarTintColor
        }
    }

    private func setupValueView() {
        let labelColor = Theme.shared.colors.transactionViewValueLabelColor

        valueLabel.minimumScaleFactor = 0.2
        valueLabel.font = Theme.shared.fonts.transactionScreenValueLabel
        valueLabel.textColor = labelColor

        currencySymbol.image = Theme.shared.icons.currencySymbol?.withTintColor(labelColor!)
    }

    private func setValues() {
        if let tx = transaction {
            self.valueLabel.text = tx.value.displayStringWithNegativeOperator

            var title: String?

            if tx.value.sign == .positive {
                title = NSLocalizedString("Payment Received", comment: "Navigation bar heading on transaction view screen")
            } else {
                title = NSLocalizedString("Payment Sent", comment: "Navigation bar heading on transaction view screen")
            }

            navigationItem.title = title
        }
    }
}
