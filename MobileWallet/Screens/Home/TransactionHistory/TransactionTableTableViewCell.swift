//  TransactionTableTableViewCell.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/10/31
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

class TransactionTableTableViewCell: UITableViewCell {
    private let BACKGROUND_COLOR = Theme.shared.colors.transactionTableBackground

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        viewSetup()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        contentView.backgroundColor = BACKGROUND_COLOR
    }

    private func viewSetup() {
        backgroundColor = BACKGROUND_COLOR

        valueLabel.font = Theme.shared.fonts.transactionCellValueLabel
        valueLabel.layer.cornerRadius = 3
        valueLabel.layer.masksToBounds = true

        userNameLabel.font = Theme.shared.fonts.transactionCellUsernameLabel
        userNameLabel.textColor = Theme.shared.colors.transactionCellUsername

        descriptionLabel.font = Theme.shared.fonts.transactionCellDescriptionLabel
        descriptionLabel.textColor = Theme.shared.colors.transactionCellDescription

        selectionStyle = .none
    }

    func setValueLabel(value: Int) {
        if value > 0 {
            valueLabel.backgroundColor = Theme.shared.colors.transactionCellValuePositiveBackground
            valueLabel.textColor = Theme.shared.colors.transactionCellValuePositiveText
            valueLabel.text = "+ \(value)"
        } else {
            valueLabel.backgroundColor = Theme.shared.colors.transactionCellValueNegativeBackground
            valueLabel.textColor = Theme.shared.colors.transactionCellValueNegativeText
            valueLabel.text = "- \(value * -1)"
        }

        valueLabel.padding = UIEdgeInsets(top: 6, left: 6, bottom: 4, right: 6)
    }
}
