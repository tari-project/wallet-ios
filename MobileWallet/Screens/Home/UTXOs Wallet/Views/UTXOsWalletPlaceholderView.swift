//  UTXOsWalletPlaceholderView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 05/07/2022
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

final class UTXOsWalletPlaceholderView: DynamicThemeView {

    // MARK: - Subviews

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 10.0
        return view
    }()

    @View private var imageView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.utxoWalletPlaceholder?.withRenderingMode(.alwaysTemplate)
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("utxos_wallet.placeholder.label.title")
        view.textAlignment = .center
        view.font = .Avenir.light.withSize(18.0)
        return view
    }()

    @View private var subtitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("utxos_wallet.placeholder.label.subtitle")
        view.textAlignment = .center
        view.font = .Avenir.medium.withSize(14.0)
        view.numberOfLines = 0
        return view
    }()

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

        addSubview(stackView)
        [imageView, titleLabel, subtitleLabel].forEach(stackView.addArrangedSubview)

        let constraints = [
            imageView.heightAnchor.constraint(equalToConstant: 120.0),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.67),
            stackView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.67)

        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        imageView.tintColor = theme.text.body
        titleLabel.textColor = theme.text.heading
        subtitleLabel.textColor = theme.text.body
    }
}
