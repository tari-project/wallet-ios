//  PopUpProfileShareContentView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 21/10/2024
	Using Swift 5.0
	Running on macOS 14.6

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

final class PopUpProfileShareContentView: DynamicThemeView {

    // MARK: - Subviews

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 40.0
        return view
    }()

    @View private var label: UILabel = {
        let view = UILabel()
        view.text = localized("profile_view.pop_up.share.message", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol)
        view.font = .Avenir.medium.withSize(13.0)
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    @View private var linkCodeButton: RoundedLabeledButton = {
        let view = RoundedLabeledButton()
        view.update(image: .Icons.General.link, text: localized("profile_view.button.share.link"))
        view.buttonSize = 46.0
        view.padding = 12.0
        return view
    }()

    @View private var bleCodeButton: RoundedLabeledButton = {
        let view = RoundedLabeledButton()
        view.update(image: .Icons.General.bluetooth, text: localized("profile_view.button.share.ble"))
        view.buttonSize = 46.0
        view.padding = 12.0
        return view
    }()

    // MARK: - Properties

    var onLinkButtonTap: (() -> Void)? {
        get { linkCodeButton.onTap }
        set { linkCodeButton.onTap = newValue }
    }
    var onBLEButtonTap: (() -> Void)? {
        get { bleCodeButton.onTap }
        set { bleCodeButton.onTap = newValue }
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

        [label, stackView].forEach { addSubview($0) }
        [linkCodeButton, bleCodeButton].forEach { stackView.addArrangedSubview($0) }

        let constraints = [
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.body
    }
}
