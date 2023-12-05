//  ChatNavigationContentView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 18/09/2023
	Using Swift 5.0
	Running on macOS 13.5

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

final class ChatNavigationContentView: BaseButton {

    // MARK: - Subviews

    @View private var avatarView = AvatarWithStatusView()

    @View private var usernameLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.black.withSize(17.0)
        return view
    }()

    // MARK: - Properties

    var avatar: RoundedAvatarView.Avatar {
        get { avatarView.avatar }
        set { avatarView.avatar = newValue }
    }

    var isOnline: Bool {
        get { avatarView.isOnline }
        set { avatarView.isOnline = newValue }
    }

    var username: String? {
        get { usernameLabel.text }
        set { usernameLabel.text = newValue }
    }

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [avatarView, usernameLabel].forEach(addSubview)

        let constratins = [
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.0),
            avatarView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 32.0),
            avatarView.heightAnchor.constraint(equalToConstant: 32.0),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 20.0),
            usernameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            usernameLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        NSLayoutConstraint.activate(constratins)
    }
}
