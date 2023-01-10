//  PopUpButtonsView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 10/04/2022
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

final class PopUpButtonsView: UIView {

    // MARK: - Subviews

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 13.0
        return view
    }()

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

        addSubview(stackView)

        let constraints = [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions

    func addButton(model: PopUpDialogButtonModel) {

        let button: BaseButton

        switch model.type {
        case .normal:
            let actionButton = ActionButton()
            actionButton.setImage(model.icon, for: .normal)
            button = actionButton
        case .destructive:
            let actionButton = ActionButton()
            actionButton.variation = .destructive
            actionButton.setImage(model.icon, for: .normal)
            button = actionButton
        case .text:
            let textButton = TextButton()
            textButton.setVariation(.secondary)
            textButton.setRightImage(model.icon)
            button = textButton
        case .textDimmed:
            let textButton = TextButton()
            textButton.setVariation(.primary)
            textButton.setRightImage(model.icon)
            button = textButton
        }

        button.setTitle(model.title, for: .normal)
        button.onTap = model.callback

        stackView.addArrangedSubview(button)
    }
}
