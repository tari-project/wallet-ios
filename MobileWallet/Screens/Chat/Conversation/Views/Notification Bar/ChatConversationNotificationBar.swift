//  ChatConversationNotificationBar.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 15/09/2023
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

final class ChatConversationNotificationBar: BaseChatNotificationBar {

    @View private var textLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.normalFont = .Avenir.medium.withSize(15.0)
        view.boldFont = .Avenir.heavy.withSize(15.0)
        view.separator = " "
        view.numberOfLines = 0
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
        contentMargin = 8.0
    }

    private func setupConstraints() {

        contentView.addSubview(textLabel)

        let constraints = [
            textLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        updateTextColor(theme: theme)
    }

    func update(textComponents: [StylizableComponent], messageType: MessageType) {
        textLabel.textComponents = textComponents
        self.messageType = messageType
        updateTextColor(theme: theme)
    }

    private func updateTextColor(theme: ColorTheme) {
        textLabel.textColor = messageType == .error ? theme.system.red : theme.chat.text.textNotification
    }
}
