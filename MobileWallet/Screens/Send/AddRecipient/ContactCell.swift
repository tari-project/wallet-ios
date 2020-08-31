//  ContactCell.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/02/11
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

class ContactCell: UITableViewCell {
    private let sidePadding = Theme.shared.sizes.appSidePadding
    private let CONTACT_LETTER_VIEW_SIZE: CGFloat = 44
    private let CONTACT_LETTER_VIEW_RADIUS: CGFloat = 12

    private let cellView = UIView()
    private let contactLetterView = UIView()
    private let contactLetter = UILabel()
    private let aliasLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView()

    private let unknownContactImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.cellView.alpha = 0.6
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.cellView.alpha = 1
            })
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)

        // Configure the view for the selected state
    }

    private func setup() {
        backgroundColor = .clear

        // Container view
        cellView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cellView)
        cellView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        cellView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        cellView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sidePadding).isActive = true
        cellView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sidePadding).isActive = true

        // Contact "image"
        contactLetterView.translatesAutoresizingMaskIntoConstraints = false
        cellView.addSubview(contactLetterView)
        contactLetterView.backgroundColor = Theme.shared.colors.contactCellImageBackground
        contactLetterView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        contactLetterView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor).isActive = true
        contactLetterView.heightAnchor.constraint(equalToConstant: CONTACT_LETTER_VIEW_SIZE).isActive = true
        contactLetterView.widthAnchor.constraint(equalToConstant: CONTACT_LETTER_VIEW_SIZE).isActive = true
        contactLetterView.layer.cornerRadius = CONTACT_LETTER_VIEW_RADIUS
        contactLetterView.clipsToBounds = true

        // Label inside contact image
        contactLetter.translatesAutoresizingMaskIntoConstraints = false
        contactLetter.text = ""
        contactLetter.textColor = Theme.shared.colors.contactCellImage
        contactLetter.font = Theme.shared.fonts.contactCellAliasLetter
        contactLetterView.addSubview(contactLetter)
        contactLetter.centerXAnchor.constraint(equalTo: contactLetterView.centerXAnchor).isActive = true
        contactLetter.centerYAnchor.constraint(equalTo: contactLetterView.centerYAnchor).isActive = true

        // Unknow "image"
        unknownContactImageView.isHidden = true
        unknownContactImageView.contentMode = .center
        unknownContactImageView.image = Theme.shared.images.unknownUser
        contactLetterView.addSubview(unknownContactImageView)

        unknownContactImageView.translatesAutoresizingMaskIntoConstraints = false

        unknownContactImageView.widthAnchor.constraint(equalTo: contactLetterView.widthAnchor).isActive = true
        unknownContactImageView.heightAnchor.constraint(equalTo: contactLetterView.heightAnchor).isActive = true
        unknownContactImageView.centerYAnchor.constraint(equalTo: contactLetterView.centerYAnchor).isActive = true
        unknownContactImageView.centerXAnchor.constraint(equalTo: contactLetterView.centerXAnchor).isActive = true

        // Alias label
        aliasLabel.textColor = Theme.shared.colors.contactCellAlias
        aliasLabel.font = Theme.shared.fonts.contactCellAlias
        aliasLabel.translatesAutoresizingMaskIntoConstraints = false
        cellView.addSubview(aliasLabel)

        aliasLabel.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        aliasLabel.leadingAnchor.constraint(equalTo: contactLetterView.trailingAnchor, constant: 10).isActive = true
        aliasLabel.trailingAnchor.constraint(equalTo: cellView.trailingAnchor).isActive = true
        aliasLabel.heightAnchor.constraint(equalToConstant: aliasLabel.font.pointSize * 1.15).isActive = true

        // yat lookup activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .medium
        activityIndicator.color = .lightGray
        cellView.addSubview(activityIndicator)
        activityIndicator.stopAnimating()

        activityIndicator.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        activityIndicator.trailingAnchor.constraint(equalTo: cellView.trailingAnchor).isActive = true
    }

    func setYat(_ yat: String, yatLookupIsInProgress: Bool) {
        aliasLabel.textColor = Theme.shared.colors.contactCellAlias
        aliasLabel.text = String.init(format: NSLocalizedString("add_recipient.send_to_yat.with_param", comment: ""), yat)
        contactLetter.text = ""
        unknownContactImageView.isHidden = false
        if yatLookupIsInProgress {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    func setTx(_ tx: TxProtocol) {
        if let contact = tx.contact.0 {
            setContact(contact)
        } else {
            aliasLabel.textColor = Theme.shared.colors.emojisSeparator!
            contactLetter.text = ""
            unknownContactImageView.isHidden = false
            switch tx.direction {
            case .inbound:
                if let yat = tx.message.0.sourceYat {
                    aliasLabel.text = yat
                } else {
                    let emojis = tx.sourcePublicKey.0!.emojis.0
                    aliasLabel.text = "\(emojis.prefix(3))•••\(emojis.suffix(3))"
                }
            case .outbound:
                if let yat = tx.message.0.destinationYat {
                    aliasLabel.text = yat
                } else {
                    let emojis = tx.destinationPublicKey.0!.emojis.0
                    aliasLabel.text = "\(emojis.prefix(3))•••\(emojis.suffix(3))"
                }
            case .none:
                aliasLabel.text = ""
            }
        }

    }

    func setContact(_ contact: Contact) {
        let (alias, _) = contact.alias
        var aliasDisplay = alias
        if aliasDisplay.isEmpty, let emojis = contact.publicKey.0?.emojis.0 {
            aliasLabel.textColor = Theme.shared.colors.emojisSeparator!
            aliasDisplay = "\(emojis.prefix(3))•••\(emojis.suffix(3))"
        } else {
            aliasLabel.textColor = Theme.shared.colors.contactCellAlias
        }

        aliasLabel.text = aliasDisplay

        if !alias.isEmpty {
            contactLetter.text = String(alias.prefix(1)).uppercased()
            unknownContactImageView.isHidden = true
        } else {
            contactLetter.text = ""
            unknownContactImageView.isHidden = false
        }
    }
}
