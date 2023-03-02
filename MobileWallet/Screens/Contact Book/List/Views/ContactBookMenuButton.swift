//  ContactBookMenuButton.swift

/*
	Package MobileWallet
	Created by Browncoat on 20/02/2023
	Using Swift 5.0
	Running on macOS 13.0

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

final class ContactBookMenuButton: DynamicThemeView {

    // MARK: - Subviews

    @View private var button = RoundedButton()

    // MARK: - Properties

    var image: UIImage? {
        get { button.image(for: .normal) }
        set { button.setImage(newValue, for: .normal) }
    }

    var onTap: (() -> Void)?

    private var buttonCollapsedSizeConstraints: [NSLayoutConstraint] = []
    private var buttonExpandedSizeConstraints: [NSLayoutConstraint] = []

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

        addSubview(button)

        buttonCollapsedSizeConstraints = [
            button.widthAnchor.constraint(equalToConstant: 0.0),
            button.heightAnchor.constraint(equalToConstant: 0.0)
        ]

        buttonExpandedSizeConstraints = [
            button.widthAnchor.constraint(equalTo: widthAnchor),
            button.heightAnchor.constraint(equalTo: heightAnchor)
        ]

        let constraints = [
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints + buttonCollapsedSizeConstraints)
    }

    private func setupCallbacks() {
        button.onTap = { [weak self] in self?.onTap?() }
    }

    // MARK: - Actions

    func show() {
        NSLayoutConstraint.deactivate(buttonCollapsedSizeConstraints)
        NSLayoutConstraint.activate(buttonExpandedSizeConstraints)
    }

    func hide() {
        NSLayoutConstraint.deactivate(buttonExpandedSizeConstraints)
        NSLayoutConstraint.activate(buttonCollapsedSizeConstraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        button.backgroundColor = theme.backgrounds.primary?.withAlphaComponent(0.15)
        button.tintColor = theme.buttons.primaryText
    }
}
