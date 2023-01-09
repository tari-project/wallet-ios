//  TransactionsToolbarView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 13/01/2022
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

import UIKit
import TariCommon

final class TransactionsToolbarView: DynamicThemeView {

    // MARK: - Subviews

    @View private var sendButton: BaseButton = {
        let view = BaseButton()
        view.setTitle(localized("transactions.toolbar.send"), for: .normal)
        view.titleLabel?.font = UIFont.Avenir.medium.withSize(16.0)
        return view
    }()

    @View private var requestButton: BaseButton = {
        let view = BaseButton()
        view.setTitle(localized("transactions.toolbar.request"), for: .normal)
        view.titleLabel?.font = UIFont.Avenir.medium.withSize(16.0)
        return view
    }()

    @View private var selectorLineView = UIView()

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .fillEqually
        view.alignment = .fill
        return view
    }()

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        sendButton.setTitleColor(theme.text.heading, for: .normal)
        requestButton.setTitleColor(theme.text.heading, for: .normal)
        selectorLineView.backgroundColor = theme.brand.purple
    }

    // MARK: - Properties

    var onButtonTap: ((_ index: Int) -> Void)?

    var indexPosition: CGFloat = 0.0 {
        didSet { update(indexPosition: indexPosition) }
    }

    private var selectorLineCenterXConstraint: NSLayoutConstraint?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [stackView, selectorLineView].forEach(addSubview)
        [sendButton, requestButton].forEach(stackView.addArrangedSubview)

        let selectorLineCenterXConstraint = selectorLineView.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor)
        self.selectorLineCenterXConstraint = selectorLineCenterXConstraint

        let constraints = [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            selectorLineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            selectorLineView.widthAnchor.constraint(equalTo: sendButton.widthAnchor, constant: -24.0),
            selectorLineView.heightAnchor.constraint(equalToConstant: 3.0),
            selectorLineCenterXConstraint
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        [sendButton, requestButton]
            .enumerated()
            .forEach { index, button in
                button.onTap = { [weak self] in self?.onButtonTap?(index) }
            }
    }

    // MARK: - Update

    private func update(indexPosition: CGFloat) {
        guard let firstButton = stackView.arrangedSubviews.first else { return }
        selectorLineCenterXConstraint?.constant = indexPosition * firstButton.bounds.width
    }
}
