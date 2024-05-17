//  AttachmentOverlayView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 15/05/2024
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

final class AttachmentOverlayView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var contentView = KeyboardAvoidingContentView()

    @View private var gifView: GifView = {
        let view = GifView()
        view.layer.cornerRadius = 10.0
        view.clipsToBounds = true
        return view
    }()

    @View private var amountLabel: AnimatedBalanceLabel = {
        let view = AnimatedBalanceLabel()
        view.animation = .type
        view.textAlignment = .center(inset: -30)
        return view
    }()

    @View private var textInputBar: ChatInputMessageView = {
        let view = ChatInputMessageView()
        view.isAddButtonHidden = true
        view.isGifButtonHidden = true
        return view
    }()

    // MARK: - Properties

    var onSendButtonTap: ((String?) -> Void)? {
        get { textInputBar.onSendButtonTap }
        set { textInputBar.onSendButtonTap = newValue }
    }

    var messageText: String? {
        get { textInputBar.text }
        set { textInputBar.text = newValue }
    }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupNavigationBar()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupNavigationBar() {
        navigationBar.backButtonType = .close
    }

    private func setupConstraints() {

        addSubview(contentView)
        [gifView, amountLabel, textInputBar].forEach(contentView.addSubview)

        let constraints = [
            contentView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            gifView.topAnchor.constraint(equalTo: contentView.contentView.topAnchor, constant: 25.0),
            gifView.leadingAnchor.constraint(equalTo: contentView.contentView.leadingAnchor, constant: 25.0),
            gifView.trailingAnchor.constraint(equalTo: contentView.contentView.trailingAnchor, constant: -25.0),
            amountLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 100.0),
            amountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textInputBar.leadingAnchor.constraint(equalTo: contentView.contentView.leadingAnchor),
            textInputBar.trailingAnchor.constraint(equalTo: contentView.contentView.trailingAnchor),
            textInputBar.bottomAnchor.constraint(equalTo: contentView.contentView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    func update(requestedValue: NSAttributedString) {
        navigationBar.title = localized("chat.conversation.attachements_overlay.title.request")
        amountLabel.attributedText = requestedValue
        amountLabel.isHidden = false
        gifView.isHidden = true
    }

    func update(gifState: GifDynamicModel.GifDataState) {
        navigationBar.title = localized("chat.conversation.attachements_overlay.title.gif")
        gifView.update(dataState: gifState)
        gifView.isHidden = false
        amountLabel.isHidden = true

    }
}
