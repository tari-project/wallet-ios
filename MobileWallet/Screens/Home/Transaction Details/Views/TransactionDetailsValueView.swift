//  TransactionDetailsValueView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 16/03/2022
	Using Swift 5.0
	Running on macOS 12.3

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
import TariCommon

final class TransactionDetailsValueView: DynamicThemeView {

    // MARK: - Subviews

    @TariView private var currencyImageView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.currencySymbol
        view.contentMode = .scaleAspectFit
        return view
    }()

    @TariView private(set) var valueLabel: UILabel = {
        let view = UILabel()
        view.minimumScaleFactor = 0.2
        view.font = Theme.shared.fonts.txScreenCurrencyValueLabel
        view.adjustsFontSizeToFitWidth = true
        return view
    }()

    @TariView private var feeLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.txFeeLabel
        return view
    }()

    @TariView private(set) var feeButton: TextButton = {
        let view = TextButton()
        view.setTitle(localized("common.fee"), for: .normal)
        view.font = .Poppins.SemiBold.withSize(13.0)
        view.image = .Icons.General.roundedQuestionMark
        return view
    }()

    var fee: String? {
        didSet { updateFeeElements() }
    }

    // MARK: - Properties

    private var valueLabelBottomConstraint: NSLayoutConstraint?
    private var feeButtonBottomConstraint: NSLayoutConstraint?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        let feeButtonBottomConstraint = feeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30.0)
        self.feeButtonBottomConstraint = feeButtonBottomConstraint
        valueLabelBottomConstraint = valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30.0)

        [currencyImageView, valueLabel, feeLabel, feeButton].forEach(addSubview)

        let constraints = [
            currencyImageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 22.0),
            currencyImageView.widthAnchor.constraint(equalToConstant: 21.0),
            currencyImageView.heightAnchor.constraint(equalToConstant: 21.0),
            currencyImageView.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            valueLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30.0),
            valueLabel.leadingAnchor.constraint(equalTo: currencyImageView.trailingAnchor, constant: 11.0),
            valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -22.0),
            valueLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            feeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            feeLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor),
            feeButton.topAnchor.constraint(equalTo: feeLabel.bottomAnchor),
            feeButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            feeButtonBottomConstraint
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
        currencyImageView.tintColor = theme.icons.default
        valueLabel.textColor = theme.text.heading
        feeLabel.textColor = theme.text.heading
    }

    private func updateFeeElements() {
        feeLabel.text = fee

        let isFeeVisible = fee != nil

        feeLabel.isHidden = !isFeeVisible
        feeButton.isHidden = !isFeeVisible

        if isFeeVisible {
            valueLabelBottomConstraint?.isActive = false
            feeButtonBottomConstraint?.isActive = true
        } else {
            feeButtonBottomConstraint?.isActive = false
            valueLabelBottomConstraint?.isActive = true
        }
    }
}
