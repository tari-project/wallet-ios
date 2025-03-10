//  MenuTableHeaderView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 27/02/2023
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

import TariCommon

final class MenuTableHeaderView: DynamicThemeHeaderFooterView {

    // MARK: - Subviews

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = .Poppins.Bold.withSize(15.0)
        return view
    }()

    @View private var backgroundContentView = UIView()

    // MARK: - Properties

    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

    // MARK: - Initialisers

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [backgroundContentView, label].forEach(addSubview)

        let constraints = [
            backgroundContentView.topAnchor.constraint(equalTo: topAnchor),
            backgroundContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.heading
        backgroundContentView.backgroundColor = theme.backgrounds.secondary
    }
}
