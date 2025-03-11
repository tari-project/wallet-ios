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

    @View private var nameLabel: UILabel = {
        let view = UILabel()
        view.font = .Poppins.Medium.withSize(16.0)
        return view
    }()

    @View private var addressView = AddressView()

    @View private var arrowView: UIImageView = {
        let view = UIImageView()
        view.image = .Icons.General.cellArrow
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

        [nameLabel, addressView, arrowView].forEach(contentView.addSubview)

        let constraints = [
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30.0),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25.0),
            addressView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5.0),
            addressView.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            addressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30.0),
            arrowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25.0),
            arrowView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: Update

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        nameLabel.textColor = theme.text.heading
        arrowView.tintColor = theme.text.heading
    }

    func update(name: String?, addressViewModel: AddressView.ViewModel) {
        nameLabel.text = name
        addressView.update(viewModel: addressViewModel)
    }
}
