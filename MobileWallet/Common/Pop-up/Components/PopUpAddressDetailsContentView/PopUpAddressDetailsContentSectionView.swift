//  PopUpAddressDetailsContentSectionView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 02/07/2024
	Using Swift 5.0
	Running on macOS 14.4

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

import TariCommon

final class PopUpAddressDetailsContentSectionView<T: UIView>: DynamicThemeView {

    // MARK: - Subviews

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .Poppins.Bold.withSize(15.0)
        return view
    }()

    @View private var contentBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4.0
        return view
    }()

    @View private(set) var contentView = T()

    // MARK: - Properties

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

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

        [titleLabel, contentBackgroundView].forEach(addSubview)
        contentBackgroundView.addSubview(contentView)

        let constraints = [
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentBackgroundView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10.0),
            contentBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.topAnchor.constraint(equalTo: contentBackgroundView.topAnchor, constant: 10.0),
            contentView.leadingAnchor.constraint(equalTo: contentBackgroundView.leadingAnchor, constant: 10.0),
            contentView.trailingAnchor.constraint(equalTo: contentBackgroundView.trailingAnchor, constant: -10.0),
            contentView.bottomAnchor.constraint(equalTo: contentBackgroundView.bottomAnchor, constant: -10.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        contentBackgroundView.backgroundColor = theme.backgrounds.secondary
    }
}
