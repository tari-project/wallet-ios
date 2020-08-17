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

class AddNoteViewController: UIViewController, UITextViewDelegate, SlideViewDelegate, GiphyDelegate, GPHGridDelegate, UIScrollViewDelegate {
    var publicKey: PublicKey?
    var amount: MicroTari?
    var deepLinkParams: DeepLinkParams?
    private let sidePadding = Theme.shared.sizes.appSidePadding
    private let navigationBar = NavigationBar()
    fileprivate let scrollView = UIScrollView()
    fileprivate let stackView = UIStackView()
    fileprivate let sendButton = SlideView()
    fileprivate var sendButtonBottomConstraint = NSLayoutConstraint()
    fileprivate var spacerViewHeightConstraint = NSLayoutConstraint() //For adding extar space to the stack view so it can be scrolled up with the keyboard open
    fileprivate let titleLabel = UILabel()
    fileprivate let noteInput = UITextView()
    fileprivate let notePlaceholder = UILabel()
    fileprivate var noteText = "" {
        didSet {
            setSendButtonState()
        }
    }
    private let poweredByGiphyImageView = UIImageView(image: Theme.shared.images.poweredByGiphy)
    private let giphyCarouselContainerView = UIView()
    private var giphyCarouselBottomConstraint = NSLayoutConstraint()
    private let giffPadding: CGFloat = 7
    private var giphyModal = GiphyViewController()
    private let searchGiphyButton = UIButton()

    let attachmentContainer = UIView()
    var attachmentContainerHeightConstraint = NSLayoutConstraint()
    let attachmentView = GPHMediaView()
    let attachmentCancelView = UIView()
    var attachment: GPHMedia? = nil {
        didSet {
            attachmentView.media = attachment
            if let media = attachment {
                attachmentContainer.isHidden = false
                hideGiphyCarousel()
                attachmentCancelView.isHidden = false
                attachmentContainerHeightConstraint.isActive = false
                attachmentContainerHeightConstraint = attachmentContainer.heightAnchor.constraint(equalTo: attachmentContainer.widthAnchor, multiplier: 1 / media.aspectRatio)
                attachmentContainerHeightConstraint.isActive = true
            } else {
                showGiphyCarousel()
                attachmentContainer.isHidden = true
                attachmentCancelView.isHidden = true
            }

            setSendButtonState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        setup()
        hideKeyboardWhenTappedAroundOrSwipedDown(view: attachmentContainer)
        displayAliasOrEmojiId()
        Tracker.shared.track("/home/send_tari/add_note", "Send Tari - Add Note")
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    private func displayAliasOrEmojiId() {
        guard let wallet = TariLib.shared.tariWallet, let pubKey = publicKey else {
            return
        }

        do {
            guard let contact = try wallet.contacts.0?.find(publicKey: pubKey) else { return }
            if contact.alias.0.trimmingCharacters(in: .whitespaces).isEmpty {
                try navigationBar.showEmojiId(pubKey, inViewController: self)
            } else {
                navigationBar.title = contact.alias.0
            }
        } catch {
            do {
                try navigationBar.showEmojiId(pubKey, inViewController: self)
            } catch {
                UserFeedback.shared.error(
                    title: NSLocalizedString("navigation_bar.error.show_emoji.title", comment: "Navigation bar"),
                    description: NSLocalizedString("navigation_bar.error.show_emoji.description", comment: "Navigation bar"),
                    error: error
                )
            }
        }
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

        setupNoteTitle()
        setupSendButton()
        setupGiphy()
        setupNoteInput()
        setupMediaAttachment()
    }

    @objc private func showGiphyPanel() {
        view.endEditing(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.giphyModal = GiphyViewController()
            self.giphyModal.mediaTypeConfig = [.gifs]
            self.giphyModal.theme = TariGiphyTheme()
            self.giphyModal.delegate = self
            GiphyViewController.trayHeightMultiplier = 0.8
            self.present(self.giphyModal, animated: true, completion: nil)
        }
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

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        //Stop new line chars, instead close the keyboard on return key
        if text.components(separatedBy: CharacterSet.newlines).count > 1 {
            view.endEditing(true)
            return false
        }

        return true
    }

    @objc private func moveSendButtonUp(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            sendButtonBottomConstraint.isActive = false

            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.sendButtonBottomConstraint = self.sendButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -keyboardHeight)
                self.sendButtonBottomConstraint.isActive = true
                self.spacerViewHeightConstraint.constant = keyboardHeight + 80
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
            self.spacerViewHeightConstraint.constant = 100
            self.view.layoutIfNeeded()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //Assume the user is trying to swipe the keyboard down
        if scrollView.contentOffset.y < -60 {
            view.endEditing(true)
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

        sendButton.variation = .loading
        UIApplication.shared.keyWindow?.isUserInteractionEnabled = false
        navigationBar.backButton.isHidden = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            UIApplication.shared.keyWindow?.isUserInteractionEnabled = true
            self.navigationBar.backButton.isHidden = false
            self.sendTransaction(
                wallet,
                recipientPublicKey: recipientPublicKey,
                amount: recipientAmount
            )
            self.sendButton.variation = .slide
        }
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
        let titleView = UIView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(titleLabel)
        titleLabel.font = Theme.shared.fonts.addNoteTitleLabel
        titleLabel.textColor = Theme.shared.colors.addNoteTitleLabel
        titleLabel.bottomAnchor.constraint(equalTo: titleView.bottomAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: sidePadding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor, constant: -sidePadding).isActive = true
        titleLabel.text = NSLocalizedString("add_note.title", comment: "Add note view")

        titleView.heightAnchor.constraint(equalToConstant: sidePadding + titleLabel.font.pointSize).isActive = true
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
        let noteView = UIView()
        noteView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(noteView)
        noteView.heightAnchor.constraint(greaterThanOrEqualToConstant: 86).isActive = true

        let font = Theme.shared.fonts.addNoteInputView
        noteInput.delegate = self
        noteInput.isScrollEnabled = false
        noteInput.translatesAutoresizingMaskIntoConstraints = false
        noteView.addSubview(noteInput)
        noteInput.topAnchor.constraint(equalTo: noteView.topAnchor, constant: sidePadding / 2).isActive = true
        noteInput.leadingAnchor.constraint(equalTo: noteView.leadingAnchor, constant: sidePadding).isActive = true
        noteInput.trailingAnchor.constraint(equalTo: noteView.trailingAnchor, constant: -sidePadding).isActive = true
        noteInput.bottomAnchor.constraint(equalTo: noteView.bottomAnchor, constant: -sidePadding).isActive = true
        noteInput.textContainerInset = .zero
        noteInput.returnKeyType = .done
        noteInput.textContainer.lineFragmentPadding = 0
        noteInput.sizeToFit()

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

    private func setupMediaAttachment() {
        let attachmentSection = UIView()
        attachmentSection.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(attachmentSection)

        attachmentSection.addSubview(attachmentContainer)
        attachmentContainer.translatesAutoresizingMaskIntoConstraints = false
        attachmentContainer.leadingAnchor.constraint(equalTo: attachmentSection.leadingAnchor, constant: sidePadding).isActive = true
        attachmentContainer.trailingAnchor.constraint(equalTo: attachmentSection.trailingAnchor, constant: -sidePadding).isActive = true
        attachmentContainer.topAnchor.constraint(equalTo: attachmentSection.topAnchor).isActive = true
        attachmentContainer.bottomAnchor.constraint(equalTo: attachmentSection.bottomAnchor).isActive = true
        attachmentContainerHeightConstraint = attachmentContainer.heightAnchor.constraint(equalTo: attachmentContainer.widthAnchor, multiplier: 1)
        attachmentContainerHeightConstraint.isActive = true
        attachmentContainer.layer.cornerRadius = 20
        attachmentContainer.layer.masksToBounds = true

        attachmentContainer.addSubview(attachmentView)
        attachmentView.translatesAutoresizingMaskIntoConstraints = false
        attachmentView.topAnchor.constraint(equalTo: attachmentContainer.topAnchor).isActive = true
        attachmentView.bottomAnchor.constraint(equalTo: attachmentContainer.bottomAnchor).isActive = true
        attachmentView.leadingAnchor.constraint(equalTo: attachmentContainer.leadingAnchor).isActive = true
        attachmentView.trailingAnchor.constraint(equalTo: attachmentContainer.trailingAnchor).isActive = true

        attachmentCancelView.isHidden = true
        attachmentCancelView.translatesAutoresizingMaskIntoConstraints = false
        attachmentContainer.addSubview(attachmentCancelView)
        attachmentCancelView.topAnchor.constraint(equalTo: attachmentContainer.topAnchor).isActive = true
        attachmentCancelView.trailingAnchor.constraint(equalTo: attachmentContainer.trailingAnchor).isActive = true
        attachmentCancelView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        attachmentCancelView.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let cancelImageView = UIImageView(image: Theme.shared.images.cancelGiphy)
        cancelImageView.translatesAutoresizingMaskIntoConstraints = false
        attachmentCancelView.addSubview(cancelImageView)
        cancelImageView.centerXAnchor.constraint(equalTo: attachmentCancelView.centerXAnchor).isActive = true
        cancelImageView.centerYAnchor.constraint(equalTo: attachmentCancelView.centerYAnchor).isActive = true

        attachmentCancelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (removeAttachment)))

        //Adding extra space so if the gif goes under the slide button it can be scrolled up
        let spacerKeyboardView = UIView()
        spacerKeyboardView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacerKeyboardView)
        spacerViewHeightConstraint = spacerKeyboardView.heightAnchor.constraint(equalToConstant: 0)
        spacerViewHeightConstraint.isActive = true
    }

    private func setupGiphy() {
        //Pre selected caurousal
        let giphyVC = GiphyGridController()

        giphyCarouselContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(giphyCarouselContainerView)
        giphyCarouselContainerView.leftAnchor.constraint(equalTo: view.safeLeftAnchor, constant: giffPadding).isActive = true
        giphyCarouselContainerView.rightAnchor.constraint(equalTo: view.safeRightAnchor, constant: -giffPadding).isActive = true
        giphyCarouselBottomConstraint = giphyCarouselContainerView.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -(giffPadding * 2))
        giphyCarouselBottomConstraint.isActive = true
        view.bringSubviewToFront(sendButton)

        //Giphy settings
        giphyVC.cellPadding = giffPadding
        giphyVC.direction = .horizontal
        giphyVC.numberOfTracks = 1
        giphyVC.view.backgroundColor = .clear
        giphyVC.imageType = .gif
        giphyVC.direction = .horizontal
        giphyVC.rating = .ratedPG13
        giphyVC.fixedSizeCells = true
        giphyVC.theme = TariGiphyTheme()
        giphyVC.delegate = self
        addChild(giphyVC)
        giphyCarouselContainerView.addSubview(giphyVC.view)

        giphyVC.view.translatesAutoresizingMaskIntoConstraints = false

        giphyVC.view.leadingAnchor.constraint(equalTo: giphyCarouselContainerView.leadingAnchor).isActive = true
        giphyVC.view.trailingAnchor.constraint(equalTo: giphyCarouselContainerView.trailingAnchor).isActive = true
        giphyVC.view.bottomAnchor.constraint(equalTo: giphyCarouselContainerView.bottomAnchor).isActive = true
        giphyVC.view.heightAnchor.constraint(equalToConstant: 64).isActive = true

        searchGiphyButton.setImage(Theme.shared.images.searchIcon, for: .normal)
        searchGiphyButton.tintColor = Theme.shared.colors.searchGiphyButtonTitle
        searchGiphyButton.backgroundColor = Theme.shared.colors.searchGiphyButtonBackground
        searchGiphyButton.setTitleColor(Theme.shared.colors.searchGiphyButtonTitle, for: .normal)
        searchGiphyButton.titleLabel?.font = Theme.shared.fonts.searchGiphyButtonTitle
        searchGiphyButton.setTitle(NSLocalizedString("add_note.search_giphy_button", comment: "Add note view"), for: .normal)
        searchGiphyButton.translatesAutoresizingMaskIntoConstraints = false
        searchGiphyButton.layer.cornerRadius = 3
        searchGiphyButton.titleEdgeInsets = .init(top: 0, left: 5, bottom: 0, right: 0)
        giphyCarouselContainerView.addSubview(searchGiphyButton)
        searchGiphyButton.heightAnchor.constraint(equalToConstant: 18).isActive = true
        searchGiphyButton.leadingAnchor.constraint(equalTo: giphyCarouselContainerView.leadingAnchor).isActive = true
        searchGiphyButton.widthAnchor.constraint(equalToConstant: 95).isActive = true
        searchGiphyButton.topAnchor.constraint(equalTo: giphyCarouselContainerView.topAnchor).isActive = true
        searchGiphyButton.bottomAnchor.constraint(equalTo: giphyVC.view.topAnchor, constant: -giffPadding).isActive = true
        searchGiphyButton.addTarget(self, action: #selector(showGiphyPanel), for: .touchUpInside)
        searchGiphyButton.isHidden = true

        poweredByGiphyImageView.translatesAutoresizingMaskIntoConstraints = false
        giphyCarouselContainerView.addSubview(poweredByGiphyImageView)
        let poweredByWidth: CGFloat = 125
        poweredByGiphyImageView.heightAnchor.constraint(equalToConstant: poweredByWidth * 0.11).isActive = true
        poweredByGiphyImageView.widthAnchor.constraint(equalToConstant: poweredByWidth).isActive = true
        poweredByGiphyImageView.trailingAnchor.constraint(equalTo: giphyCarouselContainerView.trailingAnchor, constant: giffPadding).isActive = true
        poweredByGiphyImageView.bottomAnchor.constraint(equalTo: giphyVC.view.topAnchor, constant: -giffPadding).isActive = true
        poweredByGiphyImageView.isHidden = true

        giphyVC.content = GPHContent.search(withQuery: "Money", mediaType: .gif, language: .english)
        giphyVC.update()
    }

    private func showGiphyCarousel(animated: Bool = true) {
        giphyCarouselBottomConstraint.constant = -(giffPadding * 2)
        UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        UIView.animate(withDuration: animated ? CATransaction.animationDuration() * 2 : 0) { [weak self] in
            self?.giphyCarouselContainerView.alpha = 1.0
        }
    }

    private func hideGiphyCarousel(animated: Bool = true) {
        giphyCarouselBottomConstraint.constant = giphyCarouselContainerView.frame.height
        UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        UIView.animate(withDuration: animated ? CATransaction.animationDuration() / 2 : 0) { [weak self] in
            self?.giphyCarouselContainerView.alpha = 0.0
        }
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
