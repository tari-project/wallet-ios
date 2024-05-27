//  ChatReplyBar.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 21/05/2024
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

final class ChatReplyBar: DynamicThemeView {

    // MARK: - Subviews

    @View private var separatorView = UIView()
    @View private var notificationBar = ChatReplyNotificationBar()

    @View private var closeButton: BaseButton = {
        let view = BaseButton()
        view.setImage(.Icons.General.close, for: .normal)
        return view
    }()

    // MARK: - Properties

    var onCloseButtonTap: (() -> Void)? {
        get { closeButton.onTap }
        set { closeButton.onTap = newValue }
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

        [separatorView, notificationBar, closeButton].forEach(addSubview)

        let constraints = [
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1.0),
            notificationBar.topAnchor.constraint(equalTo: topAnchor, constant: 10.0),
            notificationBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            notificationBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10.0),
            closeButton.leadingAnchor.constraint(equalTo: notificationBar.trailingAnchor, constant: 15.0),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15.0),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24.0),
            closeButton.heightAnchor.constraint(equalToConstant: 24.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        closeButton.tintColor = theme.icons.default
    }

    func update(viewModel: ChatReplyViewModel) {
        notificationBar.update(viewModel: viewModel)
    }
}
