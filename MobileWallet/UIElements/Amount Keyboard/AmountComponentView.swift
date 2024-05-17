//  AmountComponentView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 03/04/2024
	Using Swift 5.0
	Running on macOS 14.4

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

import TariCommon

final class AmountComponentView: DynamicThemeView {

    // MARK: - Subviews

    @View private var amountLabel: AnimatedBalanceLabel = {
        let view = AnimatedBalanceLabel()
        view.animation = .type
        view.textAlignment = .center(inset: -30)
        return view
    }()

    @View private var keyboard: AmountKeyboardView = {
        let view = AmountKeyboardView()
        view.setup(keys: .amountKeyboard)
        return view
    }()

    @View private var amountContentView = UIView()
    @View private var keyboardContentView = UIView()

    // MARK: - Properties

    var amount: String = "0" {
        didSet { update(amount: amount) }
    }

    var onKeyTap: ((AmountKeyboardView.Key) -> Void)?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
        setupCallbacks()
        update(amount: amount)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [amountContentView, keyboardContentView].forEach(addSubview)
        amountContentView.addSubview(amountLabel)
        keyboardContentView.addSubview(keyboard)

        var constraints = [
            amountContentView.topAnchor.constraint(equalTo: topAnchor),
            amountContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            amountContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyboardContentView.topAnchor.constraint(equalTo: amountContentView.bottomAnchor),
            keyboardContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyboardContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyboardContentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        let amountContainnterConstraints = [
            amountLabel.leadingAnchor.constraint(equalTo: amountContentView.leadingAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: amountContentView.trailingAnchor),
            amountLabel.centerYAnchor.constraint(equalTo: amountContentView.centerYAnchor)
        ]

        let keyboardBottomConstraint: NSLayoutConstraint

        if UIDevice.current.userInterfaceIdiom == .pad {
            keyboardBottomConstraint = keyboard.bottomAnchor.constraint(equalTo: keyboardContentView.bottomAnchor)
        } else {
            let amountContentViewHeightConstraint = amountContentView.heightAnchor.constraint(equalToConstant: 220.0)
            amountContentViewHeightConstraint.priority = .defaultLow
            constraints.append(amountContentViewHeightConstraint)
            keyboardBottomConstraint = keyboard.bottomAnchor.constraint(lessThanOrEqualTo: keyboardContentView.bottomAnchor)
        }

        let keyboardContainterConstraints = [
            keyboard.topAnchor.constraint(equalTo: keyboardContentView.topAnchor),
            keyboard.leadingAnchor.constraint(equalTo: keyboardContentView.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: keyboardContentView.trailingAnchor),
            keyboardBottomConstraint
        ]

        NSLayoutConstraint.activate(constraints + amountContainnterConstraints + keyboardContainterConstraints)
    }

    private func setupCallbacks() {
        keyboard.onKeyTap = { [weak self] in
            self?.onKeyTap?($0)
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        updateAmountLabelColor(theme: theme)
    }

    private func updateAmountLabelColor(theme: ColorTheme) {

        guard let attributedText = amountLabel.attributedText, let color = theme.text.heading else { return }

        let amountText = NSMutableAttributedString(attributedString: attributedText)
        amountText.addAttributes([.foregroundColor: color], range: NSRange(location: 0, length: amountText.length))

        amountLabel.attributedText = amountText
    }

    private func update(amount: String) {
        amountLabel.attributedText = NSAttributedString(amount: amount)
        updateAmountLabelColor(theme: theme)
    }
}
