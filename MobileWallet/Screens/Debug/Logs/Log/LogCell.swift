//  LogCell.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 17/10/2022
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

final class LogCell: DynamicThemeCell {

    // MARK: - Subviews

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = .Poppins.Medium.withSize(14.0)
        view.numberOfLines = 0
        return view
    }()

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
    }

    private func setupConstraints() {

        contentView.addSubview(label)

        let constraints = [
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.0),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.body
    }

    func update(text: String) {
        label.text = text
    }
}
