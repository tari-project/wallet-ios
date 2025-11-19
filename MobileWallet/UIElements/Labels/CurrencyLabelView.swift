//  CurrencyLabelView.swift

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

final class CurrencyLabelView: UIView {

    // MARK: - Subviews

    @TariView private var currencyIcon: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.currencySymbol
        view.contentMode = .scaleAspectFit
        return view
    }()

    @TariView private var label: UILabel = {
        let view = UILabel()
        view.numberOfLines = 1
        view.setContentHuggingPriority(.required, for: .vertical)
        view.adjustsFontSizeToFitWidth = true
        return view
    }()

    // MARK: - Properties

    var text: String? {
        didSet { updateLabel() }
    }

    var textColor: UIColor? {
        get { label.textColor }
        set {
            label.textColor = newValue
            currencyIcon.tintColor = newValue
        }
    }

    var font: UIFont? {
        didSet { updateLabel() }
    }

    var secondaryFont: UIFont? {
        didSet { updateLabel() }
    }

    var separator: String? {
        didSet { updateLabel() }
    }

    var iconHeight: CGFloat? {
        didSet { updateIconHeight() }
    }

    var defaultCurrencyIconHeightConstraint: NSLayoutConstraint?
    var definedCurrencyIconHeightConstraint: NSLayoutConstraint?

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [currencyIcon, label].forEach(addSubview)

        let defaultCurrencyIconHeightConstraint = currencyIcon.heightAnchor.constraint(equalTo: label.heightAnchor)
        self.defaultCurrencyIconHeightConstraint = defaultCurrencyIconHeightConstraint
        definedCurrencyIconHeightConstraint = currencyIcon.heightAnchor.constraint(equalToConstant: 0.0)

        let constraints = [
            currencyIcon.leadingAnchor.constraint(equalTo: leadingAnchor),
            currencyIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            defaultCurrencyIconHeightConstraint,
            currencyIcon.widthAnchor.constraint(equalTo: currencyIcon.heightAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: currencyIcon.trailingAnchor, constant: 6.0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    private func updateIconHeight() {
        guard let iconHeight = iconHeight else {
            definedCurrencyIconHeightConstraint?.isActive = false
            defaultCurrencyIconHeightConstraint?.isActive = true
            return
        }

        defaultCurrencyIconHeightConstraint?.isActive = false
        definedCurrencyIconHeightConstraint?.constant = iconHeight
        definedCurrencyIconHeightConstraint?.isActive = true
    }

    private func updateLabel() {

        guard let text = text, let font = font, let secondaryFont = secondaryFont, let separator = separator, let index = text.firstIndex(where: { String($0) == separator }) else {
            label.text = text
            label.font = font
            return
        }

        label.font = font

        let range = index..<text.endIndex
        let attributedRange = NSRange(range, in: text)

        let attributedString = NSMutableAttributedString(string: text)

        attributedString.addAttributes(
            [
                .font: secondaryFont,
                .baselineOffset: font.capHeight - secondaryFont.capHeight
            ],
            range: attributedRange
        )

        label.attributedText = attributedString
    }
}
