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
import GiphyUISDK
import GiphyCoreSDK

class AddNoteViewController: UIViewController, UITextViewDelegate, SlideViewDelegate, GiphyDelegate, GPHGridDelegate {
    var publicKey: PublicKey?
    var amount: MicroTari?
    var deepLinkParams: DeepLinkParams?
    private let sidePadding = Theme.shared.sizes.appSidePadding
    private let navigationBar = NavigationBar()
    fileprivate let sendButton = SlideView()
    fileprivate var sendButtonBottomConstraint = NSLayoutConstraint()
    fileprivate let titleLabel = UILabel()
    fileprivate let noteInput = UITextView()
    fileprivate let notePlaceholder = UILabel()
    fileprivate var noteText = "" {
        didSet {
            setSendButtonState()
        }
    }
    private let poweredByGiphyImageView = UIImageView(image: Theme.shared.images.poweredByGiphy)
    private let giphyCaroursalContainerView = UIView()
    private let giphyModal = GiphyViewController()
    private let searchGiphyButton = UIButton()

    let attachmentContainer = UIView()
    let attachmentView = GPHMediaView()
    var attachment: GPHMedia? = nil {
        didSet {
            attachmentView.media = attachment
            if let _ = attachment {
                attachmentContainer.isHidden = false
                giphyCaroursalContainerView.isHidden = true
            } else {
                giphyCaroursalContainerView.isHidden = false
                attachmentContainer.isHidden = true
            }

            setSendButtonState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

//        hideKeyboardWhenTappedAroundOrSwipedDown(view: noteInput)
//        hideKeyboardWhenTappedAroundOrSwipedDown(view: attachmentContainer)

        Tracker.shared.track("/home/send_tari/add_note", "Send Tari - Add Note")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let wallet = TariLib.shared.tariWallet, let pubKey = publicKey else {
            return
        }

        do {
            guard let contact = try wallet.contacts.0?.find(publicKey: pubKey) else { return }
            if contact.alias.0.trimmingCharacters(in: .whitespaces).isEmpty {
                try navigationBar.showEmoji(pubKey, animated: true)
            } else {
                navigationBar.title = contact.alias.0
            }
        } catch {
            do {
                try navigationBar.showEmoji(pubKey, animated: true)
            } catch {
                UserFeedback.shared.error(
                    title: NSLocalizedString("navigation_bar.error.show_emoji.title", comment: "Navigation bar"),
                    description: NSLocalizedString("navigation_bar.error.show_emoji.description", comment: "Navigation bar"),
                    error: error
                )
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(moveSendButtonUp), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(moveSendButtonDown), name: UIResponder.keyboardWillHideNotification, object: nil)

        noteInput.becomeFirstResponder()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        if let params = deepLinkParams {
            noteInput.text = params.note
            textViewDidChangeSelection(noteInput)
        }

        setupGiphy()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationBar.hideEmoji(animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    func setSendButtonState() {
        if noteText.isEmpty && attachment == nil {
            sendButton.isEnabled = false
        } else {
            sendButton.isEnabled = true
        }
    }

    private func setup() {
        view.backgroundColor = Theme.shared.colors.appBackground

        setupNavigationBar()
        setupNoteTitle()
        setupSendButton()
        setupNoteInput()
        setupMediaAttachment()
    }

    private func setupMediaAttachment() {
        view.addSubview(attachmentContainer)
        attachmentContainer.translatesAutoresizingMaskIntoConstraints = false
        attachmentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sidePadding).isActive = true
        attachmentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sidePadding).isActive = true
        attachmentContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 200).isActive = true
        attachmentContainer.layer.cornerRadius = 20
        attachmentContainer.layer.masksToBounds = true

        attachmentContainer.addSubview(attachmentView)
        attachmentView.translatesAutoresizingMaskIntoConstraints = false
        attachmentView.topAnchor.constraint(equalTo: attachmentContainer.topAnchor).isActive = true
        attachmentView.bottomAnchor.constraint(equalTo: attachmentContainer.bottomAnchor).isActive = true
        attachmentView.leadingAnchor.constraint(equalTo: attachmentContainer.leadingAnchor).isActive = true
        attachmentView.trailingAnchor.constraint(equalTo: attachmentContainer.trailingAnchor).isActive = true

        view.bringSubviewToFront(attachmentContainer)
        view.bringSubviewToFront(sendButton)

        //TODO delete button
        let cancelView = UIView()
        cancelView.translatesAutoresizingMaskIntoConstraints = false
        attachmentContainer.addSubview(cancelView)
        cancelView.topAnchor.constraint(equalTo: attachmentContainer.topAnchor).isActive = true
        cancelView.trailingAnchor.constraint(equalTo: attachmentContainer.trailingAnchor).isActive = true
        cancelView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        cancelView.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let cancelImageView = UIImageView(image: Theme.shared.images.cancelGiphy)
        cancelImageView.translatesAutoresizingMaskIntoConstraints = false
        cancelView.addSubview(cancelImageView)
        cancelImageView.centerXAnchor.constraint(equalTo: cancelView.centerXAnchor).isActive = true
        cancelImageView.centerYAnchor.constraint(equalTo: cancelView.centerYAnchor).isActive = true

        cancelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (removeAttachment)))
    }

    private func setupGiphy() {
        //Pre selected caurousal
        let giffPadding: CGFloat = 7
        let giphyVC = GiphyGridController()

        giphyCaroursalContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(giphyCaroursalContainerView)
        giphyCaroursalContainerView.leftAnchor.constraint(equalTo: view.safeLeftAnchor, constant: giffPadding).isActive = true
        giphyCaroursalContainerView.rightAnchor.constraint(equalTo: view.safeRightAnchor, constant: -giffPadding).isActive = true
        giphyCaroursalContainerView.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -(giffPadding * 2)).isActive = true

        //Giphy settings
        giphyVC.cellPadding = giffPadding
        giphyVC.direction = .horizontal
        giphyVC.numberOfTracks = 1
        giphyVC.showCheckeredBackground = false
        giphyVC.view.backgroundColor = .clear
        giphyVC.imageType = .gif
        giphyVC.layout = .carousel
        giphyVC.rating = .ratedPG13
        giphyVC.fixedSizeCells = true
        giphyVC.theme = TariGiphyTheme()

        giphyVC.delegate = self
        addChild(giphyVC)
        giphyCaroursalContainerView.addSubview(giphyVC.view)

        giphyVC.view.translatesAutoresizingMaskIntoConstraints = false

        giphyVC.view.leadingAnchor.constraint(equalTo: giphyCaroursalContainerView.leadingAnchor).isActive = true
        giphyVC.view.trailingAnchor.constraint(equalTo: giphyCaroursalContainerView.trailingAnchor).isActive = true
        giphyVC.view.bottomAnchor.constraint(equalTo: giphyCaroursalContainerView.bottomAnchor).isActive = true
        giphyVC.view.heightAnchor.constraint(equalToConstant: 64).isActive = true

        let searchButtonWidth: CGFloat = 90
        searchGiphyButton.setImage(Theme.shared.images.searchIcon, for: .normal)
        searchGiphyButton.tintColor = Theme.shared.colors.searchGiphyButtonTitle
        searchGiphyButton.backgroundColor = Theme.shared.colors.searchGiphyButtonBackground
        searchGiphyButton.setTitleColor(Theme.shared.colors.searchGiphyButtonTitle, for: .normal)
        searchGiphyButton.titleLabel?.font = Theme.shared.fonts.searchGiphyButtonTitle
        searchGiphyButton.setTitle(NSLocalizedString("add_note.search_giphy_button", comment: "Add note view"), for: .normal)
        searchGiphyButton.translatesAutoresizingMaskIntoConstraints = false
        searchGiphyButton.layer.cornerRadius = 3
        searchGiphyButton.titleEdgeInsets = .init(top: 0, left: 5, bottom: 0, right: 0)
        giphyCaroursalContainerView.addSubview(searchGiphyButton)
        searchGiphyButton.heightAnchor.constraint(equalToConstant: 18).isActive = true
        searchGiphyButton.leadingAnchor.constraint(equalTo: giphyCaroursalContainerView.leadingAnchor).isActive = true
        searchGiphyButton.widthAnchor.constraint(equalToConstant: searchButtonWidth).isActive = true
        searchGiphyButton.topAnchor.constraint(equalTo: giphyCaroursalContainerView.topAnchor).isActive = true
        searchGiphyButton.addTarget(self, action: #selector(showGiffyPanel), for: .touchUpInside)
        searchGiphyButton.isHidden = true

        poweredByGiphyImageView.translatesAutoresizingMaskIntoConstraints = false
        giphyCaroursalContainerView.addSubview(poweredByGiphyImageView)
        poweredByGiphyImageView.heightAnchor.constraint(equalToConstant: 9.9).isActive = true
        poweredByGiphyImageView.widthAnchor.constraint(equalToConstant: searchButtonWidth).isActive = true
        poweredByGiphyImageView.leadingAnchor.constraint(equalTo: giphyCaroursalContainerView.leadingAnchor).isActive = true
        poweredByGiphyImageView.topAnchor.constraint(equalTo: searchGiphyButton.bottomAnchor, constant: giffPadding).isActive = true
        poweredByGiphyImageView.bottomAnchor.constraint(equalTo: giphyVC.view.topAnchor, constant: -giffPadding).isActive = true
        poweredByGiphyImageView.isHidden = true

        giphyVC.content = GPHContent.search(withQuery: "Money", mediaType: .gif, language: .english)
        giphyVC.update()
    }

    @objc private func showGiffyPanel() {
        giphyModal.layout = .waterfall
        giphyModal.mediaTypeConfig = [.gifs]
        giphyModal.theme = TariGiphyTheme()
        giphyModal.delegate = self
        GiphyViewController.trayHeightMultiplier = 0.8
        present(giphyModal, animated: true, completion: nil)
    }

    func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia) {
        giphyModal.dismiss(animated: true, completion: nil)
        attachment = media
    }

    func didSelectMedia(media: GPHMedia, cell: UICollectionViewCell) {
        attachment = media
    }

    @objc func removeAttachment() {
        attachment = nil
    }

    func didDismiss(controller: GiphyViewController?) {}

    func contentDidUpdate(resultCount: Int) {
        searchGiphyButton.isHidden = false
        poweredByGiphyImageView.isHidden = false
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        var trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText.isEmpty {
            titleLabel.textColor = Theme.shared.colors.addNoteTitleLabel
            notePlaceholder.isHidden = false
        } else {
            titleLabel.textColor = Theme.shared.colors.inputPlaceholder
            notePlaceholder.isHidden = true
        }

        //Limit to the size of a tx note
        let charLimit = 280
        if trimmedText.count > charLimit {
            TariLogger.warn("Limitting tx note to \(charLimit) chars")
            trimmedText = String(trimmedText.prefix(charLimit))
            textView.text = trimmedText
        }

        noteText = trimmedText
    }

    @objc private func moveSendButtonUp(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            sendButtonBottomConstraint.isActive = false

            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.sendButtonBottomConstraint = self.sendButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -keyboardHeight)
                self.sendButtonBottomConstraint.isActive = true
                self.view.layoutIfNeeded()
            }

        }
    }

    @objc private func moveSendButtonDown() {
        sendButtonBottomConstraint.isActive = false

        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }

            self.sendButtonBottomConstraint = self.sendButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
            self.sendButtonBottomConstraint.isActive = true
        }
    }

    func slideViewDidFinish(_ sender: SlideView) {
        dismissKeyboard()

        Tracker.shared.track(
            eventWithCategory: "Transaction",
            action: "Transaction Initiated"
        )

        guard let wallet = TariLib.shared.tariWallet else {
            UserFeedback.shared.error(
                title: NSLocalizedString("wallet.error.title", comment: "Wallet error"),
                description: NSLocalizedString("wallet.error.wallet_not_initialized", comment: "Wallet error")
            )
            sender.resetStateWithAnimation(true)
            return
        }

        guard let recipientPublicKey = publicKey else {
            UserFeedback.shared.error(
                title: NSLocalizedString("add_note.error.recipient_public_key.title", comment: "Add note view"),
                description: NSLocalizedString("add_note.error.recipient_public_key.description", comment: "Add note view")
            )
            sender.resetStateWithAnimation(true)
            return
        }

        guard let recipientAmount = amount else {
            UserFeedback.shared.error(
                title: NSLocalizedString("add_note.error.recipient_amount.title", comment: "Add note view"),
                description: NSLocalizedString("add_note.error.recipient_amount.description", comment: "Add note view")
            )
            sender.resetStateWithAnimation(true)
            return
        }

        sendTransaction(
            wallet,
            recipientPublicKey: recipientPublicKey,
            amount: recipientAmount
        )
    }

    private func sendTransaction(_ wallet: Wallet, recipientPublicKey: PublicKey, amount: MicroTari) {
        //Init first so it starts listening for a callback right away
        let sendingVC = SendingTariViewController()

        if let m = attachment {
            sendingVC.note = "\(noteText) \(m.embedUrl ?? "")"
        } else {
            sendingVC.note = noteText
        }

        sendingVC.recipientPubKey = recipientPublicKey
        sendingVC.amount = amount
        self.navigationController?.pushViewController(sendingVC, animated: false)
    }
}

extension AddNoteViewController {
    private func setupNavigationBar() {
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }

    fileprivate func setupNoteTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        titleLabel.font = Theme.shared.fonts.addNoteTitleLabel
        titleLabel.textColor = Theme.shared.colors.addNoteTitleLabel
        titleLabel.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: sidePadding).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: sidePadding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -sidePadding).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.pointSize * 1.1).isActive = true
        titleLabel.text = NSLocalizedString("add_note.title", comment: "Add note view")
    }

    fileprivate func setupSendButton() {
        sendButton.isEnabled = false

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        sendButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        sendButtonBottomConstraint = sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -sidePadding)
        sendButtonBottomConstraint.isActive = true

        sendButton.showSliderText = true
        sendButton.labelText = NSLocalizedString("add_note.slide_to_send", comment: "Add note view")
        sendButton.delegate = self

        //If we're in testmode, the slide to send doesn't seem to work so allow it to be tapped in this case
        if ProcessInfo.processInfo.arguments.contains("ui-test-mode") {
            let tapButtonGesture = UITapGestureRecognizer(target: self, action: #selector (self.slideViewDidFinish (_:)))
            sendButton.addGestureRecognizer(tapButtonGesture)
        }
    }

    fileprivate func setupNoteInput() {
        let font = Theme.shared.fonts.addNoteInputView
        noteInput.delegate = self
        noteInput.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noteInput)
        noteInput.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: sidePadding / 2).isActive = true
        noteInput.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: sidePadding).isActive = true
        noteInput.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -sidePadding).isActive = true
        noteInput.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -sidePadding).isActive = true
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
        notePlaceholder.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sidePadding).isActive = true
        notePlaceholder.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sidePadding).isActive = true
        notePlaceholder.numberOfLines = 0

        notePlaceholder.attributedText = NSAttributedString(
            string: NSLocalizedString("add_note.placeholder", comment: "Add note view"),
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.inputPlaceholder!
            ]
        )

    }
}

public class TariGiphyTheme: GPHTheme {
    public override init() {
        super.init()
        self.type = .light
    }

    public override var textFieldFont: UIFont? {
        return Theme.shared.fonts.searchContactsInputBoxText
    }

//    public override var toolBarSwitchSelectedColor: UIColor { return .green }
//    public override var placeholderColor: UIColor {
//        return .red
//    }
//
//    public override var backgroundColorForLoadingCells: UIColor {
//        return .blue
//    }
}
