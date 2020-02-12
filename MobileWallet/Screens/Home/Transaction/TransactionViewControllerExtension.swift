//  TransactionViewControllerExtension.swift

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

extension TransactionViewController {
    func setupDateView() {
        dateContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dateContainerView)

        //Constraints
        dateContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        dateContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        dateContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        dateContainerView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        dateContainerView.backgroundColor = Theme.shared.colors.appBackground
        dateContainerView.layer.shadowColor = Theme.shared.colors.navigationBottomShadow!.cgColor
        dateContainerView.layer.shadowOffset = CGSize(width: 10.0, height: 10.0)
        dateContainerView.layer.shadowRadius = 10
        dateContainerView.layer.shadowOpacity = 0.1
        dateContainerView.clipsToBounds = true
        dateContainerView.layer.masksToBounds = false

        //Setup date label
        dateContainerView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.topAnchor.constraint(equalTo: dateContainerView.topAnchor).isActive = true
        dateLabel.centerXAnchor.constraint(equalTo: dateContainerView.centerXAnchor).isActive = true
        dateLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true

        //Date style
        dateLabel.textAlignment = .center
        dateLabel.font = Theme.shared.fonts.transactionScreenSubheadingLabel
        dateLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
    }

    func setupValueView() {
        valueContainerView.backgroundColor = Theme.shared.colors.transactionViewValueContainer
        valueContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(valueContainerView)

        //Constraints
        valueContainerView.topAnchor.constraint(equalTo: dateContainerView.bottomAnchor).isActive = true
        valueContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        valueContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true

        valueContainerViewHeightConstraintFull = valueContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: VALUE_VIEW_HEIGHT_MULTIPLIER_FULL)
        valueContainerViewHeightConstraintFull.isActive = true

        //Create disabled shorted constraint to use later for when keyboard pops up
        valueContainerViewHeightConstraintShortened = valueContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: VALUE_VIEW_HEIGHT_MULTIPLIER_SHORTEND)
        valueContainerViewHeightConstraintShortened.isActive = false

        view.sendSubviewToBack(valueContainerView)

        //Value label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(valueLabel)

        valueLabel.centerXAnchor.constraint(equalTo: valueContainerView.centerXAnchor).isActive = true
        valueCenterYAnchorConstraint = valueLabel.centerYAnchor.constraint(equalTo: valueContainerView.centerYAnchor)
        valueCenterYAnchorConstraint.isActive = true
        valueLabel.widthAnchor.constraint(lessThanOrEqualTo: valueContainerView.widthAnchor, constant: SIDE_PADDING * -4).isActive = true

        let valueColor = Theme.shared.colors.transactionViewValueLabel
        valueLabel.minimumScaleFactor = 0.2
        valueLabel.font = Theme.shared.fonts.transactionScreenCurrencyValueLabel
        valueLabel.textColor = valueColor
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.2
        valueLabel.textAlignment = .center

        //Currency image
        let valueImage = UIImageView()
        valueImage.image = Theme.shared.images.currencySymbol?.withTintColor(valueColor!)
        valueImage.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(valueImage)

        valueImage.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor).isActive = true
        valueImage.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -SIDE_PADDING / 2).isActive = true
        valueImage.heightAnchor.constraint(equalToConstant: 21).isActive = true
        valueImage.widthAnchor.constraint(equalToConstant: 21).isActive = true
        valueImage.contentMode = .scaleAspectFit
    }

    func setFeeLabel(_ feeText: String) {
        valueContainerViewHeightConstraintFull.isActive = false
        valueContainerViewHeightConstraintFull = valueContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: VALUE_VIEW_HEIGHT_MULTIPLIER_FULL, constant: 30)
        valueContainerViewHeightConstraintFull.isActive = true

        valueContainerViewHeightConstraintShortened.isActive = false
        valueContainerViewHeightConstraintShortened = valueContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: VALUE_VIEW_HEIGHT_MULTIPLIER_SHORTEND, constant: 30)

        valueCenterYAnchorConstraint.isActive = false
        valueLabel.centerYAnchor.constraint(equalTo: valueContainerView.centerYAnchor, constant: -22).isActive = true

        let feeLabel = UILabel()
        feeLabel.text = feeText
        feeLabel.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(feeLabel)

        feeLabel.centerXAnchor.constraint(equalTo: valueContainerView.centerXAnchor).isActive = true
        feeLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 12).isActive = true
        feeLabel.font = Theme.shared.fonts.transactionFeeLabel
        feeLabel.textColor = Theme.shared.colors.transactionViewValueLabel

        let feeButton = TextButton()
        feeButton.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(feeButton)
        feeButton.setTitle(NSLocalizedString("Transaction Fee", comment: "Transaction view screen"), for: .normal)
        feeButton.setRightImage(Theme.shared.images.transactionFee!)

        feeButton.topAnchor.constraint(equalTo: feeLabel.bottomAnchor, constant: 6).isActive = true
        feeButton.centerXAnchor.constraint(equalTo: valueContainerView.centerXAnchor).isActive = true
        feeButton.addTarget(self, action: #selector(feeButtonPressed), for: .touchUpInside)
    }

    func setupFromEmojis() {

        fromHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fromHeadingLabel)
        fromHeadingLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
        fromHeadingLabel.font = Theme.shared.fonts.transactionScreenSubheadingLabel
        fromHeadingLabel.text = NSLocalizedString("From", comment: "Transaction detail view")
        fromHeadingLabel.topAnchor.constraint(equalTo: valueContainerView.bottomAnchor, constant: SIDE_PADDING).isActive = true
        fromHeadingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: SIDE_PADDING).isActive = true

        emojiButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emojiButton)
        emojiButton.topAnchor.constraint(equalTo: fromHeadingLabel.bottomAnchor, constant: BOTTOM_HEADING_PADDING).isActive = true
        emojiButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: SIDE_PADDING).isActive = true
    }

    func setupAddContactButton() {
        addContactButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addContactButton)

        addContactButton.topAnchor.constraint(equalTo: fromHeadingLabel.bottomAnchor, constant: BOTTOM_HEADING_PADDING).isActive = true
        addContactButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -SIDE_PADDING).isActive = true
        addContactButton.setTitle(NSLocalizedString("Add Contact Name", comment: "Transaction detail view"), for: .normal)
        addContactButton.setVariation(.secondary)
        addContactButton.addTarget(self, action: #selector(addContactButtonPressed), for: .touchUpInside)
    }

    func setupContactName() {
        contactNameHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contactNameHeadingLabel)
        contactNameHeadingLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
        contactNameHeadingLabel.font = Theme.shared.fonts.transactionScreenSubheadingLabel
        contactNameHeadingLabel.text = NSLocalizedString("Contact Name", comment: "Transaction detail view")
        contactNameHeadingLabel.topAnchor.constraint(equalTo: emojiButton.bottomAnchor, constant: BOTTOM_HEADING_PADDING * 2).isActive = true
        contactNameHeadingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: SIDE_PADDING).isActive = true

        contactNameTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contactNameTextField)
        contactNameTextField.textColor = Theme.shared.colors.transactionScreenTextLabel
        contactNameTextField.font = Theme.shared.fonts.transactionScreenTextLabel
        contactNameTextField.placeholder = NSLocalizedString("Create a Contact Name", comment: "Transaction detail view")
        contactNameTextField.autocorrectionType = .no
        contactNameTextField.returnKeyType = .done
        contactNameTextField.delegate = self
        contactNameTextField.topAnchor.constraint(equalTo: contactNameHeadingLabel.bottomAnchor, constant: BOTTOM_HEADING_PADDING).isActive = true
        contactNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: SIDE_PADDING).isActive = true
    }

    func setupEditContactButton() {
        editContactNameButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editContactNameButton)
        editContactNameButton.topAnchor.constraint(equalTo: contactNameHeadingLabel.bottomAnchor, constant: BOTTOM_HEADING_PADDING).isActive = true
        editContactNameButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -SIDE_PADDING).isActive = true
        editContactNameButton.setTitle(NSLocalizedString("Edit", comment: "Transaction detail view"), for: .normal)
        editContactNameButton.setVariation(.secondary)
        editContactNameButton.addTarget(self, action: #selector(editContactButtonPressed), for: .touchUpInside)
    }

    func setupDivider() {
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dividerView)
        dividerView.topAnchor.constraint(equalTo: contactNameTextField.bottomAnchor, constant: BOTTOM_HEADING_PADDING * 1.5).isActive = true
        dividerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: SIDE_PADDING).isActive = true
        dividerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -SIDE_PADDING).isActive = true
        dividerView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        dividerView.layer.borderWidth = 1
        dividerView.layer.borderColor = Theme.shared.colors.transactionScreenDivider!.cgColor
    }

    func setupNote() {
        noteHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noteHeadingLabel)
        noteHeadingLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
        noteHeadingLabel.font = Theme.shared.fonts.transactionScreenSubheadingLabel
        noteHeadingLabel.text = NSLocalizedString("Note", comment: "Transaction detail view")
        noteHeadingLabelTopAnchorConstraintContactNameShowing = noteHeadingLabel.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: BOTTOM_HEADING_PADDING * 1.5)
        noteHeadingLabelTopAnchorConstraintContactNameShowing.isActive = true
        noteHeadingLabelTopAnchorConstraintContactNameMissing = noteHeadingLabel.topAnchor.constraint(equalTo: emojiButton.bottomAnchor, constant: BOTTOM_HEADING_PADDING * 1.5)
        noteHeadingLabelTopAnchorConstraintContactNameShowing.isActive = false

        noteHeadingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: SIDE_PADDING).isActive = true

        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noteLabel)
        noteLabel.textColor = Theme.shared.colors.transactionScreenTextLabel
        noteLabel.font = Theme.shared.fonts.transactionScreenTextLabel
        noteLabel.numberOfLines = 5
        noteLabel.topAnchor.constraint(equalTo: noteHeadingLabel.bottomAnchor, constant: BOTTOM_HEADING_PADDING).isActive = true
        noteLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: SIDE_PADDING).isActive = true
        noteLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
    }
}
