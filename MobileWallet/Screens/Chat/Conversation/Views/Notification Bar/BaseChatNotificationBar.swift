//  BaseChatNotificationBar.swift

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

class BaseChatNotificationBar: DynamicThemeView {

    enum MessageType {
        case incoming
        case outgoing
        case error
    }

    // MARK: - Subviews

    @View private var leftBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 1.0
        return view
    }()

    @View private(set) var contentView = UIView()

    // MARK: - Properties

    var messageType: MessageType = .incoming {
        didSet { updateColors(theme: theme) }
    }

    var contentMargin: CGFloat = 0.0 {
        didSet {
            contentViewTopConstraint?.constant = contentMargin
            contentViewBottomConstraint?.constant = -contentMargin
        }
    }

    private var contentViewTopConstraint: NSLayoutConstraint?
    private var contentViewBottomConstraint: NSLayoutConstraint?

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

        [leftBar, contentView].forEach(addSubview)

        let contentViewTopConstraint = contentView.topAnchor.constraint(equalTo: leftBar.topAnchor)
        let contentViewBottomConstraint = contentView.bottomAnchor.constraint(equalTo: leftBar.bottomAnchor)

        self.contentViewTopConstraint = contentViewTopConstraint
        self.contentViewBottomConstraint = contentViewBottomConstraint

        let constraints = [
            leftBar.topAnchor.constraint(equalTo: topAnchor, constant: 3.0),
            leftBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3.0),
            leftBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3.0),
            leftBar.widthAnchor.constraint(equalToConstant: 2.0),
            contentViewTopConstraint,
            contentView.leadingAnchor.constraint(equalTo: leftBar.leadingAnchor, constant: 5.0),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10.0),
            contentViewBottomConstraint
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        updateColors(theme: theme)
    }

    private func updateColors(theme: ColorTheme) {

        leftBar.backgroundColor = messageType == .error ? theme.system.red : theme.chat.text.textNotification

        switch messageType {
        case .incoming:
            backgroundColor = theme.chat.backgrounds.receiverNotification
        case .outgoing:
            backgroundColor = theme.chat.backgrounds.senderNotification
        case .error:
            backgroundColor = theme.system.red?.withAlphaComponent(0.15)
        }
    }
}
