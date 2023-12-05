//  ChatConversationCell.swift

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

final class ChatConversationCell: DynamicThemeCell {

    struct Model: Identifiable, Hashable {

        let id: String
        let isIncoming: Bool
        let isLastInContext: Bool
        let notificationTextComponents: [StylizedLabel.StylizedText]
        let message: String
        let timestamp: String

        static func == (lhs: ChatConversationCell.Model, rhs: ChatConversationCell.Model) -> Bool { lhs.id == rhs.id }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    // MARK: - Subviews

    @View private var bubbleContentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15.0
        return view
    }()

    @View private var contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 10.0
        return view
    }()

    @View private var notificationBar = ChatConversationNotificationBar()

    @View private var messageLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = .Avenir.medium.withSize(15.0)
        return view
    }()

    @View private var timestampLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(11.0)
        return  view
    }()

    // MARK: - Properties

    private var contentViewLeadingConstraint: NSLayoutConstraint?
    private var contentViewTrailingConstraint: NSLayoutConstraint?

    private var isIncoming: Bool = false

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
    }

    private func setupConstraints() {

        [notificationBar, messageLabel].forEach(contentStackView.addArrangedSubview)
        [contentStackView, timestampLabel].forEach(bubbleContentView.addSubview)
        contentView.addSubview(bubbleContentView)

        let contentViewLeadingConstraint = bubbleContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        let contentViewTrailingConstraint = bubbleContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)

        self.contentViewLeadingConstraint = contentViewLeadingConstraint
        self.contentViewTrailingConstraint = contentViewTrailingConstraint

        let constraints = [
            bubbleContentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5.0),
            contentViewLeadingConstraint,
            contentViewTrailingConstraint,
            bubbleContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5.0),
            contentStackView.topAnchor.constraint(equalTo: bubbleContentView.topAnchor, constant: 15.0),
            contentStackView.leadingAnchor.constraint(equalTo: bubbleContentView.leadingAnchor, constant: 15.0),
            contentStackView.trailingAnchor.constraint(equalTo: bubbleContentView.trailingAnchor, constant: -15.0),
            contentStackView.bottomAnchor.constraint(equalTo: bubbleContentView.bottomAnchor, constant: -15.0),
            timestampLabel.trailingAnchor.constraint(equalTo: bubbleContentView.trailingAnchor, constant: -15.0),
            timestampLabel.bottomAnchor.constraint(equalTo: bubbleContentView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        messageLabel.textColor = theme.chat.text.text
        timestampLabel.textColor = theme.text.body
        updateContentBackgroundColor(theme: theme)
    }

    private func updateContentBackgroundColor(theme: ColorTheme) {
        bubbleContentView.backgroundColor = isIncoming ? theme.chat.backgrounds.sender : theme.chat.backgrounds.receiver
        messageLabel.textColor = theme.chat.text.text
    }

    func update(model: Model) {

        contentViewLeadingConstraint?.constant = model.isIncoming ? 90.0 : 25.0
        contentViewTrailingConstraint?.constant = model.isIncoming ? -25.0 : -90.0

        notificationBar.update(textComponents: model.notificationTextComponents, isIncomingMessage: model.isIncoming)
        notificationBar.isHidden = model.notificationTextComponents.isEmpty

        messageLabel.text = model.message
        timestampLabel.text = model.timestamp
        isIncoming = model.isIncoming

        if !model.isLastInContext {
            bubbleContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if model.isIncoming {
            bubbleContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        } else {
            bubbleContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }

        updateContentBackgroundColor(theme: theme)
    }
}
