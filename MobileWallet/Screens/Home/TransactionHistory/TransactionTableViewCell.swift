//  TransactionTableTableViewCell.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/10/31
	Using Swift 5.0
	Running on macOS 10.15

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

import UIKit

class TransactionTableViewCell: UITableViewCell {
    private let BACKGROUND_COLOR = Theme.shared.colors.transactionTableBackground

    private let icon = UIImageView()
    private let userNameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let valueLabel = UILabelWithPadding()

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.contentView.alpha = 0.6
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.contentView.alpha = 1
            })
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewSetup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setValue(microTari: MicroTari?, direction: TransactionDirection, isCancelled: Bool = false) {
        if let mt = microTari {
            if isCancelled {
                valueLabel.text = mt.formatted
                valueLabel.backgroundColor = Theme.shared.colors.transactionCellValueCancelledBackground
                valueLabel.textColor = Theme.shared.colors.transactionCellValueCancelledText
            } else if direction == .inbound {
                valueLabel.text = mt.formattedWithOperator
                valueLabel.backgroundColor = Theme.shared.colors.transactionCellValuePositiveBackground
                valueLabel.textColor = Theme.shared.colors.transactionCellValuePositiveText
            } else {
                valueLabel.text = mt.formattedWithNegativeOperator
                valueLabel.backgroundColor = Theme.shared.colors.transactionCellValueNegativeBackground
                valueLabel.textColor = Theme.shared.colors.transactionCellValueNegativeText
            }
        } else {
            //Unlikely to happen scenario
            valueLabel.text = "0"
            valueLabel.backgroundColor = Theme.shared.colors.transactionTableBackground
            valueLabel.textColor = Theme.shared.colors.transactionScreenTextLabel
        }

        valueLabel.padding = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
    }

    private func setMessage(_ message: String) {
        descriptionLabel.text = !message.isEmpty ? message : "*Missing message*"
        descriptionLabel.sizeToFit()
    }

    private func setAlias(_ contact: Contact) {
        let (alias, _) = contact.alias
        if !alias.isEmpty {
            //In contacts but alias is blank
            userNameLabel.text = alias
            userNameLabel.textColor = Theme.shared.colors.transactionCellAlias
        } else {
            if let pubKey = contact.publicKey.0 {
                setEmojis(pubKey)
            }
        }
    }

    private func setEmojis(_ pubKey: PublicKey) {
        let (emojis, _) = pubKey.emojis
        let shortEmojisStr = "\(String(emojis.emojis.prefix(3)))•••\(String(emojis.emojis.suffix(3)))"
        userNameLabel.text = shortEmojisStr
        userNameLabel.textColor = Theme.shared.colors.emojisSeparator
    }

    func setDetails(completedTransaction: CompletedTransaction) {
        setMessage(completedTransaction.message.0)
        setValue(microTari: completedTransaction.microTari.0, direction: completedTransaction.direction, isCancelled: completedTransaction.isCancelled)
        if let contact = completedTransaction.contact.0 {
            setAlias(contact)
        } else {
            if completedTransaction.direction == .inbound {
                let (publicKey, _) = completedTransaction.sourcePublicKey
                if let pubKey = publicKey {
                    setEmojis(pubKey)
                }
            } else if completedTransaction.direction == .outbound {
                let (publicKey, _) = completedTransaction.destinationPublicKey
                if let pubKey = publicKey {
                    setEmojis(pubKey)
                }
            }
        }
    }

    func setDetails(pendingInboundTransaction: PendingInboundTransaction) {
        setMessage(pendingInboundTransaction.message.0)
        setValue(microTari: pendingInboundTransaction.microTari.0, direction: pendingInboundTransaction.direction)
        if let contact = pendingInboundTransaction.contact.0 {
            setAlias(contact)
        } else {
            let (publicKey, _) = pendingInboundTransaction.sourcePublicKey
            if let pubKey = publicKey {
                setEmojis(pubKey)
            }
        }
    }

    func setDetails(pendingOutboundTransaction: PendingOutboundTransaction) {
        setMessage(pendingOutboundTransaction.message.0)
        setValue(microTari: pendingOutboundTransaction.microTari.0, direction: pendingOutboundTransaction.direction)
        if let contact = pendingOutboundTransaction.contact.0 {
            setAlias(contact)
        } else {
            let (publicKey, _) = pendingOutboundTransaction.destinationPublicKey
            if let pubKey = publicKey {
                setEmojis(pubKey)
            }
        }
    }
}

// MARK: setup subviews
extension TransactionTableViewCell {
    private func viewSetup() {
        contentView.backgroundColor = BACKGROUND_COLOR
        selectionStyle = .none

        setupIcon()
        setupValueLabel()
        setupLabels()
    }

    private func setupIcon() {
        contentView.addSubview(icon)

        icon.image = Theme.shared.images.transfer

        icon.translatesAutoresizingMaskIntoConstraints = false

        icon.widthAnchor.constraint(equalToConstant: 44).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 44).isActive = true
        icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25).isActive = true
        icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    }

    private func setupValueLabel() {
        contentView.addSubview(valueLabel)

        valueLabel.font = Theme.shared.fonts.transactionCellValueLabel
        valueLabel.layer.cornerRadius = 3
        valueLabel.layer.masksToBounds = true

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25).isActive = true

        valueLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .vertical)
        valueLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 252), for: .horizontal)
    }

    private func setupLabels() {
        let containerLabels = UIView()
        containerLabels.backgroundColor = .clear
        contentView.addSubview(containerLabels)

        containerLabels.translatesAutoresizingMaskIntoConstraints = false
        containerLabels.heightAnchor.constraint(equalToConstant: 40).isActive = true
        containerLabels.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        containerLabels.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 20).isActive = true
        containerLabels.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -8).isActive = true

        contentView.addSubview(userNameLabel)

        userNameLabel.font = Theme.shared.fonts.transactionCellUsernameLabel
        userNameLabel.textColor = Theme.shared.colors.transactionCellAlias
        userNameLabel.text = ""
        userNameLabel.lineBreakMode = .byTruncatingMiddle

        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        userNameLabel.topAnchor.constraint(equalTo: containerLabels.topAnchor).isActive = true
        userNameLabel.leadingAnchor.constraint(equalTo: containerLabels.leadingAnchor).isActive = true
        userNameLabel.trailingAnchor.constraint(equalTo: containerLabels.trailingAnchor).isActive = true

        contentView.addSubview(descriptionLabel)

        descriptionLabel.font = Theme.shared.fonts.transactionCellDescriptionLabel
        descriptionLabel.textColor = Theme.shared.colors.transactionCellDescription
        descriptionLabel.lineBreakMode = .byTruncatingTail

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.bottomAnchor.constraint(equalTo: containerLabels.bottomAnchor).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: containerLabels.leadingAnchor).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: containerLabels.trailingAnchor).isActive = true
    }
}
