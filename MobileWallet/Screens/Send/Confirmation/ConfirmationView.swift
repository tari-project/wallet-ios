//  ConfirmationView.swift

/*
	Package MobileWallet
	Created by Konrad Faltyn on 09/04/2025
	Using Swift 6.0
	Running on macOS 15.3

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

class DetailView: DynamicThemeView {
    var onCopyButonTap: ((_ value: String?) -> Void)? {
        didSet {
            copyButton.addAction(UIAction(handler: { _ in
                self.onCopyButonTap?(self.valueText)
            }), for: .touchUpInside)
        }
    }

    override init() {
        super.init()
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    @View private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(12)
        return label
    }()

    @View private var valueLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(14)
        return label
    }()

    @View private var separatorView: UIView = {
        let view = UIView()
        return view
    }()

    @View private var copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.sendCopy.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .Text.primary
        button.backgroundColor = .clear
        return button
    }()

    func setupViews() {

        [titleLabel, valueLabel, separatorView, copyButton].forEach(addSubview)

        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.leftAnchor.constraint(equalTo: leftAnchor),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            copyButton.rightAnchor.constraint(equalTo: rightAnchor),
            copyButton.centerYAnchor.constraint(equalTo: valueLabel.topAnchor),
            copyButton.heightAnchor.constraint(equalToConstant: 22),
            copyButton.widthAnchor.constraint(equalToConstant: 22),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.leftAnchor.constraint(equalTo: leftAnchor),
            separatorView.rightAnchor.constraint(equalTo: rightAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    public var titleText: String? {
        didSet {
            titleLabel.text = titleText
        }
    }

    public var valueText: String? {
        didSet {
            valueLabel.text = valueText
        }
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)

        backgroundColor = .clear
        separatorView.backgroundColor = .Token.divider
        titleLabel.textColor = .Text.secondary
        valueLabel.textColor = .Text.primary
    }
}

class ConfirmationView: DynamicThemeView {
    var onSendButonTap: (() -> Void)? {
        didSet {
            sendButton.onTap = onSendButonTap
        }
    }
    var onCancelButonTap: (() -> Void)? {
        didSet {
            cancelButton.onTap = onCancelButonTap
        }
    }

    var onCopyButonTap: ((_ value: String?) -> Void)? {
        didSet {
            feeView.onCopyButonTap = onCopyButonTap
            recipientView.onCopyButonTap = onCopyButonTap
            noteView.onCopyButonTap = onCopyButonTap
        }
    }

    override init() {
        super.init()
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    @View private var titleLabel: UILabel = {
        let label = UILabel()

        label.text = "You are about to send"
        label.font = .Poppins.SemiBold.withSize(16)
        return label
    }()

    @View private var amountContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        return view
    }()

    @View private var amountLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(18)
        return label
    }()

    @View private var userLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(18)
        return label
    }()

    @View private var addressContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        return view
    }()

    @View private var separatorView: UIView = {
        let view = UIView()
        return view
    }()

    @View private var sendFundsImageView = UIImageView(image: .sendFundsSeparator)
    @View private var tariIconView = UIImageView(image: .sendTariIcon)
    @View private var userIconView = UIImageView(image: .sendTariIcon)

    @View private var feeView: DetailView = {
        let view = DetailView()
        view.titleText = "Transaction Fee"
        return view
    }()

    @View private var recipientView: DetailView = {
        let view = DetailView()
        view.titleText = "Recipient Address"
        return view
    }()

    @View private var noteView: DetailView = {
        let view = DetailView()
        view.titleText = "Note"
        return view
    }()

    @View private var sendButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .large)
        button.setTitle("Confirm & Send", for: .normal)
        return button
    }()

    @View private var cancelButton: StylisedButton = {
        let button = StylisedButton(withStyle: .text, withSize: .large)
        button.setTitle("Cancel", for: .normal)
        return button
    }()

    @View private var totalLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(16)
        label.text = "Total"
        return label
    }()

    @View private var totalValueLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(16)
        return label
    }()

    public var amountText: String? {
        didSet {
            amountLabel.text = amountText
        }
    }

    public var totalAmountText: String? {
        didSet {
            totalValueLabel.text = amountText
        }
    }

    public var feeText: String? {
        didSet {
            feeView.valueText = feeText
        }
    }

    public var addressText: String? {
        didSet {
            userLabel.text = addressText
            recipientView.valueText = addressText
        }
    }

    public var noteText: String? {
        didSet {
            noteView.valueText = noteText
        }
    }

    func setupViews() {

        [titleLabel, amountContainerView, addressContainerView,
         sendFundsImageView, amountLabel, tariIconView,
         userIconView, userLabel, feeView, recipientView, noteView, totalLabel, totalValueLabel, sendButton, cancelButton].forEach(addSubview)

        let guide = UILayoutGuide()
        addLayoutGuide(guide)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 106),
            amountContainerView.widthAnchor.constraint(equalToConstant: 356),
            amountContainerView.heightAnchor.constraint(equalToConstant: 82),
            amountContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            amountContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            addressContainerView.widthAnchor.constraint(equalToConstant: 356),
            addressContainerView.heightAnchor.constraint(equalToConstant: 82),
            addressContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            addressContainerView.topAnchor.constraint(equalTo: amountContainerView.bottomAnchor, constant: 12),

            guide.leftAnchor.constraint(equalTo: amountContainerView.leftAnchor),
            guide.rightAnchor.constraint(equalTo: amountContainerView.rightAnchor),
            guide.topAnchor.constraint(equalTo: amountContainerView.topAnchor),
            guide.bottomAnchor.constraint(equalTo: addressContainerView.bottomAnchor),

            sendFundsImageView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            sendFundsImageView.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
            sendFundsImageView.widthAnchor.constraint(equalToConstant: 46),
            sendFundsImageView.heightAnchor.constraint(equalToConstant: 46),

            amountLabel.centerYAnchor.constraint(equalTo: amountContainerView.centerYAnchor),
            amountLabel.leftAnchor.constraint(equalTo: amountContainerView.leftAnchor, constant: 16),

            tariIconView.centerYAnchor.constraint(equalTo: amountContainerView.centerYAnchor),
            tariIconView.rightAnchor.constraint(equalTo: amountContainerView.rightAnchor, constant: -16),
            tariIconView.widthAnchor.constraint(equalToConstant: 44),
            tariIconView.heightAnchor.constraint(equalToConstant: 44),

            userIconView.centerYAnchor.constraint(equalTo: addressContainerView.centerYAnchor),
            userIconView.rightAnchor.constraint(equalTo: addressContainerView.rightAnchor, constant: -16),
            userIconView.widthAnchor.constraint(equalToConstant: 44),
            userIconView.heightAnchor.constraint(equalToConstant: 44),

            userLabel.leftAnchor.constraint(equalTo: addressContainerView.leftAnchor, constant: 16),
            userLabel.centerYAnchor.constraint(equalTo: addressContainerView.centerYAnchor),

            feeView.topAnchor.constraint(equalTo: addressContainerView.bottomAnchor, constant: 24),
            feeView.widthAnchor.constraint(equalToConstant: 324),
            feeView.heightAnchor.constraint(equalToConstant: 48),
            feeView.centerXAnchor.constraint(equalTo: centerXAnchor),

            recipientView.topAnchor.constraint(equalTo: feeView.bottomAnchor, constant: 10),
            recipientView.widthAnchor.constraint(equalToConstant: 324),
            recipientView.heightAnchor.constraint(equalToConstant: 48),
            recipientView.centerXAnchor.constraint(equalTo: centerXAnchor),

            noteView.topAnchor.constraint(equalTo: recipientView.bottomAnchor, constant: 10),
            noteView.widthAnchor.constraint(equalToConstant: 324),
            noteView.heightAnchor.constraint(equalToConstant: 48),
            noteView.centerXAnchor.constraint(equalTo: centerXAnchor),

            totalLabel.leftAnchor.constraint(equalTo: noteView.leftAnchor),
            totalLabel.topAnchor.constraint(equalTo: noteView.bottomAnchor, constant: 16),

            totalValueLabel.rightAnchor.constraint(equalTo: noteView.rightAnchor),
            totalValueLabel.topAnchor.constraint(equalTo: noteView.bottomAnchor, constant: 14),

            sendButton.widthAnchor.constraint(equalToConstant: 342),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
            sendButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            sendButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -8),

            cancelButton.widthAnchor.constraint(equalToConstant: 342),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = .Background.secondary
        titleLabel.textColor = .Text.primary
        amountLabel.textColor = .Text.primary

        totalLabel.textColor = .Text.primary
        totalValueLabel.textColor = .Text.primary

        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        if isDarkMode {
            amountContainerView.apply(shadow: nil)
            amountContainerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.12)
            addressContainerView.apply(shadow: nil)
            addressContainerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.12)
        } else {
            amountContainerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            amountContainerView.apply(shadow: Shadow(color: .Light.Shadows.box, opacity: 0.8, radius: 8.5, offset: CGSize(width: -1.0, height: 6.5)))

            addressContainerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            addressContainerView.apply(shadow: Shadow(color: .Light.Shadows.box, opacity: 0.8, radius: 8.5, offset: CGSize(width: -1.0, height: 6.5)))
        }
    }
}
