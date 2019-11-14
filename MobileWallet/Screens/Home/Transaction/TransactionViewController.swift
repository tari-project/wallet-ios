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
    @IBOutlet weak var valueContainerView: UIView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var currencySymbol: UIImageView!
    @IBOutlet weak var detailsStackView: UIStackView!

    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var fromUserNameLabel: UILabel!
    @IBOutlet weak var fromUserIdLabel: UILabel!

    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var noteValueLabel: UILabel!
    @IBOutlet weak var transactionIcon: UIImageView!

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dateValueLabel: UILabel!

    @IBOutlet weak var transactionFeeLabel: UILabel!
    @IBOutlet weak var transactionFeeValueLabel: UILabel!

    @IBOutlet weak var transactionIdLabel: UILabel!

    var transaction: Transaction?

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        createBorders()
    }

    private func setup() {
        view.backgroundColor = Theme.shared.colors.appBackground

        fromLabel.text = NSLocalizedString("From", comment: "Transaction detail screen")
        fromLabel.font = Theme.shared.fonts.transactionScreenSubheadingLabel
        fromLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
        fromUserNameLabel.font = Theme.shared.fonts.transactionScreenTextLabel
        fromUserNameLabel.textColor = Theme.shared.colors.transactionScreenTextLabel

        noteLabel.text = NSLocalizedString("Note", comment: "Transaction detail screen")
        noteLabel.font = Theme.shared.fonts.transactionScreenSubheadingLabel
        noteLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
        noteValueLabel.font = Theme.shared.fonts.transactionScreenTextLabel
        noteValueLabel.textColor = Theme.shared.colors.transactionScreenTextLabel

        dateLabel.text = NSLocalizedString("Date and Time", comment: "Transaction detail screen")
        dateLabel.font = Theme.shared.fonts.transactionScreenSubheadingLabel
        dateLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
        dateValueLabel.font = Theme.shared.fonts.transactionScreenTextLabel
        dateValueLabel.textColor = Theme.shared.colors.transactionScreenTextLabel

        transactionFeeLabel.text = NSLocalizedString("Transaction Fee", comment: "Transaction detail screen")
        transactionFeeLabel.font = Theme.shared.fonts.transactionScreenSubheadingLabel
        transactionFeeLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
        transactionFeeValueLabel.font = Theme.shared.fonts.transactionScreenTextLabel
        transactionFeeValueLabel.textColor = Theme.shared.colors.transactionScreenTextLabel

        transactionIdLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
        transactionIdLabel.font = Theme.shared.fonts.transactionScreenTxIDLabel

        for view in self.detailsStackView.subviews {
            view.backgroundColor = Theme.shared.colors.appBackground
        }

        setupValueView()
        setValues()
    }

    private func createBorders() {
        for view in self.detailsStackView.subviews {
            view.layer.addBorder(edge: .bottom, color: Theme.shared.colors.transactionScreenDivider!, thickness: 1.0)
        }
    }

    private func setupValueView() {
        let labelColor = Theme.shared.colors.transactionViewValueLabel

        valueLabel.minimumScaleFactor = 0.2
        valueLabel.font = Theme.shared.fonts.transactionScreenCurrencyValueLabel
        valueLabel.textColor = labelColor

        currencySymbol.image = Theme.shared.icons.currencySymbol?.withTintColor(labelColor!)

        valueContainerView.backgroundColor = Theme.shared.colors.transactionViewValueContainer
    }

    private func setValues() {
        if let tx = transaction {
            var title: String?

            if tx.value.sign == .positive {
                title = NSLocalizedString("Payment Received", comment: "Navigation bar heading on transaction view screen")
            } else {
                title = NSLocalizedString("Payment Sent", comment: "Navigation bar heading on transaction view screen")
            }

            navigationItem.title = title

            valueLabel.text = tx.value.displayStringWithNegativeOperator
            fromUserNameLabel.text = tx.userName
            fromUserIdLabel.text = tx.userId
            noteValueLabel.text = tx.description
            transactionIcon.image = tx.icon
            dateValueLabel.text = tx.date.locallyFormattedDisplay()
            transactionFeeValueLabel.text = tx.fee.displayStringWithNegativeOperator

            let txLabelText = NSLocalizedString("Transaction ID:", comment: "Transaction view screen")
            transactionIdLabel.text = "\(txLabelText) \(tx.id)"
        }
    }
}
