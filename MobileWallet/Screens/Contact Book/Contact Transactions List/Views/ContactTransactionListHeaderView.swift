//  ContactTransactionListHeaderView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 18/04/2023
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

final class ContactTransactionListHeaderView: DynamicThemeView {

    // MARK: - Subviews

    @View private var label: StylizedLabel = {
        let view = StylizedLabel()
        view.textAlignment = .center
        view.normalFont = .Avenir.medium.withSize(14.0)
        view.boldFont = .Avenir.heavy.withSize(14.0)
        view.numberOfLines = 0
        view.separator = " "
        return view
    }()

    @View private var placeholder = UIView()

    // MARK: - Properties

    var name: String = "" {
        didSet { updateText() }
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

        [label, placeholder].forEach(addSubview)

        let constraints = [
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            placeholder.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20.0),
            placeholder.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholder.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholder.bottomAnchor.constraint(equalTo: bottomAnchor),
            placeholder.heightAnchor.constraint(equalToConstant: 20.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func updateText() {
        label.textComponents = [
            StylizedLabel.StylizedText(text: localized("contact_book.transaction_list.label.part.1"), style: .normal),
            StylizedLabel.StylizedText(text: name, style: .bold)
        ]
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
        placeholder.backgroundColor = theme.backgrounds.primary
    }
}
