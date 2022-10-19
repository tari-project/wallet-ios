//  TxTableViewCell.swift

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

class TxTableViewCell: UITableViewCell {
    private let avatarContainer = UIView()
    private let labelsContainer = UIView()
    private let avatarLabel = UILabel()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusLabel = UILabel()
    private var statusLabelHeightHidden = NSLayoutConstraint()
    private let noteLabel = UILabel()
    private let valueContainer = UIView()
    private let valueLabel = UILabelWithPadding()
    private var attachmentView: GPHMediaView?
    private let loadingGifButton = LoadingGIFButton()

    var updateCell: (() -> Void)?
    weak var model: TxTableViewModel?

    private var kvoTime: NSKeyValueObservation?
    private var kvoGif: NSKeyValueObservation?
    private var kvoGifFailure: NSKeyValueObservation?
    private var kvoStatus: NSKeyValueObservation?

    private static let topCellPadding: CGFloat = 0
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

    func configure(with model: TxTableViewModel) {
        setStatus(model.status)
        setValue(
            microTari: model.value.microTari,
            isOutboundTransaction: model.value.isOutboundTransaction,
            isCancelled: model.value.isCancelled,
            isPending: model.value.isPending
        )

        if model.id == self.model?.id { return }

        self.model = model
        avatarLabel.text = model.avatar
        noteLabel.text = model.message
        titleLabel.attributedText = model.title
        timeLabel.text = model.time

        if model.hasGif {
            loadingGifButton.isHidden = false
        } else {
            loadingGifButton.isHidden = true
        }
        observe(item: model)
        setGif(media: model.gif)
    }

    private func observe(item: TxTableViewModel) {
        stopObservation()
        kvoGif = item.observe(\.gif, options: .new) { [weak self] (_, _) in
            self?.updateCell?()
        }

        kvoGifFailure = item.observe(\.gifDownloadFailed, options: .new) { [weak self] (_, _) in
            if item.gifDownloadFailed {
                DispatchQueue.main.async { [weak self] in
                    self?.loadingGifButton.isHidden = false
                    self?.loadingGifButton.variation = .retry
                }
            }
        }

        kvoStatus = item.observe(\.status, options: .new) {
            (_, _) in
            DispatchQueue.main.async {
                [weak self] in
                guard let self = self, let model = self.model else { return }
                self.setStatus(item.status)
                self.setValue(
                    microTari: model.value.microTari,
                    isOutboundTransaction: model.value.isOutboundTransaction,
                    isCancelled: model.value.isCancelled,
                    isPending: model.value.isPending
                )
            }
        }

        kvoTime = item.observe(\.time, options: .new) {
            (_, _) in
            DispatchQueue.main.async {
                [weak self] in
                self?.timeLabel.text = item.time
            }
        }
    }

    private func stopObservation() {
        kvoGif?.invalidate()
        kvoStatus?.invalidate()
        kvoTime?.invalidate()
        kvoGif = nil
        kvoStatus = nil
        kvoTime = nil
    }

    private func setGif(media: GPHMedia?) {
        if model?.hasGif == false || media != nil {
            loadingGifButton.isHidden = true
        }

        if media != nil {
            if media?.id == attachmentView?.media?.id { return }
            setupAttachmentView()
            attachmentView?.setMedia(media!)
        } else {
            attachmentView?.removeFromSuperview()
            attachmentView = nil
        }
    }

    private func setStatus(_ status: String) {
        statusLabel.text = status

        if statusLabel.text?.isEmpty ?? true {
            statusLabelHeightHidden.isActive = true
        } else {
            statusLabelHeightHidden.isActive = false
        }
    }

    private func setValue(microTari: MicroTari?, isOutboundTransaction: Bool, isCancelled: Bool, isPending: Bool) {
        if let mt = microTari {
            if isCancelled {
                valueLabel.text = mt.formattedPrecise
                valueLabel.backgroundColor = Theme.shared.colors.txCellValueCancelledBackground
                valueLabel.textColor = Theme.shared.colors.txCellValueCancelledText
            } else if isOutboundTransaction {
                valueLabel.text = mt.formattedWithNegativeOperator
                valueLabel.backgroundColor = Theme.shared.colors.txCellValueNegativeBackground
                valueLabel.textColor = Theme.shared.colors.txCellValueNegativeText
            } else {
                valueLabel.text = mt.formattedWithOperator
                valueLabel.backgroundColor = Theme.shared.colors.txCellValuePositiveBackground
                valueLabel.textColor = Theme.shared.colors.txCellValuePositiveText
            }

            if isPending && !isCancelled {
                valueLabel.backgroundColor = Theme.shared.colors.txCellValuePendingBackground
                valueLabel.textColor = Theme.shared.colors.txCellValuePendingText
            }
        } else {
            // Unlikely to happen scenario
            valueLabel.text = "0"
            valueLabel.backgroundColor = Theme.shared.colors.txTableBackground
            valueLabel.textColor = Theme.shared.colors.txScreenTextLabel
        }
        // fix to 2 decimal places
        if let text = valueLabel.text, let distance = text.indexDistance(of: MicroTari.decimalSeparator) {
            let upperBound = text.index(
                text.startIndex,
                offsetBy: distance + MicroTari.decimalSeparator.count + 2
            )
            valueLabel.text = "\(text[text.startIndex..<upperBound])"
        }

        valueLabel.padding = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
    }

    deinit {
        stopObservation()
    }
}

// MARK: setup subviews
extension TxTableViewCell {
    private func viewSetup() {
        contentView.backgroundColor = Theme.shared.colors.txTableBackground
        selectionStyle = .none

        setupAvatar()
        setupLabels()
    }

    private func setupAvatar() {
        contentView.addSubview(avatarContainer)

        avatarContainer.backgroundColor = Theme.shared.colors.txTableBackground

        avatarContainer.translatesAutoresizingMaskIntoConstraints = false

        let size: CGFloat = 42
        avatarContainer.widthAnchor.constraint(equalToConstant: size).isActive = true
        avatarContainer.heightAnchor.constraint(equalToConstant: size).isActive = true
        avatarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        avatarContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: TxTableViewCell.topCellPadding).isActive = true
        avatarContainer.layer.cornerRadius = size / 2

        avatarContainer.layer.shadowOpacity = 0.13
        avatarContainer.layer.shadowOffset = CGSize(width: 10, height: 10)
        avatarContainer.layer.shadowRadius = 10
        avatarContainer.layer.shadowColor = Theme.shared.colors.defaultShadow?.cgColor

        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(avatarLabel)
        avatarLabel.font = UIFont.systemFont(ofSize: size * 0.55)
        avatarLabel.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor).isActive = true
        avatarLabel.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor).isActive = true
    }

    private func setupLabels() {
        // MARK: - Label container
        labelsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(labelsContainer)

        labelsContainer.addBottomBorder(with: Theme.shared.colors.txCellBorder, andWidth: 1)
        labelsContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: TxTableViewCell.topCellPadding).isActive = true
        labelsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -25 + TxTableViewCell.topCellPadding).isActive = true
        labelsContainer.leadingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        labelsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true

        // MARK: - Value
        valueContainer.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.numberOfLines = 1
        valueLabel.font = Theme.shared.fonts.txCellValueLabel
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
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: labelsContainer.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: valueContainer.leadingAnchor, constant: -4).isActive = true

        // MARK: - Time
        labelsContainer.addSubview(timeLabel)
        timeLabel.font = Theme.shared.fonts.txDateValueLabel
        timeLabel.textColor = Theme.shared.colors.txSmallSubheadingLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5).isActive = true
        timeLabel.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: labelsContainer.trailingAnchor).isActive = true

        // MARK: - Status
        labelsContainer.addSubview(statusLabel)
        statusLabel.font = Theme.shared.fonts.txCellStatusLabel
        statusLabel.textColor = Theme.shared.colors.txCellStatusLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 5).isActive = true
        statusLabel.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: labelsContainer.trailingAnchor).isActive = true
        statusLabelHeightHidden = statusLabel.heightAnchor.constraint(equalToConstant: 0)

        // MARK: - TX note
        labelsContainer.addSubview(noteLabel)
        noteLabel.font = Theme.shared.fonts.txCellDescriptionLabel
        noteLabel.textColor = Theme.shared.colors.txCellNote
        noteLabel.lineBreakMode = .byWordWrapping
        noteLabel.numberOfLines = 0
        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        noteLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5).isActive = true
        noteLabel.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor).isActive = true
        noteLabel.trailingAnchor.constraint(equalTo: labelsContainer.trailingAnchor).isActive = true
        noteLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelsContainer.bottomAnchor, constant: -25).isActive = true
        // MARK: - Loading gif button
        loadingGifButton.variation = model?.gifDownloadFailed == true ? .retry : .loading
        labelsContainer.addSubview(loadingGifButton)
        loadingGifButton.addTarget(self, action: #selector(loadingGifButtonAction(_:)), for: .touchUpInside)
        loadingGifButton.translatesAutoresizingMaskIntoConstraints = false
        loadingGifButton.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 5).isActive = true
        loadingGifButton.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor).isActive = true
        loadingGifButton.trailingAnchor.constraint(equalTo: labelsContainer.trailingAnchor).isActive = true
    }

    private func setupAttachmentView() {
        attachmentView?.removeFromSuperview()
        attachmentView = GPHMediaView()

        guard let attachmentView = self.attachmentView, let media = model?.gif else { return }

        attachmentView.clipsToBounds = true
        attachmentView.layer.cornerRadius = 4
        labelsContainer.addSubview(attachmentView)
        attachmentView.translatesAutoresizingMaskIntoConstraints = false
        attachmentView.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 5).isActive = true
        attachmentView.leadingAnchor.constraint(equalTo: labelsContainer.leadingAnchor).isActive = true
        attachmentView.trailingAnchor.constraint(equalTo: labelsContainer.trailingAnchor).isActive = true

        let heightConstraint = attachmentView.heightAnchor.constraint(equalTo: attachmentView.widthAnchor, multiplier: 1 / media.aspectRatio)
        attachmentView.bottomAnchor.constraint(equalTo: labelsContainer.bottomAnchor, constant: -40).isActive = true

        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }

    @objc private func loadingGifButtonAction(_ sender: UIButton) {
        loadingGifButton.variation = .loading
        loadingGifButton.isHidden = false
        model?.downloadGif()
    }
}
