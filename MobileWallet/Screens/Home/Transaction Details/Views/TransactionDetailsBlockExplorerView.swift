//  TransactionDetailsBlockExplorerView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 24/03/2022
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

final class TransactionDetailsBlockExplorerView: DynamicThemeBaseButton {

    // MARK: - Subviews

    @TariView private var label: UILabel = {
        let view = UILabel()
        view.text = localized("tx_detail.block_explorer.description")
        view.font = Theme.shared.fonts.txScreenTextLabel
        return view
    }()

    @TariView private var accessoryView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.forwardArrow
        view.contentMode = .scaleAspectFit
        return view
    }()

    // MARK: - Initialisations

    override init() {
        super.init()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [label, accessoryView].forEach(addSubview)

        let constraints = [
            label.topAnchor.constraint(equalTo: topAnchor, constant: 11.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -11.0),
            accessoryView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 11.0),
            accessoryView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            accessoryView.heightAnchor.constraint(equalToConstant: 13.0),
            accessoryView.widthAnchor.constraint(equalToConstant: 13.0),
            accessoryView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Update

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.heading
        accessoryView.tintColor = theme.icons.default
    }
}
