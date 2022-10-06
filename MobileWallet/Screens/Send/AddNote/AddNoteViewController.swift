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

final class AddNoteViewController: UIViewController, GiphyDelegate, GPHGridDelegate, UIScrollViewDelegate {

    private static var giphyKeywords = ["money", "money machine", "rich"]
    private static var giphyCurrentKeywordIndex = 0

    private let paymentInfo: PaymentInfo
    private let amount: MicroTari
    private let feePerGram: MicroTari
    private let isOneSidedPayment: Bool
    private let deeplink: TransactionsSendDeeplink?

    private let sidePadding = Theme.shared.sizes.appSidePadding
    private let navigationBar = NavigationBar()
    fileprivate let scrollView = UIScrollView()
    fileprivate let stackView = UIStackView()
    fileprivate let sendButton = SlideView()
    fileprivate var sendButtonBottomConstraint = NSLayoutConstraint()
    fileprivate let titleLabel = UILabel()
    fileprivate let noteInput = UITextView()
    fileprivate var noteText = "" {
        didSet {
            updateTitleColorAndSetSendButtonState()
        }
    }
    private let notePlaceholder = localized("add_note.placeholder")

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
                attachmentContainerHeightConstraint.isActive = false
                attachmentContainerHeightConstraint = attachmentContainer.heightAnchor.constraint(equalToConstant: 0.0)
                attachmentContainerHeightConstraint.isActive = true
                attachmentContainer.isHidden = true
                attachmentCancelView.isHidden = true
            }

            updateTitleColorAndSetSendButtonState()
        }
    }
    
    init(paymentInfo: PaymentInfo, amount: MicroTari, feePerGram: MicroTari, isOneSidedPayment: Bool, deeplink: TransactionsSendDeeplink?) {
        self.paymentInfo = paymentInfo
        self.amount = amount
        self.feePerGram = feePerGram
        self.isOneSidedPayment = isOneSidedPayment
        self.deeplink = deeplink
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        if let note = deeplink?.note {
            noteInput.text = note
            textViewDidChangeSelection(noteInput)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    private func displayAliasOrEmojiId() {
        
        var alias: String?
        
        do {
            alias = try Tari.shared.contacts.findContact(hex: try paymentInfo.publicKey.byteVector.hex)?.alias
        } catch {
        }
        
        guard let alias = alias, !alias.trimmingCharacters(in: .whitespaces).isEmpty else {
            do {
                try navigationBar.showEmojiId(emojiID: paymentInfo.publicKey.emojis, hex: paymentInfo.publicKey.byteVector.hex, presenterController: self)
            } catch {
                PopUpPresenter.show(message: MessageModel(title: localized("navigation_bar.error.show_emoji.title"), message: localized("navigation_bar.error.show_emoji.description"), type: .error))
            }
            return
        }
        
        navigationBar.title = alias
    }

    func updateTitleColorAndSetSendButtonState() {
        if noteText.isEmpty && attachment == nil {
            sendButton.isEnabled = false
            titleLabel.textColor = Theme.shared.colors.addNoteTitleLabel
        } else {
            sendButton.isEnabled = true
            titleLabel.textColor = Theme.shared.colors.addNoteTitleLabelGray
        }
    }

    private func setup() {
        setupNavigationBar()
        view.backgroundColor = Theme.shared.colors.appBackground
        setupSendButton()
        setupGiphy()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: giphyCarouselContainerView.topAnchor).isActive = true

        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical

        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: sidePadding).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -sidePadding).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -sidePadding).isActive = true
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -sidePadding * 2).isActive = true

        setupNoteTitle()
        setupNoteInput()
        setupMediaAttachment()
        view.bringSubviewToFront(navigationBar)
    }

    @objc private func showGiphyPanel() {
        view.endEditing(true)
        giphyModal = GiphyViewController()
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

    @objc private func moveSendButtonUp(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            sendButtonBottomConstraint.isActive = false
            showGiphyCarousel()

            UIView.animate(withDuration: 0.46, delay: 0.008, options: .curveEaseIn, animations: { [weak self] in
                guard let self = self else { return }
                self.sendButtonBottomConstraint = self.sendButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -keyboardHeight)
                self.sendButtonBottomConstraint.isActive = true
                self.view.layoutIfNeeded()
            })
        }
    }

    @objc private func moveSendButtonDown() {
        sendButtonBottomConstraint.isActive = false
        hideGiphyCarousel()

        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.sendButtonBottomConstraint = self.sendButton.bottomAnchor.constraint(equalTo: self.view.safeBottomAnchor)
            self.sendButtonBottomConstraint.isActive = true
            self.view.layoutIfNeeded()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Assume the user is trying to swipe the keyboard down
        if scrollView.contentOffset.y < -60 {
            view.endEditing(true)
        }

        if scrollView.contentOffset.y <= 0 {
            onScrollTopHit(true)
        } else {
            onScrollTopHit(false)
        }
    }

    private func onScrollTopHit(_ isAtTop: Bool) {
        if isAtTop {
            navigationBar.hideShadow()
        } else {
            navigationBar.showShadow()
        }
    }

    private func onSlideToEndAction() {
        dismissKeyboard()

        Tracker.shared.track(
            eventWithCategory: "Transaction",
            action: "Transaction Initiated"
        )

        sendTx(recipientPublicKey: paymentInfo.publicKey, amount: amount, feePerGram: feePerGram)
    }

    private func sendTx(recipientPublicKey: PublicKey, amount: MicroTari, feePerGram: MicroTari) {
        
        var message = noteText
        
        if let attachment = attachment, let embedUrl = attachment.embedUrl {
            message += " \(embedUrl)"
        }
        
        TransactionProgressPresenter.showTransactionProgress(
            presenter: self,
            recipientPublicKey: recipientPublicKey,
            amount: amount,
            feePerGram: feePerGram,
            message: message,
            isOneSidedPayment: isOneSidedPayment,
            yatID: paymentInfo.yatID
        )
    }
}

extension AddNoteViewController {
    private func setupNavigationBar() {
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let stubView = UIView()
        stubView.backgroundColor = navigationBar.backgroundColor
        navigationBar.insertSubview(stubView, at: 0)
        stubView.translatesAutoresizingMaskIntoConstraints = false

        stubView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stubView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        stubView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        stubView.bottomAnchor.constraint(equalTo: navigationBar.topAnchor).isActive = true
    }

    fileprivate func setupNoteTitle() {
        stackView.addArrangedSubview(titleLabel)
        titleLabel.font = Theme.shared.fonts.addNoteTitleLabel
        titleLabel.textColor = Theme.shared.colors.addNoteTitleLabel
        titleLabel.text = localized("add_note.title")

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.heightAnchor.constraint(equalToConstant: sidePadding + titleLabel.font.pointSize).isActive = true
    }

    fileprivate func setupSendButton() {
        sendButton.isEnabled = false

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        sendButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        sendButtonBottomConstraint = sendButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        sendButtonBottomConstraint.isActive = true

        sendButton.showSliderText = true
        sendButton.labelText = localized("add_note.slide_to_send")
        
        sendButton.onSlideToEnd = { [weak self] in
            self?.onSlideToEndAction()
        }
    }

    fileprivate func setupNoteInput() {
        stackView.addArrangedSubview(noteInput)
        stackView.setCustomSpacing(20.0, after: noteInput)
        noteInput.delegate = self
        noteInput.isScrollEnabled = false
        noteInput.font = Theme.shared.fonts.addNoteInputView
        noteInput.textContainerInset = .zero
        noteInput.returnKeyType = .done
        noteInput.textContainer.lineFragmentPadding = 0
        noteInput.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        noteInput.text = notePlaceholder
        noteInput.textColor = .lightGray
    }

    private func setupMediaAttachment() {
        stackView.addArrangedSubview(attachmentContainer)
        attachmentContainer.translatesAutoresizingMaskIntoConstraints = false
        attachmentContainerHeightConstraint = attachmentContainer.heightAnchor.constraint(equalToConstant: 0.0)
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

        // Adding extra space so if the gif goes under the slide button it can be scrolled up
        let spacerKeyboardView = UIView()
        spacerKeyboardView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(spacerKeyboardView)
        spacerKeyboardView.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }

    private func setupGiphy() {
        // Pre selected caurousal
        let giphyVC = GiphyGridController()

        giphyCarouselContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(giphyCarouselContainerView)
        giphyCarouselContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: giffPadding).isActive = true
        giphyCarouselContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -giffPadding).isActive = true
        giphyCarouselBottomConstraint = giphyCarouselContainerView.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -(giffPadding * 2))
        giphyCarouselBottomConstraint.isActive = true
        view.bringSubviewToFront(sendButton)

        // Giphy settings
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
        searchGiphyButton.setTitle(localized("add_note.search_giphy_button"), for: .normal)
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

        let keyword = AddNoteViewController.giphyKeywords[
            AddNoteViewController.giphyCurrentKeywordIndex % AddNoteViewController.giphyKeywords.count
        ]
        giphyVC.content = GPHContent.search(
            withQuery: keyword,
            mediaType: .gif,
            language: .english
        )
        giphyVC.update()
        AddNoteViewController.giphyCurrentKeywordIndex = AddNoteViewController.giphyCurrentKeywordIndex + 1
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

extension AddNoteViewController: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        var trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Limit to the size of a tx note
        let charLimit = 280
        if trimmedText.count > charLimit {
            TariLogger.warn("Limitting tx note to \(charLimit) chars")
            trimmedText = String(trimmedText.prefix(charLimit))
            textView.text = trimmedText
        }

        noteText = trimmedText.replacingOccurrences(of: notePlaceholder, with: "")
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text.count == 1 && text.isEmpty {
            textView.textColor = .lightGray
            textView.text = notePlaceholder
            let newPosition = textView.beginningOfDocument
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
            return false
        } else if textView.text == notePlaceholder {
            if text == "\n" {
                textView.resignFirstResponder()
                return false
            }
            if text.isEmpty {
                return false
            }
            textView.textColor = .black
            textView.text = ""
            return true
        }

        // Stop new line chars, instead close the keyboard on return key
        if text.components(separatedBy: CharacterSet.newlines).count > 1 {
            view.endEditing(true)
            return false
        }
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == notePlaceholder {
            DispatchQueue.main.async {
                let newPosition = textView.beginningOfDocument
                textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
            }
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = notePlaceholder
            textView.textColor = .lightGray
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
}
