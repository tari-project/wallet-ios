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
import GiphyUISDK
import GiphyCoreSDK

class TransactionTableViewCell: UITableViewCell {
    static var mediaCache: [String: GPHMedia] = [:]

    private let avatarContainer = UIView()
    private let avatarLabel = UILabel()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusLabel = UILabel()
    private var statusLabelHeightHidden = NSLayoutConstraint()
    private let noteLabel = UILabel()
    private let valueContainer = UIView()
    private let valueLabel = UILabelWithPadding()
    private let attachmentViewContainer = GPHMediaView()
    private let attachmentView = GPHMediaView()
    private var attachmentViewHeightContraint = NSLayoutConstraint()

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

    private func setValue(microTari: MicroTari?, direction: TransactionDirection, isCancelled: Bool, isPending: Bool) {
        if let mt = microTari {
            if isCancelled {
                valueLabel.text = mt.formatted
                valueLabel.backgroundColor = Theme.shared.colors.transactionCellValueCancelledBackground
                valueLabel.textColor = Theme.shared.colors.transactionCellValueCancelledText
            } else if direction == .inbound {
                valueLabel.text = mt.formattedWithOperator
                valueLabel.backgroundColor = Theme.shared.colors.transactionCellValuePositiveBackground
                valueLabel.textColor = Theme.shared.colors.transactionCellValuePositiveText
            } else if direction == .outbound {
                valueLabel.text = mt.formattedWithNegativeOperator
                valueLabel.backgroundColor = Theme.shared.colors.transactionCellValueNegativeBackground
                valueLabel.textColor = Theme.shared.colors.transactionCellValueNegativeText
            }

            if isPending {
                valueLabel.backgroundColor = Theme.shared.colors.transactionCellValuePendingBackground
                valueLabel.textColor = Theme.shared.colors.transactionCellValuePendingText
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
        //Extract the giphy link
        let giphyLinkPrefix = "https://giphy.com/embed/"

        if let endIndex = message.range(of: giphyLinkPrefix)?.lowerBound {
            let messageExcludingLink = message[..<endIndex].trimmingCharacters(in: .whitespaces)
            let link = message[endIndex...].trimmingCharacters(in: .whitespaces)
            let giphyId = link.replacingOccurrences(of: giphyLinkPrefix, with: "")

            noteLabel.text = messageExcludingLink

            //Check cache first
            if let cachedMedia = TransactionTableViewCell.mediaCache[giphyId] {
                self.setMedia(cachedMedia)
            } else {
                GiphyCore.shared.gifByID(giphyId) { (response, error) in
                    guard error == nil else {
                        return TariLogger.error("Failed to load gif", error: error)
                    }

                    if let media = response?.data {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.setMedia(media)
                            TransactionTableViewCell.mediaCache[giphyId] = media
                        }
                    }
                }
            }

        } else {
            noteLabel.text = message
            attachmentView.media = nil
            setMediaVisible(aspectRatio: nil)
        }

        noteLabel.sizeToFit()
    }

    private func setMedia(_ media: GPHMedia) {
        attachmentView.media = media
        setMediaVisible(aspectRatio: media.aspectRatio)
    }

    private func setMediaVisible(aspectRatio: CGFloat?) {
        attachmentViewHeightContraint.isActive = false
        if var ratio = aspectRatio {
            ratio = ratio > 1 ? ratio - 1 : ratio
            //TODO when the height is set correctly then they layout constraints break
            attachmentViewHeightContraint = attachmentView.heightAnchor.constraint(equalTo: attachmentView.widthAnchor, multiplier: ratio)
        } else {
            attachmentViewHeightContraint = attachmentViewContainer.heightAnchor.constraint(equalToConstant: 0)
        }
        attachmentViewHeightContraint.priority = .defaultHigh
        attachmentViewHeightContraint.isActive = true
    }

    private func setAvatar(_ pubKey: PublicKey) {
        let (emojis, _) = pubKey.emojis
        avatarLabel.text = String(emojis.emojis.prefix(1))
    }

    func setDetails(_ tx: TransactionProtocol) {
        var isCancelled = false
        var isPending = false

        let (publicKey, _) = tx.direction == .inbound ? tx.sourcePublicKey : tx.destinationPublicKey
        guard let pubKey = publicKey else { return }

        if let _ = tx as? PendingInboundTransaction {
            isPending = true
        }

        if let _ = tx as? PendingOutboundTransaction {
            isPending = true
        }

        setAvatar(pubKey)

        var alias = ""
        var aliasIsEmojis = false
        if let contact = tx.contact.0 {
            alias = contact.alias.0
        }

        if alias.isEmpty {
            let (emojis, _) = pubKey.emojis
            alias = "\(String(emojis.emojis.prefix(2)))•••\(String(emojis.emojis.suffix(2)))"
            aliasIsEmojis = true
        }

        var titleText = ""
        if tx.direction == .inbound {
            if isPending {
                titleText = String(
                    format: NSLocalizedString("tx_list.inbound_pending_title", comment: "Transaction list"),
                    alias
                )
            } else {
                titleText =  String(
                    format: NSLocalizedString("tx_list.inbound_title", comment: "Transaction list"),
                    alias
                )
            }
        } else if tx.direction == .outbound {
            titleText =  String(
                format: NSLocalizedString("tx_list.outbound_title", comment: "Transaction list"),
                alias
            )
        }

        //Getting the line breaks around the alias an not the other spaces in the copy
        titleText = titleText
            .replacingOccurrences(of: " ", with: "\u{00A0}")
            .replacingOccurrences(of: alias, with: " \(alias) ")
            .trimmingCharacters(in: .whitespaces)

        if let startIndex = titleText.indexDistance(of: alias) {
            let attributedTitle = NSMutableAttributedString(
                string: titleText,
                attributes: [
                    .font: Theme.shared.fonts.transactionCellUsernameLabel,
                    .foregroundColor: Theme.shared.colors.transactionCellAlias!
                ]
            )

            let range = NSRange(location: startIndex, length: alias.count)
            attributedTitle.addAttribute(.font, value: Theme.shared.fonts.transactionCellUsernameLabelHeavy, range: range)
            if aliasIsEmojis {
                //So the elippises between the emojis is lighter
                attributedTitle.addAttribute(.foregroundColor, value: Theme.shared.colors.emojisSeparator!, range: range)
            }

            titleLabel.attributedText = attributedTitle
        }

        statusLabel.text = ""
        statusLabelHeightHidden.isActive = true

        var statusMessage = ""

        //Cancelled tranaction
        if let compledTx = tx as? CompletedTransaction {
            if compledTx.isCancelled {
                isCancelled = true
                statusMessage = "Transaction Cancelled"
            }
        }

        switch tx.status.0 {
        case .pending:
            if tx.direction == .inbound {
                statusMessage = NSLocalizedString("refresh_view.waiting_for_sender", comment: "Refresh view")
            } else if tx.direction == .outbound {
                statusMessage = NSLocalizedString("refresh_view.waiting_for_recipient", comment: "Refresh view")
            }
        case .broadcast, .completed:
            statusMessage = NSLocalizedString("refresh_view.final_processing", comment: "Refresh view")
        default:
            statusMessage = ""
        }

        if statusMessage.isEmpty {
            statusLabel.text = ""
            statusLabelHeightHidden.isActive = true
        } else {
            statusLabel.text = statusMessage
            statusLabelHeightHidden.isActive = false
        }

        setValue(microTari: tx.microTari.0, direction: tx.direction, isCancelled: isCancelled, isPending: isPending)
        setMessage(tx.message.0)
        timeLabel.text = tx.date.0?.relativeDayFromToday() ?? ""
    }
}

// MARK: setup subviews
extension TransactionTableViewCell {
    private func viewSetup() {
        contentView.backgroundColor = Theme.shared.colors.transactionTableBackground
        selectionStyle = .none

        setupAvatar()
        setupLabels()
    }

    private func setupAvatar() {
        contentView.addSubview(avatarContainer)

        avatarContainer.backgroundColor = Theme.shared.colors.transactionTableBackground

        avatarContainer.translatesAutoresizingMaskIntoConstraints = false

        let size: CGFloat = 42
        avatarContainer.widthAnchor.constraint(equalToConstant: size).isActive = true
        avatarContainer.heightAnchor.constraint(equalToConstant: size).isActive = true
        avatarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        avatarContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        avatarContainer.layer.cornerRadius = size / 2

        avatarContainer.layer.shadowOpacity = 0.13
        avatarContainer.layer.shadowOffset = CGSize(width: 10, height: 10)
        avatarContainer.layer.shadowRadius = 23
        avatarContainer.layer.shadowColor = Theme.shared.colors.defaultShadow?.cgColor

        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(avatarLabel)
        avatarLabel.font = UIFont.systemFont(ofSize: size * 0.55)
        avatarLabel.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor).isActive = true
        avatarLabel.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor).isActive = true
    }

    private func setupLabels() {
        // MARK: - Label container
        let labelsContainer = UIView()
        labelsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelsContainer)

        labelsContainer.addBottomBorder(with: Theme.shared.colors.transactionCellBorder, andWidth: 1)
        labelsContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
        labelsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -25).isActive = true
        labelsContainer.leadingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        labelsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true

        // MARK: - Value
        valueContainer.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.numberOfLines = 1
        valueLabel.font = Theme.shared.fonts.transactionCellValueLabel
        valueLabel.layer.cornerRadius = 3
        valueLabel.layer.masksToBounds = true
        valueLabel.centerYAnchor.constraint(equalTo: valueContainer.centerYAnchor).isActive = true
        valueLabel.trailingAnchor.constraint(equalTo: valueContainer.trailingAnchor).isActive = true

        valueLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .vertical)
        valueLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)

        labelsContainer.addSubview(valueContainer)
        valueContainer.translatesAutoresizingMaskIntoConstraints = false
        valueContainer.topAnchor.constraint(equalTo: labelsContainer.topAnchor).isActive = true
        valueContainer.trailingAnchor.constraint(equalTo: labelsContainer.trailingAnchor).isActive = true
        valueContainer.heightAnchor.constraint(equalToConstant: 23).isActive = true
        valueContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true

        // MARK: - Title/alias
        labelsContainer.addSubview(titleLabel)
        titleLabel.text = ""
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: labelsContainer.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: valueContainer.leadingAnchor, constant: -4).isActive = true

        // MARK: - Time
        labelsContainer.addSubview(timeLabel)
        timeLabel.font = Theme.shared.fonts.transactionDateValueLabel
        timeLabel.textColor = Theme.shared.colors.transactionSmallSubheadingLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5).isActive = true
        timeLabel.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: labelsContainer.trailingAnchor).isActive = true

        // MARK: - Status
        labelsContainer.addSubview(statusLabel)
        statusLabel.font = Theme.shared.fonts.transactionCellStatusLabel
        statusLabel.textColor = Theme.shared.colors.transactionCellStatusLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 5).isActive = true
        statusLabel.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: labelsContainer.trailingAnchor).isActive = true
        statusLabelHeightHidden = statusLabel.heightAnchor.constraint(equalToConstant: 0)
        statusLabelHeightHidden.isActive = true

        // MARK: - TX note
        labelsContainer.addSubview(noteLabel)
        noteLabel.font = Theme.shared.fonts.transactionCellDescriptionLabel
        noteLabel.textColor = Theme.shared.colors.transactionCellNote
        noteLabel.lineBreakMode = .byWordWrapping
        noteLabel.numberOfLines = 0
        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        noteLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5).isActive = true
        noteLabel.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor).isActive = true
        noteLabel.trailingAnchor.constraint(equalTo: labelsContainer.trailingAnchor).isActive = true

        // MARK: - Media attachment
        attachmentViewContainer.backgroundColor = .lightGray //TODO ask for a color
        attachmentViewContainer.clipsToBounds = true
        attachmentViewContainer.layer.cornerRadius = 4
        labelsContainer.addSubview(attachmentViewContainer)
        attachmentViewContainer.translatesAutoresizingMaskIntoConstraints = false
        attachmentViewContainer.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 5).isActive = true
        attachmentViewContainer.bottomAnchor.constraint(equalTo: labelsContainer.bottomAnchor, constant: -25).isActive = true
        attachmentViewContainer.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor).isActive = true
        attachmentViewContainer.trailingAnchor.constraint(equalTo: labelsContainer.trailingAnchor).isActive = true
        attachmentViewHeightContraint = attachmentViewContainer.heightAnchor.constraint(equalToConstant: 0)
        attachmentViewHeightContraint.isActive = true

        attachmentViewContainer.addSubview(attachmentView)
        attachmentView.translatesAutoresizingMaskIntoConstraints = false
        attachmentView.topAnchor.constraint(equalTo: attachmentViewContainer.topAnchor).isActive = true
        attachmentView.bottomAnchor.constraint(equalTo: attachmentViewContainer.bottomAnchor).isActive = true
        attachmentView.leadingAnchor.constraint(equalTo: attachmentViewContainer.leadingAnchor).isActive = true
        attachmentView.trailingAnchor.constraint(equalTo: attachmentViewContainer.trailingAnchor).isActive = true
    }
}
