//  SettingsProfileCell.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 15/03/2023
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

final class SettingsProfileCell: DynamicThemeCell {

    // MARK: - Subviews

    @View private var avatarView = RoundedAvatarView()

    @View private var nameLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(16.0)
        return view
    }()

    @View private var addressLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(17.0)
        return view
    }()

    @View private var centralContentView = UIView()

    @View private var scanImage: UIImageView = {
        let view = UIImageView()
        view.image = .Icons.General.QR
        view.contentMode = .scaleAspectFit
        return view
    }()

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [avatarView, centralContentView, scanImage].forEach(contentView.addSubview)
        [nameLabel, addressLabel].forEach(centralContentView.addSubview)

        let constraints = [
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30.0),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30.0),
            avatarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30.0),
            avatarView.heightAnchor.constraint(equalToConstant: 65.0),
            avatarView.widthAnchor.constraint(equalToConstant: 65.0),
            centralContentView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10.0),
            centralContentView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            nameLabel.topAnchor.constraint(equalTo: centralContentView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: centralContentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: centralContentView.trailingAnchor),
            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5.0),
            addressLabel.leadingAnchor.constraint(equalTo: centralContentView.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: centralContentView.trailingAnchor),
            addressLabel.bottomAnchor.constraint(equalTo: centralContentView.bottomAnchor),
            scanImage.leadingAnchor.constraint(equalTo: centralContentView.trailingAnchor, constant: 10.0),
            scanImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22.0),
            scanImage.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            scanImage.heightAnchor.constraint(equalToConstant: 30.0),
            scanImage.widthAnchor.constraint(equalToConstant: 30.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: Update

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        scanImage.tintColor = theme.icons.default
        nameLabel.textColor = theme.text.heading
        addressLabel.textColor = theme.text.heading
    }

    func update(avatar: String?, name: String?, address: String?) {
        avatarView.avatar = .text(avatar)
        nameLabel.text = name
        addressLabel.text = address
    }
}
