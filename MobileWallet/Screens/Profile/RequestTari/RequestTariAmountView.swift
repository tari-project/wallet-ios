//  RequestTariAmountView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 14/01/2022
	Using Swift 5.0
	Running on macOS 12.1

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

final class RequestTariAmountView: DynamicThemeView {

    // MARK: - Subviews

    @View private var amountComponentView: AmountComponentView = AmountComponentView()

    @View var generateQrButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("request.buttons.generate_qr"), for: .normal)
        return view
    }()

    @View var shareButton: ActionButton = {
        let view = ActionButton()
        view.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        return view
    }()

    var onKeyboardKeyTap: ((AmountKeyboardView.Key) -> Void)? {
        get { amountComponentView.onKeyTap }
        set { amountComponentView.onKeyTap = newValue }
    }

    // MARK: - Properties

    var amount: String = "0" {
        didSet { update(amount: amount) }
    }

    var areButtonsEnabled: Bool = false {
        didSet {
            generateQrButton.isEnabled = areButtonsEnabled
            shareButton.isEnabled = areButtonsEnabled
        }
    }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        update(amount: "0")
        areButtonsEnabled = false
    }

    private func setupConstraints() {

        [amountComponentView, generateQrButton, shareButton].forEach(addSubview)

        let constraints = [
            amountComponentView.topAnchor.constraint(equalTo: topAnchor),
            amountComponentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            amountComponentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            generateQrButton.topAnchor.constraint(equalTo: amountComponentView.bottomAnchor, constant: 12.0),
            generateQrButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            generateQrButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -25.0),
            shareButton.topAnchor.constraint(equalTo: generateQrButton.topAnchor),
            shareButton.leadingAnchor.constraint(equalTo: generateQrButton.trailingAnchor, constant: 15.0),
            shareButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            shareButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -25.0),
            shareButton.widthAnchor.constraint(equalTo: shareButton.heightAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
    }

    private func update(amount: String) {
        amountComponentView.amount = amount
    }
}
