//  AddNoteViewController.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/02/25
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

class AddNoteViewController: UIViewController, UITextViewDelegate, SlideViewDelegate {
    var publicKey: PublicKey?
    var amount: MicroTari?
    private let SIDE_PADDING = Theme.shared.sizes.appSidePadding

    fileprivate let sendButton = SlideView()
    fileprivate var sendButtonBottomConstraint = NSLayoutConstraint()
    fileprivate let titleLabel = UILabel()
    fileprivate let noteInput = UITextView()
    fileprivate let notePlaceholder = UILabel()
    fileprivate var noteText = "" {
        didSet {
            if noteText.isEmpty {
                sendButton.isEnabled = false
            } else {
                sendButton.isEnabled = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        hideKeyboardWhenTappedAroundOrSwipedDown()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        styleNavigatorBar(isHidden: false)

        guard let pubKey = publicKey else { return }

        do {
            try showNavbarEmojies(pubKey)
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Public key error", comment: "Add amount view"),
                description: NSLocalizedString("Failed to get Emoji ID from user's contact", comment: "Add amount view"),
                error: error
            )
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(moveSendButtonUp), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(moveSendButtonDown), name: UIResponder.keyboardWillHideNotification, object: nil)

        noteInput.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        hideNavbarEmojis()
    }

    private func setup() {
        view.backgroundColor = Theme.shared.colors.appBackground

        setupNoteTitle()
        setupSendButton()
        setupNoteInput()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        let trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText.isEmpty {
            titleLabel.textColor = Theme.shared.colors.addNoteTitleLabel
            notePlaceholder.isHidden = false
        } else {
            titleLabel.textColor = Theme.shared.colors.inputPlaceholder
            notePlaceholder.isHidden = true
        }

        noteText = trimmedText
    }

    @objc private func moveSendButtonUp(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            sendButtonBottomConstraint.isActive = false

            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.sendButtonBottomConstraint = self.sendButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -keyboardHeight - self.SIDE_PADDING)
                self.sendButtonBottomConstraint.isActive = true
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func moveSendButtonDown() {
        sendButtonBottomConstraint.isActive = false

        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }

            self.sendButtonBottomConstraint = self.sendButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -self.SIDE_PADDING)
            self.sendButtonBottomConstraint.isActive = true
        }
    }

    func slideViewDidFinish(_ sender: SlideView) {
        dismissKeyboard()

        guard let wallet = TariLib.shared.tariWallet else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Wallet error", comment: "Add note view"),
                description: NSLocalizedString("Wallet not initialized", comment: "Add note view")
            )
            sender.resetStateWithAnimation(true)
            return
        }

        guard let recipientPubKey = publicKey else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Missing public key", comment: "Add note view"),
                description: NSLocalizedString("Recipient public key not set", comment: "Add note view")
            )
            sender.resetStateWithAnimation(true)
            return
        }

        guard let recipientAmount = amount else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Missing amount", comment: "Add note view"),
                description: NSLocalizedString("Recipient amount not set", comment: "Add note view")
            )
            sender.resetStateWithAnimation(true)
            return
        }

        do {
            try wallet.sendTransaction(
                destination: recipientPubKey,
                amount: recipientAmount,
                fee: wallet.calculateTransactionFee(recipientAmount),
                message: noteText
            )

            onSendComplete(recipientAmount)
        } catch WalletErrors.generic(210) {
            TariLogger.warn("Error 210. Will wait for discovery.")
            //Discovery still needs to happen, this error is actually alright
            onSendComplete(recipientAmount)
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Transaction failed", comment: "Add note view"),
                description: NSLocalizedString("Could not send transaction to recipient", comment: "Add note view"),
                error: error
            )
            sender.resetStateWithAnimation(true)
        }
    }

    func onSendComplete(_ amount: MicroTari) {
        TariLogger.info("Sending transaction.")

        let vc = SendingTariViewController()
        vc.tariAmount = amount
        self.navigationController?.pushViewController(vc, animated: false)
    }
}

extension AddNoteViewController {
    fileprivate func setupNoteTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        titleLabel.font = Theme.shared.fonts.addNoteTitleLabel
        titleLabel.textColor = Theme.shared.colors.addNoteTitleLabel
        titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: SIDE_PADDING).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: SIDE_PADDING).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -SIDE_PADDING).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.pointSize * 1.1).isActive = true
        titleLabel.text = NSLocalizedString("Transaction Note", comment: "Add note view")
    }

    fileprivate func setupSendButton() {
        sendButton.isEnabled = false

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        sendButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: SIDE_PADDING).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -SIDE_PADDING).isActive = true
        sendButtonBottomConstraint = sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -SIDE_PADDING)
        sendButtonBottomConstraint.isActive = true

        sendButton.showSliderText = true
        sendButton.labelText = NSLocalizedString("Slide to Send", comment: "Add note view")
        sendButton.delegate = self

        //If we're in testmode, the slide to send doesn't seem to work so allow it to be tapped in this case
        if ProcessInfo.processInfo.arguments.contains("ui-test-mode") {
            let tapButtonGesture = UITapGestureRecognizer(target: self, action: #selector (self.slideViewDidFinish (_:)))
            sendButton.addGestureRecognizer(tapButtonGesture)
        }
    }

    fileprivate func setupNoteInput() {
        let font = Theme.shared.fonts.addNoteInputView!

        noteInput.delegate = self
        noteInput.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noteInput)
        noteInput.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: SIDE_PADDING / 2).isActive = true
        noteInput.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: SIDE_PADDING).isActive = true
        noteInput.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -SIDE_PADDING).isActive = true
        noteInput.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -SIDE_PADDING).isActive = true
        noteInput.textContainerInset = .zero
        noteInput.textContainer.lineFragmentPadding = 0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = font.pointSize * 1.25
        noteInput.attributedText = NSAttributedString(
            string: " ", //Needs to have at least one char to take affect
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: font
            ]
        )
        noteInput.text = ""

        notePlaceholder.translatesAutoresizingMaskIntoConstraints = false
        noteInput.addSubview(notePlaceholder)
        notePlaceholder.topAnchor.constraint(equalTo: noteInput.topAnchor).isActive = true
        notePlaceholder.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: SIDE_PADDING).isActive = true
        notePlaceholder.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -SIDE_PADDING).isActive = true
        notePlaceholder.numberOfLines = 0

        notePlaceholder.attributedText = NSAttributedString(
            string: NSLocalizedString("Let the recipient know what the payment is for", comment: "Add note view"),
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.inputPlaceholder!
            ]
        )

    }
}
