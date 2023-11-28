//  ContactTransactionListPlaceholder.swift

/*
    Package MobileWallet
    Created by Adrian Truszczyński on 18/04/2023
    Using Swift 5.0
    Running on macOS 13.0

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

final class ContactTransactionListPlaceholder: DynamicThemeView {

    // MARK: - Subviews

    @View private var imageView: PaintBackgroundImageView = {
        let view = PaintBackgroundImageView()
        view.image = .Images.ContactBook.Placeholders.transactionList
        return view
    }()

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("contact_book.transaction_list.placeholder.label.title")
        view.textAlignment = .center
        view.font = .Avenir.light.withSize(18.0)
        return view
    }()

    @View private var messageLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.textAlignment = .center
        view.numberOfLines = 0
        view.normalFont = .Avenir.medium.withSize(14.0)
        view.boldFont = .Avenir.heavy.withSize(14.0)
        view.separator = " "
        return view
    }()

    @View private var sendButton: TextButton = {
        let view = TextButton()
        view.style = .secondary
        view.setTitle(localized("contact_book.transaction_list.placeholder.button.send"), for: .normal)
        return view
    }()

    // MARK: - Properties

    var name: String = "" {
        didSet { updateMessageLabel() }
    }

    var onButtonTap: (() -> Void)?

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

        [imageView, titleLabel, messageLabel, sendButton].forEach(addSubview)

        let constraints = [
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 133.0),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: UIScreen.isSmallScreen ? 0.2 : 0.33),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 36.0),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36.0),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -36.0),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20.0),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36.0),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -36.0),
            sendButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 40.0),
            sendButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        sendButton.onTap = { [weak self] in
            self?.onButtonTap?()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
        titleLabel.textColor = theme.text.heading
        messageLabel.textColor = theme.text.body
    }

    private func updateMessageLabel() {
        messageLabel.textComponents = [
            StylizedLabel.StylizedText(text: localized("contact_book.transaction_list.placeholder.label.message.part.1"), style: .normal),
            StylizedLabel.StylizedText(text: name, style: .bold),
            StylizedLabel.StylizedText(text: localized("contact_book.transaction_list.placeholder.label.message.part.3"), style: .normal)
        ]
    }
}
