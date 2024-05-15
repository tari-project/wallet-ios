//  ChatAttachmentsBar.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 29/03/2024
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

final class ChatAttachmentsBar: DynamicThemeView {

    enum AttachmentType {
        case request(amount: String)
        case gif(state: GifDynamicModel.GifDataState)
    }

    // MARK: - Subviews

    @View private var label: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .Avenir.heavy.withSize(16.0)
        return view
    }()

    @View private var gifView = GifView()

    @View private var contentView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        return view
    }()

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

    var attachmentType: AttachmentType? {
        didSet { update(attachmentType: attachmentType) }
    }

    private var closeButtonTopConstraint: NSLayoutConstraint?
    private var closeButtonCenterYConstaint: NSLayoutConstraint?

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

        [label, gifView].forEach(contentView.addArrangedSubview)
        [contentView, closeButton].forEach(addSubview)

        closeButtonTopConstraint = closeButton.topAnchor.constraint(equalTo: topAnchor)
        closeButtonCenterYConstaint = closeButton.centerYAnchor.constraint(equalTo: centerYAnchor)

        let constraints = [
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 10.0),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40.0),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10.0),
            label.heightAnchor.constraint(equalToConstant: 42.0),
            closeButton.leadingAnchor.constraint(equalTo: contentView.trailingAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40.0),
            closeButton.heightAnchor.constraint(equalToConstant: 40.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        closeButton.tintColor = theme.icons.default
        label.textColor = theme.text.heading
    }

    private func update(attachmentType: AttachmentType?) {

        label.attributedText = nil
        gifView.update(dataState: .none)

        label.isHidden = true
        gifView.isHidden = true

        guard let attachmentType else { return }

        switch attachmentType {
        case let .request(amount):
            update(amount: amount)
            label.isHidden = false
            closeButtonTopConstraint?.isActive = false
            closeButtonCenterYConstaint?.isActive = true
        case let .gif(state):
            gifView.update(dataState: state)
            gifView.isHidden = false
            closeButtonCenterYConstaint?.isActive = false
            closeButtonTopConstraint?.isActive = true
        }
    }

    private func update(amount: String) {

        let prefixText = localized("chat.conversation.attachements_bar.request.label.request") + " "
        let suffixText = " " + amount

        let text = NSMutableAttributedString(string: prefixText)
        let imageAttachement = NSTextAttachment()
        imageAttachement.image = .Icons.General.tariGem
        imageAttachement.bounds = CGRect(x: 0.0, y: 0.0, width: 12.0, height: 12.0)
        let imageText = NSAttributedString(attachment: imageAttachement)

        text.append(imageText)
        text.append(NSAttributedString(string: suffixText))

        label.attributedText = text
    }
}
