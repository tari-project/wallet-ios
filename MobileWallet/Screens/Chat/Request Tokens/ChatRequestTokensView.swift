//  ChatRequestTokensView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 28/03/2024
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

final class ChatRequestTokensView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var amountComponentView = AmountComponentView()

    @View private var continueButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("chat.request_tokens.buttons.continue"), for: .normal)
        return view
    }()

    // MARK: - Properties

    var amount: String {
        get { amountComponentView.amount }
        set { amountComponentView.amount = newValue }
    }

    var isContinueButtonEnabled: Bool = false {
        didSet { continueButton.variation = isContinueButtonEnabled ? .normal : .disabled }
    }

    var onKeyTap: ((AmountKeyboardView.Key) -> Void)? {
        get { amountComponentView.onKeyTap }
        set { amountComponentView.onKeyTap = newValue }
    }

    var onContinueButtonTap: (() -> Void)? {
        get { continueButton.onTap }
        set { continueButton.onTap = newValue }
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
        navigationBar.title = localized("chat.request_tokens.title")
    }

    private func setupConstraints() {

        [amountComponentView, continueButton].forEach(addSubview)

        let constraints = [
            amountComponentView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            amountComponentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            amountComponentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            continueButton.topAnchor.constraint(equalTo: amountComponentView.bottomAnchor),
            continueButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            continueButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            continueButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -25.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
