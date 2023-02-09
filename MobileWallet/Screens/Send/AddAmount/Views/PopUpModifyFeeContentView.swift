//  PopUpModifyFeeContentView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 20/05/2022
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

final class PopUpModifyFeeContentView: DynamicThemeView {

    // MARK: - Subviews

    @View private(set) var segmentedControl = TariSegmentedControl(icons: [Theme.shared.images.speedometerLow, Theme.shared.images.speedometerMid, Theme.shared.images.speedometerHigh])

    @View private var estimatedFeeTitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("add_amount.pop_up.adjust_fee.label.estimated_fee")
        view.textAlignment = .center
        view.font = .Avenir.medium.withSize(14.0)
        return view
    }()

    @View private var estimatedFeeValueLabel: CurrencyLabelView = {
        let view = CurrencyLabelView()
        view.font = .Avenir.medium.withSize(26.0)
        view.iconHeight = 13.0
        return view
    }()

    // MARK: - Properties

    var estimatedFee: String? {
        get { estimatedFeeValueLabel.text }
        set { estimatedFeeValueLabel.text = newValue }
    }

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

        [segmentedControl, estimatedFeeTitleLabel, estimatedFeeValueLabel].forEach(addSubview)

        let constraints = [
            segmentedControl.topAnchor.constraint(equalTo: topAnchor),
            segmentedControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            estimatedFeeTitleLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 21.0),
            estimatedFeeTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            estimatedFeeTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            estimatedFeeValueLabel.topAnchor.constraint(equalTo: estimatedFeeTitleLabel.bottomAnchor),
            estimatedFeeValueLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            estimatedFeeValueLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        estimatedFeeTitleLabel.textColor = theme.text.heading
        estimatedFeeValueLabel.textColor = theme.text.heading
    }
}
