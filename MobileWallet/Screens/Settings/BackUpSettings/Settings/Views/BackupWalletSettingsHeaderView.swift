//  BackupWalletSettingsHeaderView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 27/10/2022
	Using Swift 5.0
	Running on macOS 12.6

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

final class BackupWalletSettingsHeaderView: DynamicThemeView {

    @TariView private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.settingsViewHeader
        view.text = localized("backup_wallet_settings.header.title")
        return view
    }()

    @TariView private var descriptionLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = Theme.shared.fonts.settingsSeedPhraseDescription
        view.text = String(format: localized("backup_wallet_settings.header.description"), NetworkManager.shared.currencySymbol)
        return view
    }()

    override init() {
        super.init()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {

        [titleLabel, descriptionLabel].forEach { addSubview($0) }

        let constraints = [
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30.0),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15.0),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -25.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        titleLabel.textColor = theme.text.heading
        descriptionLabel.textColor = theme.text.body
    }
}
