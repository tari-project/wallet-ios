//  TokenView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 23/07/2021
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

final class TokenView: UICollectionViewCell {

    // MARK: - Subviews

    private let label: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.restoreFromSeedWordsToken
        view.textColor = Theme.shared.colors.restoreFromSeedWordsTextColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let deleteIconView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.cancelGrey
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        backgroundColor = .white
        layer.cornerRadius = 5.0
        layer.borderWidth = 1.0
        layer.borderColor = Theme.shared.colors.tokenBorderColor?.cgColor
    }

    private func setupConstraints() {

        [label, deleteIconView].forEach(addSubview)

        let constraints = [
            label.topAnchor.constraint(equalTo: topAnchor, constant: 3.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13.0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3.0),
            deleteIconView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5.0),
            deleteIconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8.0),
            deleteIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteIconView.heightAnchor.constraint(equalToConstant: 14.0),
            deleteIconView.widthAnchor.constraint(equalToConstant: 14.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
