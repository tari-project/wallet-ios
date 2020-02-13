//  TransactionViewController.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/07
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

class TransactionViewController: UIViewController, UITextFieldDelegate {
    let SIDE_PADDING: CGFloat = 25
    let BOTTOM_HEADING_PADDING: CGFloat = 20
    let VALUE_VIEW_HEIGHT_MULTIPLIER_FULL: CGFloat = 0.21
    let VALUE_VIEW_HEIGHT_MULTIPLIER_SHORTEND: CGFloat = 0.18

    var contactPublicKey: PublicKey?
    var contactAlias: String = ""
    let dateContainerView = UIView()
    let dateLabel = UILabel()
    let valueContainerView = UIView()
    var valueContainerViewHeightConstraintFull = NSLayoutConstraint()
    var valueContainerViewHeightConstraintShortened = NSLayoutConstraint()
    var valueCenterYAnchorConstraint = NSLayoutConstraint()
    let valueLabel = UILabel()
    let emojiButton = EmojiButton()
    let fromHeadingLabel = UILabel()
    let addContactButton = TextButton()
    let contactNameHeadingLabel = UILabel()
    let contactNameTextField = UITextField()
    let editContactNameButton = TextButton()
    let dividerView = UIView()
    let noteHeadingLabel = UILabel()
    let noteLabel = UILabel()
    var noteHeadingLabelTopAnchorConstraintContactNameShowing = NSLayoutConstraint()
    var noteHeadingLabelTopAnchorConstraintContactNameMissing = NSLayoutConstraint()

    @IBOutlet weak var transactionIDLabel: UILabel!

    var isShowingContactAlias: Bool = true {
        didSet {
            if isShowingContactAlias {
                noteHeadingLabelTopAnchorConstraintContactNameMissing.isActive = false
                noteHeadingLabelTopAnchorConstraintContactNameShowing.isActive = true
                addContactButton.isHidden = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: { [ weak self] in
                    guard let self = self else { return }

                    self.contactNameTextField.isHidden = false
                    self.contactNameHeadingLabel.isHidden = false
                    self.dividerView.isHidden = false
                })
            } else {
                noteHeadingLabelTopAnchorConstraintContactNameShowing.isActive = false
                noteHeadingLabelTopAnchorConstraintContactNameMissing.isActive = true
                contactNameTextField.isHidden = true
                contactNameHeadingLabel.isHidden = true
                dividerView.isHidden = true
                editContactNameButton.isHidden = true
            }
        }
    }

    var isEditingContactName: Bool = false {
        didSet {
            if isEditingContactName {
                contactNameTextField.becomeFirstResponder()
                editContactNameButton.isHidden = true

                UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: { [weak self] () in
                    guard let self = self else { return }
                    self.valueContainerViewHeightConstraintFull.isActive = false
                    self.valueContainerViewHeightConstraintShortened.isActive = true
                    self.view.layoutIfNeeded()
                })

            } else {
                contactNameTextField.resignFirstResponder()
                editContactNameButton.isHidden = false

                UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: { [weak self] () in
                    guard let self = self else { return }
                    self.valueContainerViewHeightConstraintShortened.isActive = false
                    self.valueContainerViewHeightConstraintFull.isActive = true
                    self.view.layoutIfNeeded()
                })
            }
        }
    }

    var transaction: Any?

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        do {
            try setDetails()
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Transaction error", comment: "Transaction detail screen"),
                description: NSLocalizedString("Failed to load transaction details", comment: "Transaction detail screen"),
                error: error)
        }

        hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func setup() {
        view.backgroundColor = Theme.shared.colors.appBackground

        setupDateView()
        setupValueView()
        setupFromEmojis()
        setupAddContactButton()
        setupContactName()
        setupEditContactButton()
        setupDivider()
        setupNote()

        //Transaction ID
        transactionIDLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
        transactionIDLabel.font = Theme.shared.fonts.transactionScreenTxIDLabel
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if isEditingContactName {
            isEditingContactName = false
        }
    }

    @objc func feeButtonPressed(_ sender: UIButton) {
        UserFeedback.shared.info(
            title: NSLocalizedString("Transaction Fee", comment: "Transaction detail view"),
            description: NSLocalizedString("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas consequat risus sit amet laoreet mollis. ", comment: "Transaction detail view"))
    }

    @objc func editContactButtonPressed(_ sender: UIButton) {
        isEditingContactName = true
    }

    @objc func addContactButtonPressed(_ sender: UIButton) {
        isShowingContactAlias = true
        isEditingContactName = true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return isEditingContactName
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField.text?.isEmpty == false else {
            textField.text = contactAlias
            return false
        }

        isEditingContactName = false

        guard contactPublicKey != nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Contact error", comment: "Transaction detail screen"),
                description: NSLocalizedString("Missing public key from transaction.", comment: "Transaction detail screen")
            )
            return true
        }

        do {
            try TariLib.shared.tariWallet!.addUpdateContact(alias: textField.text!, publicKey: contactPublicKey!)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                UserFeedback.shared.success(title: NSLocalizedString("Contact Updated!", comment: "Transaction detail screen"))
            })

        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Contact error", comment: "Transaction detail screen"),
                description: NSLocalizedString("Failed to save contact details.", comment: "Transaction detail screen"),
                error: error
            )
        }

        return true
    }

    private func setDetails() throws {
        if let tx = transaction as? TransactionProtocol {
            let (microTari, microTariError) = tx.microTari
            guard microTariError == nil else {
                throw microTariError!
            }

            if tx.direction == .inbound {
                navigationItem.title = NSLocalizedString("Payment Received", comment: "Navigation bar title on transaction view screen")
                valueLabel.text = microTari!.formatted
                contactPublicKey = tx.sourcePublicKey.0
            } else if tx.direction == .outbound {
                navigationItem.title = NSLocalizedString("Payment Sent", comment: "Navigation bar title on transaction view screen")
                valueLabel.text = microTari!.formatted
                contactPublicKey = tx.destinationPublicKey.0
            }

            if let pubKey = contactPublicKey {
                let (emojis, emojisError) = pubKey.emojis
                guard emojisError == nil else {
                    throw emojisError!
                }

                emojiButton.setEmojis(emojis)
            }

            let (date, dateError) = tx.date
            guard dateError == nil else {
                throw dateError!
            }

            dateLabel.text = date!.formattedDisplay()

            let (contact, contactError) = tx.contact
            if contactError == nil {
                let (alias, aliasError) = contact!.alias
                guard aliasError == nil else {
                    throw aliasError!
                }

                contactAlias = alias
                contactNameTextField.text = contactAlias
                isShowingContactAlias = true
            } else {
                isShowingContactAlias = false
            }

            let (message, messageError) = tx.message
            guard messageError == nil else {
                throw messageError!
            }

            noteLabel.text = message

            let (id, idError) = tx.id
            guard idError == nil else {
                throw idError!
            }

            transactionIDLabel.text = NSLocalizedString("Transaction ID:", comment: "Transaction detail view") + " \(String(id))"

            //Get the fee for outbound transactions only
            if let completedTx = tx as? CompletedTransaction {
                if completedTx.direction == .outbound {
                    let (fee, feeError) = completedTx.fee
                    guard feeError == nil else {
                        throw feeError!
                    }

                    setFeeLabel(fee!.formattedPreciseWithOperator)
                }
            } else if let pendingOutboundTx = tx as? PendingOutboundTransaction {
                let (fee, feeError) = pendingOutboundTx.fee
                guard feeError == nil else {
                    throw feeError!
                }

                setFeeLabel(fee!.formattedPreciseWithOperator)
            }
        }
    }
}
