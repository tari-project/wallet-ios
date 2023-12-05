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

final class ChatConversationNotificationBar: DynamicThemeView {

    // MARK: - Subviews

    @View private var leftBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 1.0
        return view
    }()

    @View private var textLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.normalFont = .Avenir.medium.withSize(15.0)
        view.boldFont = .Avenir.heavy.withSize(15.0)
        view.separator = " "
        view.numberOfLines = 0
        return view
    }()

    // MARK: - Properties

    private var isIncomingMessage: Bool = false

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

        [leftBar, textLabel].forEach(addSubview)

        let constraints = [
            leftBar.topAnchor.constraint(equalTo: topAnchor, constant: 3.0),
            leftBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3.0),
            leftBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3.0),
            leftBar.widthAnchor.constraint(equalToConstant: 2.0),
            textLabel.topAnchor.constraint(equalTo: leftBar.topAnchor, constant: 8.0),
            textLabel.leadingAnchor.constraint(equalTo: leftBar.leadingAnchor, constant: 5.0),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10.0),
            textLabel.bottomAnchor.constraint(equalTo: leftBar.bottomAnchor, constant: -8.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        leftBar.backgroundColor = theme.chat.text.textNotification
        textLabel.textColor = theme.chat.text.textNotification
        updateBackgroundColor(theme: theme)
    }

    func update(textComponents: [StylizedLabel.StylizedText], isIncomingMessage: Bool) {
        textLabel.textComponents = textComponents
        self.isIncomingMessage = isIncomingMessage
        updateBackgroundColor(theme: theme)
    }

    private func updateBackgroundColor(theme: ColorTheme) {
        backgroundColor = isIncomingMessage ? theme.chat.backgrounds.senderNotification : theme.chat.backgrounds.receiverNotification
    }
}
