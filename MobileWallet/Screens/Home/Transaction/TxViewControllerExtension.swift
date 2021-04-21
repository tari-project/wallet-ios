//  TxViewControllerExtension.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/28
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

extension TxViewController {
    func setupNavigationBar() {
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        navigationBarHeightAnchor = navigationBar.heightAnchor.constraint(equalToConstant: navBarHeightConstant)
        navigationBarHeightAnchor.isActive = true
    }

    func setupValueView() {
        valueContainerView = UIView()
        valueContainerView.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.backgroundColor = Theme.shared.colors.txViewValueContainer
        stackView.addArrangedSubview(valueContainerView)
        valueContainerViewHeightAnchor = valueContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: valueViewHeightMultiplierFull)
        valueContainerViewHeightAnchor.isActive = true

        view.sendSubviewToBack(scrollView)
        scrollView.sendSubviewToBack(valueContainerView)

        // Value label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(valueLabel)

        valueLabel.centerXAnchor.constraint(equalTo: valueContainerView.centerXAnchor).isActive = true
        valueCenterYAnchorConstraint = valueLabel.centerYAnchor.constraint(equalTo: valueContainerView.centerYAnchor)
        valueCenterYAnchorConstraint.isActive = true
        valueLabel.widthAnchor.constraint(lessThanOrEqualTo: valueContainerView.widthAnchor, constant: Theme.shared.sizes.appSidePadding * -4).isActive = true
        valueLabel.heightAnchor.constraint(equalToConstant: Theme.shared.fonts.txScreenCurrencyValueLabel.pointSize).isActive = true

        let valueColor = Theme.shared.colors.txViewValueLabel
        valueLabel.minimumScaleFactor = 0.2
        valueLabel.font = Theme.shared.fonts.txScreenCurrencyValueLabel
        valueLabel.textColor = valueColor
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.textAlignment = .center
        valueLabel.baselineAdjustment = .alignCenters

        // Currency image
        let valueImage = UIImageView()
        valueImage.image = Theme.shared.images.currencySymbol?.withTintColor(valueColor!)
        valueImage.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(valueImage)

        valueImage.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor).isActive = true
        valueImage.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -Theme.shared.sizes.appSidePadding / 2).isActive = true
        valueImage.heightAnchor.constraint(equalToConstant: 21).isActive = true
        valueImage.widthAnchor.constraint(equalToConstant: 21).isActive = true
        valueImage.contentMode = .scaleAspectFit
    }

    func setFeeLabel(_ feeText: String) {
        valueCenterYAnchorConstraint.constant = -20

        feeLabel.text = feeText
        feeLabel.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(feeLabel)

        feeLabel.centerXAnchor.constraint(equalTo: valueContainerView.centerXAnchor).isActive = true
        feeLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor).isActive = true
        feeLabel.font = Theme.shared.fonts.txFeeLabel
        feeLabel.textColor = Theme.shared.colors.txViewValueLabel

        feeButton.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(feeButton)
        feeButton.setTitle(localized("common.fee"), for: .normal)
        feeButton.titleLabel?.font = Theme.shared.fonts.txFeeButton
        feeButton.setRightImage(Theme.shared.images.txFee!)

        feeButton.topAnchor.constraint(equalTo: feeLabel.bottomAnchor, constant: 0).isActive = true
        feeButton.centerXAnchor.constraint(equalTo: valueContainerView.centerXAnchor).isActive = true
        feeButton.addTarget(self, action: #selector(feeButtonPressed), for: .touchUpInside)
    }

    func setupFromEmojis() {
        stackView.addArrangedSubview(fromContainerView)
        fromContainerView.heightAnchor.constraint(equalToConstant: 85).isActive = true

        fromHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        fromContainerView.addSubview(fromHeadingLabel)
        fromHeadingLabel.textColor = Theme.shared.colors.txScreenSubheadingLabel
        fromHeadingLabel.font = Theme.shared.fonts.txScreenSubheadingLabel
        fromHeadingLabel.topAnchor.constraint(equalTo: fromContainerView.topAnchor, constant: 20).isActive = true
        fromHeadingLabel.leadingAnchor.constraint(equalTo: fromContainerView.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true

        emojiIdView.translatesAutoresizingMaskIntoConstraints = false
        fromContainerView.addSubview(emojiIdView)
        emojiIdView.bottomAnchor.constraint(equalTo: fromContainerView.bottomAnchor, constant: -16).isActive = true
        emojiIdView.leadingAnchor.constraint(
            equalTo: fromContainerView.leadingAnchor,
            constant: Theme.shared.sizes.appSidePadding
        ).isActive = true
        emojiIdView.trailingAnchor.constraint(
            equalTo: fromContainerView.trailingAnchor,
            constant: -Theme.shared.sizes.appSidePadding
        ).isActive = true
        emojiIdView.cornerRadius = 12.0
    }

    func setupAddContactButton() {
        addContactButton.translatesAutoresizingMaskIntoConstraints = false
        fromContainerView.insertSubview(addContactButton, belowSubview: emojiIdView)
        addContactButton.topAnchor.constraint(equalTo: fromHeadingLabel.bottomAnchor, constant: bottomHeadingPadding).isActive = true
        addContactButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        addContactButton.setTitle(localized("tx_detail.add_contact_name"), for: .normal)
        addContactButton.setVariation(.secondary)
        addContactButton.addTarget(self, action: #selector(addContactButtonPressed), for: .touchUpInside)
    }

    func setupContactName() {
        stackView.addArrangedSubview(contactNameContainer)
        contactNameContainerViewHeightAnchor = contactNameContainer.heightAnchor.constraint(equalToConstant: 0)
        contactNameContainerViewHeightAnchor.isActive = true

        contactNameHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        contactNameContainer.addSubview(contactNameHeadingLabel)
        contactNameHeadingLabel.textColor = Theme.shared.colors.txScreenSubheadingLabel
        contactNameHeadingLabel.font = Theme.shared.fonts.txScreenSubheadingLabel
        contactNameHeadingLabel.text = localized("tx_detail.contact_name")
        contactNameHeadingLabelTopAnchor = contactNameHeadingLabel.topAnchor.constraint(equalTo: contactNameContainer.topAnchor, constant: headingLabelTopAnchorHeight)
        contactNameHeadingLabelTopAnchor.isActive = true
        contactNameHeadingLabel.leadingAnchor.constraint(equalTo: fromContainerView.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true

        contactNameTextField.translatesAutoresizingMaskIntoConstraints = false
        contactNameContainer.addSubview(contactNameTextField)
        contactNameTextField.textColor = Theme.shared.colors.txScreenTextLabel
        contactNameTextField.font = Theme.shared.fonts.txScreenTextLabel
        contactNameTextField.placeholder = localized("tx_detail.contect_name_placeholder")
        contactNameTextField.autocorrectionType = .no
        contactNameTextField.returnKeyType = .done
        contactNameTextField.delegate = self
        contactNameTextField.topAnchor.constraint(equalTo: contactNameHeadingLabel.bottomAnchor, constant: bottomHeadingPadding).isActive = true
//        contactNameTextField.bottomAnchor.constraint(equalTo: contactNameContainer.bottomAnchor, constant: -40).isActive = true
        contactNameTextField.leadingAnchor.constraint(equalTo: fromContainerView.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
    }

    func setupEditContactButton() {
        editContactNameButton.translatesAutoresizingMaskIntoConstraints = false
        contactNameContainer.addSubview(editContactNameButton)
        editContactNameButton.topAnchor.constraint(equalTo: contactNameHeadingLabel.bottomAnchor).isActive = true
        editContactNameButton.trailingAnchor.constraint(equalTo: contactNameContainer.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        editContactNameButton.setTitle(localized("tx_detail.edit"), for: .normal)
        editContactNameButton.setVariation(.secondary)
        editContactNameButton.addTarget(self, action: #selector(editContactButtonPressed), for: .touchUpInside)
    }

    func setupDivider() {
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(dividerView)
        dividerView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        dividerView.addSubview(divider)

        divider.bottomAnchor.constraint(equalTo: dividerView.bottomAnchor).isActive = true
        divider.leadingAnchor.constraint(equalTo: dividerView.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        divider.trailingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        divider.layer.borderWidth = 1
        divider.layer.borderColor = Theme.shared.colors.txScreenDivider!.cgColor
    }

    func setupNote() {
        let noteContainer = UIView()
        stackView.addArrangedSubview(noteContainer)
        noteHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        noteContainer.addSubview(noteHeadingLabel)
        noteHeadingLabel.textColor = Theme.shared.colors.txScreenSubheadingLabel
        noteHeadingLabel.font = Theme.shared.fonts.txScreenSubheadingLabel
        noteHeadingLabel.text = localized("tx_detail.note")
        noteHeadingLabel.topAnchor.constraint(equalTo: noteContainer.topAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        noteHeadingLabel.leadingAnchor.constraint(equalTo: noteContainer.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true

        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        noteContainer.addSubview(noteLabel)
        noteLabel.textColor = Theme.shared.colors.txScreenTextLabel
        noteLabel.font = Theme.shared.fonts.txScreenTextLabel
        noteLabel.numberOfLines = 0
        noteLabel.topAnchor.constraint(equalTo: noteHeadingLabel.bottomAnchor, constant: 10).isActive = true
        noteLabel.bottomAnchor.constraint(equalTo: noteContainer.bottomAnchor, constant: -10).isActive = true

        noteLabel.leadingAnchor.constraint(equalTo: noteContainer.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        noteLabel.trailingAnchor.constraint(equalTo: noteContainer.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        noteLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 100).isActive = true
    }

    func setNoteText(_ text: String) {
        let attributedTitleString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        attributedTitleString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedTitleString.length))
        noteLabel.attributedText = attributedTitleString
    }

    func setupGiphy() {
        attachmentSection.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(attachmentSection)

        let attachmentViewBorder = UIView()
        attachmentViewBorder.translatesAutoresizingMaskIntoConstraints = false
        attachmentViewBorder.clipsToBounds = true
        attachmentViewBorder.layer.cornerRadius = 20
        attachmentSection.addSubview(attachmentViewBorder)

        attachmentViewBorder.topAnchor.constraint(equalTo: attachmentSection.topAnchor).isActive = true
        attachmentViewBorder.leadingAnchor.constraint(equalTo: attachmentSection.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        attachmentViewBorder.trailingAnchor.constraint(equalTo: attachmentSection.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        attachmentViewBorder.bottomAnchor.constraint(equalTo: attachmentSection.bottomAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true

        attachmentView.translatesAutoresizingMaskIntoConstraints = false
        attachmentViewBorder.addSubview(attachmentView)
        attachmentView.topAnchor.constraint(equalTo: attachmentViewBorder.topAnchor).isActive = true
        attachmentView.bottomAnchor.constraint(equalTo: attachmentViewBorder.bottomAnchor).isActive = true
        attachmentView.leadingAnchor.constraint(equalTo: attachmentViewBorder.leadingAnchor).isActive = true
        attachmentView.trailingAnchor.constraint(equalTo: attachmentViewBorder.trailingAnchor).isActive = true
    }

    func setupCancelButton() {
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(cancelButton)
        cancelButton.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 0).isActive = true
        cancelButton.topAnchor.constraint(equalTo: txStateView.bottomAnchor, constant: 0).isActive = true
        cancelButton.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor).isActive = true

        cancelButton.setTitle(localized("tx_detail.tx_cancellation.cancel"), for: .normal)
        cancelButton.setVariation(.warning, font: Theme.shared.fonts.textButtonCancel)
        cancelButton.addTarget(self, action: #selector(onCancelTx), for: .touchUpInside)
    }
}
