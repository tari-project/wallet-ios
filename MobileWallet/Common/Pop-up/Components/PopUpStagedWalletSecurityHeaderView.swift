//  PopUpStagedWalletSecurityHeaderView.swift

/*
	Package MobileWallet
	Created by Browncoat on 23/01/2023
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

final class PopUpStagedWalletSecurityHeaderView: DynamicThemeView {

    // MARK: - Subviews

    @TariView private var titleLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .Poppins.Medium.withSize(32.0)
        return view
    }()

    @TariView private var subtitleLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .Poppins.Medium.withSize(18.0)
        return view
    }()

    @TariView private var helpButton: BaseButton = {
        let view = BaseButton()
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 22.0)
        let image = UIImage(systemName: "questionmark.circle", withConfiguration: imageConfiguration)
        view.setImage(image, for: .normal)
        return view
    }()

    var onHelpButtonPress: (() -> Void)?

    // MARK: - Initialisers

    init(title: String, subtitle: String) {
        super.init()
        titleLabel.text = title
        subtitleLabel.text = subtitle
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [titleLabel, subtitleLabel, helpButton].forEach(addSubview)

        let buttonWidth: CGFloat = 34.0
        let margin: CGFloat = 4.0

        let constraints = [
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: buttonWidth + margin),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20.0),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            helpButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: margin),
            helpButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            helpButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            helpButton.heightAnchor.constraint(equalToConstant: buttonWidth),
            helpButton.widthAnchor.constraint(equalToConstant: buttonWidth)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        helpButton.onTap = { [weak self] in
            self?.onHelpButtonPress?()
        }
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        titleLabel.textColor = theme.text.heading
        subtitleLabel.textColor = theme.text.heading
        helpButton.tintColor = theme.text.body
    }
}
