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
    func setupNavigationBar() {
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        navigationBarHeightAnchor = navigationBar.heightAnchor.constraint(equalToConstant: defaultNavBarHeight)
        navigationBarHeightAnchor.isActive = true
    }

    func setupValueView() {
        valueContainerView.backgroundColor = Theme.shared.colors.transactionViewValueContainer
        valueContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(valueContainerView)

        //Constraints
        valueContainerView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        valueContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        valueContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true

        valueContainerViewHeightConstraintFull = valueContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: valueViewHeightMultiplierFull)
        valueContainerViewHeightConstraintFull.isActive = true

        //Create disabled shorted constraint to use later for when keyboard pops up
        valueContainerViewHeightConstraintShortened = valueContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: valueViewHeightMultiplierShortened)
        valueContainerViewHeightConstraintShortened.isActive = false

        view.sendSubviewToBack(valueContainerView)

        //Value label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(valueLabel)

        valueLabel.centerXAnchor.constraint(equalTo: valueContainerView.centerXAnchor).isActive = true
        valueCenterYAnchorConstraint = valueLabel.centerYAnchor.constraint(equalTo: valueContainerView.centerYAnchor)
        valueCenterYAnchorConstraint.isActive = true
        valueLabel.widthAnchor.constraint(lessThanOrEqualTo: valueContainerView.widthAnchor, constant: Theme.shared.sizes.appSidePadding * -4).isActive = true
        valueLabel.heightAnchor.constraint(equalToConstant: Theme.shared.fonts.transactionScreenCurrencyValueLabel!.pointSize).isActive = true

        let valueColor = Theme.shared.colors.transactionViewValueLabel
        valueLabel.minimumScaleFactor = 0.2
        valueLabel.font = Theme.shared.fonts.transactionScreenCurrencyValueLabel
        valueLabel.textColor = valueColor
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.textAlignment = .center
        valueLabel.baselineAdjustment = .alignCenters

        //Currency image
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
        valueContainerViewHeightConstraintFull.isActive = false
        valueContainerViewHeightConstraintFull = valueContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: valueViewHeightMultiplierFull, constant: 30)
        valueContainerViewHeightConstraintFull.isActive = true

        valueContainerViewHeightConstraintShortened.isActive = false
        valueContainerViewHeightConstraintShortened = valueContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: valueViewHeightMultiplierShortened, constant: 30)

        valueCenterYAnchorConstraint.isActive = false
        valueLabel.centerYAnchor.constraint(equalTo: valueContainerView.centerYAnchor, constant: -20).isActive = true

        let feeLabel = UILabel()
        feeLabel.text = feeText
        feeLabel.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(feeLabel)

        feeLabel.centerXAnchor.constraint(equalTo: valueContainerView.centerXAnchor).isActive = true
        feeLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: -5).isActive = true
        feeLabel.font = Theme.shared.fonts.transactionFeeLabel
        feeLabel.textColor = Theme.shared.colors.transactionViewValueLabel

        let feeButton = TextButton()
        feeButton.translatesAutoresizingMaskIntoConstraints = false
        valueContainerView.addSubview(feeButton)
        feeButton.setTitle(NSLocalizedString("Transaction Fee", comment: "Transaction view screen"), for: .normal)
        feeButton.setRightImage(Theme.shared.images.transactionFee!)

        feeButton.topAnchor.constraint(equalTo: feeLabel.bottomAnchor, constant: 0).isActive = true
        feeButton.centerXAnchor.constraint(equalTo: valueContainerView.centerXAnchor).isActive = true
        feeButton.addTarget(self, action: #selector(feeButtonPressed), for: .touchUpInside)
    }

    func setupFromEmojis() {
        fromContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fromContainerView)
        fromContainerView.backgroundColor = .clear
        fromContainerView.topAnchor.constraint(equalTo: valueContainerView.bottomAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        fromContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        fromContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        fromContainerView.heightAnchor.constraint(equalToConstant: 61).isActive = true

        fromHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        fromContainerView.addSubview(fromHeadingLabel)
        fromHeadingLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
        fromHeadingLabel.font = Theme.shared.fonts.transactionScreenSubheadingLabel
        fromHeadingLabel.topAnchor.constraint(equalTo: fromContainerView.topAnchor).isActive = true
        fromHeadingLabel.leadingAnchor.constraint(equalTo: fromContainerView.leadingAnchor).isActive = true

        emojiButton.translatesAutoresizingMaskIntoConstraints = false
        fromContainerView.addSubview(emojiButton)
        emojiButton.bottomAnchor.constraint(equalTo: fromContainerView.bottomAnchor, constant: -16).isActive = true
        emojiButton.leadingAnchor.constraint(equalTo: fromContainerView.leadingAnchor).isActive = true
        emojiButton.trailingAnchor.constraint(equalTo: fromContainerView.trailingAnchor).isActive = true
        emojiButton.cornerRadius = 12.0
    }

    func setupAddContactButton() {
        addContactButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addContactButton)

        addContactButton.topAnchor.constraint(equalTo: fromHeadingLabel.bottomAnchor, constant: bottomHeadingPadding).isActive = true
        addContactButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
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
        contactNameHeadingLabel.topAnchor.constraint(equalTo: fromContainerView.bottomAnchor, constant: 40.0).isActive = true
        contactNameHeadingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true

        contactNameTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contactNameTextField)
        contactNameTextField.textColor = Theme.shared.colors.transactionScreenTextLabel
        contactNameTextField.font = Theme.shared.fonts.transactionScreenTextLabel
        contactNameTextField.placeholder = NSLocalizedString("Create a Contact Name", comment: "Transaction detail view")
        contactNameTextField.autocorrectionType = .no
        contactNameTextField.returnKeyType = .done
        contactNameTextField.delegate = self
        contactNameTextField.topAnchor.constraint(equalTo: contactNameHeadingLabel.bottomAnchor, constant: bottomHeadingPadding).isActive = true
        contactNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
    }

    func setupEditContactButton() {
        editContactNameButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editContactNameButton)
        editContactNameButton.topAnchor.constraint(equalTo: contactNameHeadingLabel.bottomAnchor, constant: bottomHeadingPadding).isActive = true
        editContactNameButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        editContactNameButton.setTitle(NSLocalizedString("Edit", comment: "Transaction detail view"), for: .normal)
        editContactNameButton.setVariation(.secondary)
        editContactNameButton.addTarget(self, action: #selector(editContactButtonPressed), for: .touchUpInside)
    }

    func setupDivider() {
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dividerView)
        dividerView.topAnchor.constraint(equalTo: contactNameTextField.bottomAnchor, constant: 20.0).isActive = true
        dividerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        dividerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
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
        noteHeadingLabelTopAnchorConstraintContactNameShowing = noteHeadingLabel.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 26)
        noteHeadingLabelTopAnchorConstraintContactNameShowing.isActive = true
        noteHeadingLabelTopAnchorConstraintContactNameMissing = noteHeadingLabel.topAnchor.constraint(equalTo: emojiButton.bottomAnchor, constant: 26)
        noteHeadingLabelTopAnchorConstraintContactNameShowing.isActive = false
        noteHeadingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true

        noteLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noteLabel)
        noteLabel.textColor = Theme.shared.colors.transactionScreenTextLabel
        noteLabel.font = Theme.shared.fonts.transactionScreenTextLabel
        noteLabel.numberOfLines = 0
        noteLabel.topAnchor.constraint(equalTo: noteHeadingLabel.bottomAnchor, constant: 10).isActive = true
        noteLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        noteLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        noteLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 100).isActive = true
    }

    func setNoteText(_ text: String) {
        let attributedTitleString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        attributedTitleString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedTitleString.length))
        noteLabel.attributedText = attributedTitleString
    }
}
