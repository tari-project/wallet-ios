//  ErrorView.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/04/06
	Using Swift 5.0
	Running on macOS 10.15

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

final class ErrorView: DynamicThemeView {

    // MARK: - Subviews

    @TariView private var label: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .Poppins.Bold.withSize(14.0)
        view.numberOfLines = 0
        return view
    }()

    // MARK: - Properties

    var message: String? {
        get { label.text }
        set { label.text = newValue }
    }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        layer.cornerRadius = 4.0
        layer.masksToBounds = true
        layer.borderWidth = 1.0
        backgroundColor = .clear
    }

    private func setupConstraints() {

        addSubview(label)

        let constraints = [
            label.topAnchor.constraint(equalTo: topAnchor, constant: 14.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14.0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14.0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        label.textColor = theme.system.red
        layer.borderColor =  theme.system.red?.cgColor
    }
}
