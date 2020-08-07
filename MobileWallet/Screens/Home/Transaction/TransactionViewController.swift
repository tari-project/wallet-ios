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
import GiphyUISDK
import GiphyCoreSDK

class TransactionViewController: UIViewController {
    let bottomHeadingPadding: CGFloat = 11
    let valueViewHeightMultiplierFull: CGFloat = 0.2536
    var valueViewHeightMultiplierShortened: CGFloat {
        return isShowingCancelButton ? 0.14 : 0.16
    }

    var contactPublicKey: PublicKey?
    var contactAlias: String = ""
    let navigationBar = NavigationBarWithSubtitle()
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    var valueContainerView: UIView!
    var valueContainerViewHeightAnchor = NSLayoutConstraint()

    var valueCenterYAnchorConstraint = NSLayoutConstraint()
    let valueLabel = UILabel()
    let emojiButton = EmoticonView()
    let fromContainerView = UIView()
    let fromHeadingLabel = UILabel()
    let contactNameContainer = UIView()
    let addContactButton = TextButton()
    var contactNameContainerViewHeightAnchor = NSLayoutConstraint()
    var contactNameHeadingLabelTopAnchor = NSLayoutConstraint()
    let contactNameHeadingLabel = UILabel()
    let contactNameTextField = UITextField()
    let editContactNameButton = TextButton()
    let dividerView = UIView()
    let noteHeadingLabel = UILabel()
    let noteLabel = UILabel()
    var navigationBarHeightAnchor = NSLayoutConstraint()
    let txStateView = AnimatedRefreshingView()
    let cancelButton = TextButton()
    let attachmentSection = UIView()
    let attachmentView = GPHMediaView()
    var transaction: TransactionProtocol?
    private var isShowingStateView = false
    private var isShowingCancelButton = false
    private var txStateViewBottomAnchor = NSLayoutConstraint()
    let feeLabel = UILabel()
    let feeButton = TextButton()
    let feeButtonHeight: CGFloat = 37
    let headingLabelTopAnchorHeight: CGFloat = 40

    var isShowingContactAlias: Bool = true {
        didSet {
            if isShowingContactAlias {
                addContactButton.isHidden = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: { [ weak self] in
                    guard let self = self else { return }
                    self.contactNameTextField.isHidden = false
                    self.contactNameHeadingLabel.isHidden = false
                    self.dividerView.isHidden = false

                    self.contactNameContainerViewHeightAnchor.constant = 94
                    self.view.layoutIfNeeded()
                })
            } else {
                contactNameTextField.isHidden = true
                addContactButton.isHidden = false
                contactNameHeadingLabel.isHidden = true
                dividerView.isHidden = true
                editContactNameButton.isHidden = true
                contactNameContainerViewHeightAnchor.constant = 0
                view.layoutIfNeeded()
            }
        }
    }

    var isEditingContactName: Bool = false {
        didSet {
            let isDisplayingFee = self.feeLabel.text?.isEmpty == false

            if isEditingContactName {
                contactNameTextField.becomeFirstResponder()
                editContactNameButton.isHidden = true

                UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: { [weak self] () in
                    guard let self = self else { return }
                    self.valueContainerViewHeightAnchor.isActive = false
                    self.valueContainerViewHeightAnchor = self.valueContainerView.heightAnchor.constraint(
                        equalTo: self.view.heightAnchor,
                        multiplier: self.valueViewHeightMultiplierShortened,
                        constant: isDisplayingFee ? self.feeButtonHeight : 0
                    )
                    self.valueContainerViewHeightAnchor.isActive = true
                    self.valueLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    self.contactNameHeadingLabelTopAnchor.constant = 8
                    self.view.layoutIfNeeded()
                })
            } else {
                contactNameTextField.resignFirstResponder()
                editContactNameButton.isHidden = false

                UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: { [weak self] () in
                    guard let self = self else { return }

                    self.valueContainerViewHeightAnchor.isActive = false
                    self.valueContainerViewHeightAnchor = self.valueContainerView.heightAnchor.constraint(
                        equalTo: self.view.heightAnchor,
                        multiplier: self.valueViewHeightMultiplierFull,
                        constant: isDisplayingFee ? self.feeButtonHeight : 0
                    )
                    self.valueContainerViewHeightAnchor.isActive = true
                    self.valueLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self.contactNameHeadingLabelTopAnchor.constant = self.headingLabelTopAnchorHeight
                    self.view.layoutIfNeeded()
                })
            }
        }
    }

    var navBarHeightConstant: CGFloat {
        let defaultNavBarHeight: CGFloat = 90
        let navBarStatusHeight = AnimatedRefreshingView.containerHeight + 10
        let navBarCancelButtonHeight: CGFloat = 25

        guard let tx = transaction else {
            return defaultNavBarHeight
        }

        guard !isCancelled else {
            return defaultNavBarHeight
        }

        switch tx.status.0 {
        case .mined, .imported, .transactionNullError, .unknown:
            return defaultNavBarHeight
        case .pending:
            if tx.direction == .outbound {
                return defaultNavBarHeight + navBarStatusHeight + navBarCancelButtonHeight
            }
        default:
           return defaultNavBarHeight + navBarStatusHeight
        }

        return defaultNavBarHeight + navBarStatusHeight
    }

    var isCancelled: Bool {
        if let completedTx = transaction as? CompletedTransaction {
            return completedTx.isCancelled
        }

        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()

        do {
            try setDetails()
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("transaction_detail.error.load_transaction.title", comment: "Transaction detail view"),
                description: NSLocalizedString("transaction_detail.error.load_transaction.description", comment: "Transaction detail view"),
                error: error
            )
        }

        hideKeyboardWhenTappedAroundOrSwipedDown(view: stackView)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        Tracker.shared.track("/home/tx_details", "Transaction Details")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerEvents()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        unRegisterEvents()
    }

    private func setup() {
        view.backgroundColor = Theme.shared.colors.appBackground

        setupNavigationBar()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true

        setupValueView()
        setupFromEmojis()
        setupAddContactButton()
        setupContactName()
        setupEditContactButton()
        setupDivider()
        setupNote()
        setupGiphy()
        updateTxState()
    }

    @objc func feeButtonPressed(_ sender: UIButton) {
        UserFeedback.shared.info(
            title: NSLocalizedString("common.fee_info.title", comment: "Common"),
            description: NSLocalizedString("common.fee_info.description", comment: "Common")
        )
    }

    @objc func editContactButtonPressed(_ sender: UIButton) {
        isEditingContactName = true
    }

    @objc func addContactButtonPressed(_ sender: UIButton) {
        isShowingContactAlias = true
        isEditingContactName = true
    }

    private func registerEvents() {
        let eventTypes: [TariEventTypes] = [
            .receievedTransactionReply,
            .receivedFinalizedTransaction,
            .transactionBroadcast,
            .transactionMined
        ]

        eventTypes.forEach { (eventType) in
            TariEventBus.onMainThread(self, eventType: eventType) { [weak self] (result) in
                guard let self = self else { return }
                self.didRecieveUpdatedTx(updatedTx: result?.object as? TransactionProtocol)
            }
        }
    }

    private func unRegisterEvents() {
        TariEventBus.unregister(self)
    }

    func didRecieveUpdatedTx(updatedTx: TransactionProtocol?) {
        guard let currentTx = transaction else {
            return
        }

        guard let newTx = updatedTx else {
            TariLogger.warn("Did not get transaction in callback reponse")
            return
        }

        guard currentTx.id.0 == newTx.id.0 else {
            //Received a tx update but it was for another tx
            return
        }

        transaction = newTx

        do {
            try setDetails()
            updateTxState()
        } catch {
            TariLogger.error("Failed to update TX state", error: error)
        }
    }

    private func showStateView(defaultState: AnimatedRefreshingViewState, _ onComplete: @escaping () -> Void) {
        let allowCancelling = defaultState == .txWaitingForRecipient

        guard !isShowingStateView else {
            //If there's currently a cancel button and they can no longer cancel
            if !allowCancelling && isShowingCancelButton {
                self.txStateViewBottomAnchor.isActive = false
                self.txStateViewBottomAnchor = self.txStateView.bottomAnchor.constraint(equalTo: self.navigationBar.bottomAnchor, constant: -Theme.shared.sizes.appSidePadding)
                self.txStateViewBottomAnchor.isActive = true
                self.cancelButton.removeFromSuperview()
                self.navigationBarHeightAnchor.constant = navBarHeightConstant
            }

            onComplete()
            return
        }

        self.txStateView.translatesAutoresizingMaskIntoConstraints = false
        self.navigationBar.addSubview(self.txStateView)

        //Make space for cancel button if needed
        let bottomPadding = Theme.shared.sizes.appSidePadding + (allowCancelling ? Theme.shared.sizes.appSidePadding : 0)
        self.txStateViewBottomAnchor = self.txStateView.bottomAnchor.constraint(equalTo: self.navigationBar.bottomAnchor, constant: -bottomPadding)
        self.txStateViewBottomAnchor.isActive = true
        self.txStateView.leadingAnchor.constraint(equalTo: self.navigationBar.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        self.txStateView.trailingAnchor.constraint(equalTo: self.navigationBar.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        self.txStateView.heightAnchor.constraint(equalToConstant: 48).isActive = true

        self.txStateView.setupView(defaultState, visible: true)

        self.isShowingStateView = true

        if allowCancelling {
            self.setupCancelButton()
            self.isShowingCancelButton = true
        }

        onComplete()
    }

    private func hideStateView() {
        guard isShowingStateView else {
            return
        }

        cancelButton.removeFromSuperview()

        self.txStateView.animateOut { [weak self] in
            guard let self = self else { return }

            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                guard let self = self else { return }

                self.navigationBarHeightAnchor.constant = self.navBarHeightConstant
                self.navigationBar.layoutIfNeeded()
                self.view.layoutIfNeeded()
            }) { [weak self] (_) in
                guard let self = self else { return }
                self.isShowingStateView = false
            }
        }
    }

    private func updateTxState() {
        guard let tx = transaction else {
            return
        }

        guard !isCancelled else {
            return
        }

        var newState: AnimatedRefreshingViewState?

        switch tx.status.0 {
        case .pending:
            if tx.direction == .inbound {
                newState = .txWaitingForSender
            } else if tx.direction == .outbound {
                newState = .txWaitingForRecipient
            }
        case .broadcast, .completed:
            newState = .txCompleted
        default:
            newState = nil
        }

        if let state = newState {
            //Attempt to show it if it's not showing yet, else just update the state
            showStateView(defaultState: state) { [weak self] in
                guard let self = self else { return }
                self.txStateView.updateState(state)
            }
        } else {
            hideStateView()
        }
    }

    private func setDetails() throws {
        if let tx = transaction {
            let (microTari, microTariError) = tx.microTari
            guard microTariError == nil else {
                throw microTariError!
            }

            if tx.direction == .inbound {
                navigationBar.title = NSLocalizedString("transaction_detail.payment_received", comment: "Transaction detail view")
                fromHeadingLabel.text = NSLocalizedString("transaction_detail.from", comment: "Transaction detail view")
                valueLabel.text = microTari!.formatted
                contactPublicKey = tx.sourcePublicKey.0
            } else if tx.direction == .outbound {
                navigationBar.title = NSLocalizedString("transaction_detail.payment_sent", comment: "Transaction detail view")
                fromHeadingLabel.text = NSLocalizedString("transaction_detail.to", comment: "Transaction detail view")
                valueLabel.text = microTari!.formatted
                contactPublicKey = tx.destinationPublicKey.0
            }

            if let pubKey = contactPublicKey {
                emojiButton.setUpView(
                    pubKey: pubKey,
                    type: .buttonView,
                    textCentered: false,
                    inViewController: self
                )
                emojiButton.blackoutParent = view
            }

            let (date, dateError) = tx.date
            guard dateError == nil else {
                throw dateError!
            }

            navigationBar.subtitle = date!.formattedDisplay()

            let (contact, contactError) = tx.contact
            if contactError == nil {
                let (alias, aliasError) = contact!.alias
                guard aliasError == nil else {
                    throw aliasError!
                }

                //Got a contact but the alias is blank
                if !alias.isEmpty {
                    contactAlias = alias
                    contactNameTextField.text = contactAlias
                    isShowingContactAlias = true
                } else {
                    isShowingContactAlias = false
                }
            } else {
                isShowingContactAlias = false
            }

            let (message, messageError) = tx.message
            guard messageError == nil else {
                throw messageError!
            }

            let (note, noteGiphyId) = TransactionViewController.splitNoteAndGiphyId(message)

            setNoteText(note)

            if let giphyId = noteGiphyId {
                GiphyCore.shared.gifByID(giphyId) { (response, error) in
                    guard error == nil else {
                        return TariLogger.error("Failed to load gif", error: error)
                    }

                    if let media = response?.data {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.attachmentView.media = media
                            self.attachmentSection.heightAnchor.constraint(equalTo: self.attachmentView.widthAnchor, multiplier: 1 / media.aspectRatio).isActive = true
                        }
                    }
                }
            }

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

            if isCancelled {
                navigationBar.title = NSLocalizedString("transaction_detail.payment_cancelled", comment: "Transaction detail view")
            } else if tx.status.0 != .mined && tx.status.0 != .imported {
                navigationBar.title = NSLocalizedString("transaction_detail.payment_in_progress", comment: "Transaction detail view")
            }
        }
    }

    @objc func onCancelTx() {
        let alert = UIAlertController(
            title: NSLocalizedString("transaction_detail.tx_cancellation.title", comment: "Transaction detail tx cancellation"),
            message: NSLocalizedString("transaction_detail.tx_cancellation.message", comment: "Transaction detail tx cancellation"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("transaction_detail.tx_cancellation.yes", comment: "Transaction detail tx cancellation"), style: .destructive, handler: { [weak self] (_) in
            guard let self = self else { return }
            if let tx = self.transaction {
                guard tx.status.0 == .pending && tx.direction == .outbound else {
                    UserFeedback.shared.error(
                        title: NSLocalizedString("transaction_detail.tx_cancellation.error.title", comment: "Transaction detail tx cancellation"),
                        description: NSLocalizedString("transaction_detail.tx_cancellation.error.description", comment: "Transaction detail tx cancellation")
                    )
                    return
                }

                do {
                    try TariLib.shared.tariWallet?.cancelPendingTransaction(tx)

                    UINotificationFeedbackGenerator().notificationOccurred(.success)

                    //Attempt to get the newly cancelled tx and reset the UI
                    //TODO uncomment the below when the findCancelledTransactionBy is returning correct direction
//                    if let id = self.transaction?.id.0 {
//                        if let cancelledTX = try? TariLib.shared.tariWallet?.findCancelledTransactionBy(id: id) {
//                            self.transaction = cancelledTX
//                            do {
//                                try self.setDetails()
//                                self.updateTxState()
//                            } catch {
//                                UserFeedback.shared.error(
//                                    title: NSLocalizedString("transaction_detail.error.load_transaction.title", comment: "Transaction detail view"),
//                                    description: NSLocalizedString("transaction_detail.error.load_transaction.description", comment: "Transaction detail view"),
//                                    error: error
//                                )
//                            }
//                            return
//                        }
//                    }

                    //If cancelled tx not found just go back to home view
                    self.navigationController?.popViewController(animated: true)
                } catch {
                    UserFeedback.shared.error(
                        title: NSLocalizedString("transaction_detail.tx_cancellation.error.title", comment: "Transaction detail tx cancellation"),
                        description: "",
                        error: error
                    )
                }
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("transaction_detail.tx_cancellation.no", comment: "Transaction detail tx cancellation"), style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension TransactionViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return isEditingContactName
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if isEditingContactName {
            isEditingContactName = false
        }

        if contactAlias.isEmpty {
            isShowingContactAlias = false
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let newAlias = textField.text else {
            return true
        }

        if newAlias.isEmpty {
            isShowingContactAlias = false
        }

        guard contactPublicKey != nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("transaction_detail.error.contact.title", comment: "Transaction detail view"),
                description: NSLocalizedString("transaction_detail.error.contact.description", comment: "Transaction detail view")
            )
            return true
        }

        do {
            guard let wallet = TariLib.shared.tariWallet, let publicKey = contactPublicKey else { return true }
            try wallet.addUpdateContact(alias: newAlias, publicKey: publicKey)
            contactAlias = newAlias
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            })
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("transaction_detail.error.contact.title", comment: "Transaction detail view"),
                description: NSLocalizedString("transaction_detail.error.save_contact.description", comment: "Transaction detail view"),
                error: error
            )
        }

        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 40
        guard let currentString = textField.text as NSString? else { return false }
        let newString: NSString = currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
}

// MARK: Keyboard behavior
extension TransactionViewController {
    @objc func keyboardWillHide(notification: NSNotification) {
        contactNameTextField.endEditing(true)
        contactNameTextField.text = contactAlias
    }
}

// MARK: Giphy
extension TransactionViewController {
    static func splitNoteAndGiphyId(_ note: String) -> (String, String?) {
        let giphyLinkPrefix = "https://giphy.com/embed/"

        if let endIndex = note.range(of: giphyLinkPrefix)?.lowerBound {
            let messageExcludingLink = note[..<endIndex].trimmingCharacters(in: .whitespaces)
            let link = note[endIndex...].trimmingCharacters(in: .whitespaces)
            let giphyId = link.replacingOccurrences(of: giphyLinkPrefix, with: "")

            return (messageExcludingLink, giphyId)

        } else {
            return (note, nil)
        }
    }
}
