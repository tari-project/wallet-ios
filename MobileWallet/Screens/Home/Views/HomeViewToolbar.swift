//  HomeViewToolbar.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 06/08/2021
	Using Swift 5.0
	Running on macOS 12.0

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

final class HomeViewToolbar: DynamicThemeView {

    var onOnCloseButtonTap: (() -> Void)?

    private let titleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("tx_list.title")
        view.font = Theme.shared.fonts.navigationBarTitle
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let closeButton: UIButton = {
        let view = UIButton()
        view.setImage(Theme.shared.images.close, for: .normal)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initializers

    override init() {
        super.init()
        setupConstraints()
        setupFeedbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [titleLabel, closeButton].forEach(addSubview)

        let constraints = [
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20.0),
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14.0),
            closeButton.heightAnchor.constraint(equalToConstant: 25.0),
            closeButton.widthAnchor.constraint(equalToConstant: 25.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupFeedbacks() {
        closeButton.addTarget(self, action: #selector(onCloseButtonTapAction), for: .touchUpInside)
    }
    
    // MARK: - Updates
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        titleLabel.textColor = theme.text.heading
        closeButton.tintColor = theme.icons.default
        apply(shadow: theme.shadows.box)
    }

    // MARK: - Target - Actions

    @objc private func onCloseButtonTapAction() {
        onOnCloseButtonTap?()
    }
}
