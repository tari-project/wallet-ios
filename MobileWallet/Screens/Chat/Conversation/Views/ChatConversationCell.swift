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

        let id: ChatMessageIdentifier
        let isIncoming: Bool
        let isLastInContext: Bool
        let notificationsTextComponents: [ChatNotificationModel]
        let message: String
        let actionButtonTitle: String?
        let actionCallback: (() -> Void)?
        let timestamp: String
        let rawTimestamp: Date
        let gifIdentifier: String?
        let replyModel: ChatReplyViewModel?

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

    @View private var notificationsStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 10.0
        return view
    }()

    @View private var messageLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = .Avenir.medium.withSize(15.0)
        return view
    }()

    @View private var actionButton = ActionButton()
    @View private var replyBar = ChatReplyNotificationBar()

    @View private var gifView: GifView = {
        let view = GifView()
        view.layer.cornerRadius = 5.0
        view.clipsToBounds = true
        return view
    }()

    @View private var timestampLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(11.0)
        return view
    }()

    // MARK: - Properties

    var onContentChange: (() -> Void)? {
        get { gifView.onStateUpdate }
        set { gifView.onStateUpdate = newValue }
    }

    var onContextMenuInteraction: ((ChatConversationMenuAction) -> Void)?

    private var contentViewLeadingConstraint: NSLayoutConstraint?
    private var contentViewTrailingConstraint: NSLayoutConstraint?

    private(set) var dataIdentifier: ChatMessageIdentifier?
    private var isIncoming: Bool = false

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
        setupContextMenu()
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

        [replyBar, gifView, notificationsStackView, messageLabel, actionButton].forEach(contentStackView.addArrangedSubview)
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

    private func setupContextMenu() {
        bubbleContentView.addInteraction(UIContextMenuInteraction(delegate: self))
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        messageLabel.textColor = theme.chat.text.text
        timestampLabel.textColor = theme.text.body
        updateContentBackgroundColor(theme: theme)
    }

    private func updateContentBackgroundColor(theme: ColorTheme) {
        bubbleContentView.backgroundColor = isIncoming ? theme.chat.backgrounds.receiver : theme.chat.backgrounds.sender
    }

    func update(model: Model) {

        dataIdentifier = model.id

        contentViewLeadingConstraint?.constant = model.isIncoming ? 25.0 : 90.0
        contentViewTrailingConstraint?.constant = model.isIncoming ? -90.0 : -25.0

        if let replyModel = model.replyModel {
            replyBar.update(viewModel: replyModel)
            replyBar.isHidden = false
        } else {
            replyBar.isHidden = true
        }

        notificationsStackView.removeAllViews()
        notificationsStackView.isHidden = model.notificationsTextComponents.isEmpty

        model.notificationsTextComponents
            .map {
                let view = ChatConversationNotificationBar()
                let messageType: ChatConversationNotificationBar.MessageType

                if $0.isValid {
                    messageType = model.isIncoming ? .incoming : .outgoing
                } else {
                    messageType = .error
                }

                view.update(textComponents: $0.notificationParts, messageType: messageType)
                return view
            }
            .forEach(notificationsStackView.addArrangedSubview)

        actionButton.onTap = model.actionCallback

        messageLabel.text = model.message
        actionButton.setTitle(model.actionButtonTitle, for: .normal)
        actionButton.isHidden = model.actionButtonTitle == nil
        timestampLabel.text = model.timestamp
        isIncoming = model.isIncoming

        gifView.gifID = model.gifIdentifier
        gifView.isHidden = model.gifIdentifier == nil

        if !model.isLastInContext {
            bubbleContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if model.isIncoming {
            bubbleContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        } else {
            bubbleContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        }

        updateContentBackgroundColor(theme: theme)
    }
}

extension ChatConversationCell: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        guard let dataIdentifier else { return nil }

        return UIContextMenuConfiguration(actionProvider: { _ in
            UIMenu(children: [
                UIAction(title: localized("chat.conversation.cell.context_menu.reply"), image: .Icons.Chat.reply) { [weak self] _ in self?.onContextMenuInteraction?(.reply(identifier: dataIdentifier)) }
            ])
        })
    }
}
