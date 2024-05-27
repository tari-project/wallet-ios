//  ChatReplyNotificationBar.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 09/05/2024
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

final class ChatReplyNotificationBar: BaseChatNotificationBar {

    // MARK: - Subviews

    @View private var topLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.heavy.withSize(15.0)
        return view
    }()

    @View private var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private var bottomLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(15.0)
        return view
    }()

    @View private var thumbnailView: GifView = {
        let view = GifView()
        return view
    }()

    @View private var bottomViewStack: UIStackView = {
        let view = UIStackView()
        view.spacing = 5.0
        return view
    }()

    @View private var leadingContentStack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        return view
    }()

    @View private var mainViewStack: UIStackView = {
        let view = UIStackView()
        return view
    }()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupSubviews() {
        messageType = .outgoing
        contentMargin = 0.0
    }

    private func setupConstraints() {

        topLabel.setContentHuggingPriority(.required, for: .vertical)
        bottomLabel.setContentHuggingPriority(.required, for: .vertical)
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        [iconView, bottomLabel].forEach(bottomViewStack.addArrangedSubview)
        [topLabel, bottomViewStack].forEach(leadingContentStack.addArrangedSubview)
        [leadingContentStack, thumbnailView].forEach(mainViewStack.addArrangedSubview)

        contentView.addSubview(mainViewStack)

        let constraints = [
            mainViewStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainViewStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainViewStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainViewStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        topLabel.textColor = theme.chat.text.textNotification
        iconView.tintColor = theme.chat.text.textNotification
        bottomLabel.textColor = theme.chat.text.textNotification
    }

    func update(viewModel: ChatReplyViewModel) {
        topLabel.text = viewModel.name
        bottomLabel.text = viewModel.message
        iconView.image = viewModel.icon
        iconView.isHidden = viewModel.icon == nil
        thumbnailView.gifID = viewModel.gifID
    }
}
