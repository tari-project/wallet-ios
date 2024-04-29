//  ChatInputMessageView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 20/09/2023
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

final class ChatInputMessageView: DynamicThemeView {

    // MARK: - Constants

    private static let addGifButtonHeight: CGFloat = 21.0
    private let maxNumberOfLinesWithoutScrolling = 4

    // MARK: - Subviews

    @View private var addButton: BaseButton = {
        let view = BaseButton()
        view.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large)), for: .normal)
        view.imageView?.contentMode = .scaleToFill
        return view
    }()

    @View private var textView: UITextView = {
        let view = UITextView()
        view.textContainerInset = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0 + addGifButtonHeight)
        view.font = .Avenir.roman.withSize(14.0)
        view.layer.cornerRadius = 6.0
        return view
    }()

    @View private var addGifButton: BaseButton = {
        let view = BaseButton()
        view.setImage(.Icons.Chat.document, for: .normal)
        return view
    }()

    @View private var textViewPlaceholderLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.roman.withSize(14.0)
        view.text = localized("chat.conversation.label.input_placeholder")
        return view
    }()

    @View private var sendButton: BaseButton = {
        let view = BaseButton()
        view.setImage(.Icons.Chat.sendMessage, for: .normal)
        view.isEnabled = false
        return view
    }()

    // MARK: - Properties

    var onAddButtonTap: (() -> Void)?
    var onAddGifButtonTap: (() -> Void)?
    var onSendButtonTap: ((String?) -> Void)?
    private var textViewHeightConstraint: NSLayoutConstraint?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [addButton, textView, addGifButton, textViewPlaceholderLabel, sendButton].forEach(addSubview)

        let textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: 0.0)
        self.textViewHeightConstraint = textViewHeightConstraint

        let constraints = [
            addButton.topAnchor.constraint(equalTo: topAnchor, constant: 21.0),
            addButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            addButton.widthAnchor.constraint(equalToConstant: 24.0),
            addButton.heightAnchor.constraint(equalToConstant: 24.0),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: 10.0),
            textView.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 10.0),
            textView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10.0),
            textViewHeightConstraint,
            addGifButton.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -10.0),
            addGifButton.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
            addGifButton.heightAnchor.constraint(equalToConstant: Self.addGifButtonHeight),
            addGifButton.widthAnchor.constraint(equalToConstant: Self.addGifButtonHeight),
            textViewPlaceholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 15.0),
            textViewPlaceholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 15.0),
            textViewPlaceholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -15.0),
            textViewPlaceholderLabel.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -15.0),
            sendButton.topAnchor.constraint(equalTo: topAnchor, constant: 21.0),
            sendButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 10.0),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            sendButton.widthAnchor.constraint(equalToConstant: 24.0),
            sendButton.heightAnchor.constraint(equalToConstant: 24.0)
        ]

        NSLayoutConstraint.activate(constraints)
        updateTextViewHeight()
    }

    private func setupCallbacks() {

        textView.delegate = self

        addButton.onTap = { [weak self] in
            self?.onAddButtonTap?()
        }

        addGifButton.onTap = { [weak self] in
            self?.onAddGifButtonTap?()
        }

        sendButton.onTap = { [weak self] in
            self?.onSendButtonTap?(self?.textView.text)
            self?.textView.text = ""
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.neutral.tertiary
        addButton.tintColor = theme.icons.active
        textView.backgroundColor = theme.backgrounds.primary
        textView.textColor = theme.text.body
        addGifButton.tintColor = theme.icons.active
        textViewPlaceholderLabel.textColor = theme.text.lightText
        sendButton.tintColor = theme.icons.active
    }

    private func updateTextViewHeight() {
        let currentText = textView.text
        let height = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .infinity)).height
        textView.text = (0..<maxNumberOfLinesWithoutScrolling-1).reduce(into: "") { result, _ in result += "\n" }
        let maxHeight = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .infinity)).height
        textView.text = currentText
        textViewHeightConstraint?.constant = min(height, maxHeight)
        textView.scrollToBottom(animated: true)
    }

    private func updatePlaceholder() {
        UIView.animate(withDuration: 0.3) {
            self.textViewPlaceholderLabel.alpha = (!self.textView.isFirstResponder && self.textView.text.isEmpty) ? 1.0 : 0.0
        }
    }
}

extension ChatInputMessageView: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {

        let text = (textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        sendButton.isEnabled = !text.isEmpty

        updateTextViewHeight()

        UIView.animate(withDuration: 0.1) {
            self.textView.layoutIfNeeded()
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        updatePlaceholder()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholder()
    }
}
