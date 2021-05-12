/*
 Package MobileWallet
 Created by Gabriel Lupu on 20/02/2020
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

class EmojiIdView: UIView {

    // var containerView = UIView()
    weak var blackoutParent: UIView?
    private lazy var blackoutView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        guard let bounds =  UIApplication.shared.keyWindow?.bounds else { return view }
        view.frame = bounds
        view.alpha = 0.0
        return view
    }()

    var expanded: Bool = false
    var blackoutWhileExpanded = true
    var tapToExpand: ((_ expanded: Bool) -> Void)?
    private var initialWidth: CGFloat = CGFloat(172)

    private let condensedEmojiIdContainer = UIView()
    private lazy var condensedEmojiIdLabel = UILabel()

    private var expandedEmojiIdScrollView = UIScrollView()
    private lazy var expandedEmojiIdLabel = UILabel()

    private var hexPubKeyTipView: UIView?
    private var hexPubKeyTipLabel: UILabel?
    private var hexPubKeyTipViewBottomConstraint: NSLayoutConstraint?
    private var hexPubKeyTipViewHiddenBottomConstraint = CGFloat(250)

    private var labelInitialWidth: NSLayoutConstraint?
    private var labelWidthConstraint: NSLayoutConstraint?
    private var labelCenterConstraint: NSLayoutConstraint?

    private let emojiMenu = EmojiMenuView()

    private var emojiText: String!
    private var pubKeyHex: String!

    private var tapActionIsDisabled = false

    var cornerRadius: CGFloat = 6.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
            condensedEmojiIdLabel.layer.cornerRadius = cornerRadius
        }
    }

    private var superVC: UIViewController?

    func setupView(pubKey: PublicKey,
                   textCentered: Bool,
                   inViewController vc: UIViewController? = nil,
                   initialWidth: CGFloat = CGFloat(185),
                   initialHeight: CGFloat = CGFloat(40),
                   showContainerViewBlur: Bool = true,
                   cornerRadius: CGFloat = 6.0) {
        self.backgroundColor = .clear
        self.cornerRadius = cornerRadius
        blackoutView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
        superVC = vc
        superVC?.navigationController?.navigationBar.layer.zPosition = 0
        emojiText = pubKey.emojis.0
        pubKeyHex = pubKey.hex.0
        blackoutWhileExpanded = showContainerViewBlur
        // tap gesture
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap(_:))))
        prepareCondensedEmojiId(textCentered: textCentered,
                                width: initialWidth,
                                height: initialHeight)
        prepareExpandedEmojiId(height: initialHeight)
    }

    private func prepareCondensedEmojiId(textCentered: Bool,
                                         width: CGFloat,
                                         height: CGFloat) {
        self.addSubview(condensedEmojiIdContainer)
        condensedEmojiIdContainer.translatesAutoresizingMaskIntoConstraints = false
        condensedEmojiIdContainer.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        if textCentered {
            condensedEmojiIdContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        } else {
            condensedEmojiIdContainer.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        }
        self.initialWidth = width
        labelInitialWidth = condensedEmojiIdContainer.widthAnchor.constraint(equalToConstant: initialWidth)
        labelInitialWidth?.isActive = true
        condensedEmojiIdContainer.heightAnchor.constraint(equalToConstant: height).isActive = true
        condensedEmojiIdContainer.layer.shadowColor = Theme.shared.colors.emojiButtonShadow!.cgColor
        condensedEmojiIdContainer.layer.shadowOffset = .zero
        condensedEmojiIdContainer.layer.shadowRadius = cornerRadius * 1.2
        condensedEmojiIdContainer.layer.shadowOpacity = 1.0
        condensedEmojiIdContainer.clipsToBounds = true
        condensedEmojiIdContainer.layer.masksToBounds = false
        condensedEmojiIdContainer.addSubview(condensedEmojiIdLabel)

        condensedEmojiIdLabel.layer.masksToBounds = true
        condensedEmojiIdLabel.backgroundColor = Theme.shared.colors.creatingWalletEmojisLabelBackground
        condensedEmojiIdLabel.textAlignment = .center
        condensedEmojiIdLabel.textColor = Theme.shared.colors.emojisSeparator!
        condensedEmojiIdLabel.text = getCondensedEmojiId() + " "
        condensedEmojiIdLabel.letterSpacing(value: 1.6)
        condensedEmojiIdLabel.translatesAutoresizingMaskIntoConstraints = false

        condensedEmojiIdLabel.leadingAnchor.constraint(equalTo: condensedEmojiIdContainer.leadingAnchor).isActive = true
        condensedEmojiIdLabel.trailingAnchor.constraint(equalTo: condensedEmojiIdContainer.trailingAnchor).isActive = true
        condensedEmojiIdLabel.topAnchor.constraint(equalTo: condensedEmojiIdContainer.topAnchor).isActive = true
        condensedEmojiIdLabel.bottomAnchor.constraint(equalTo: condensedEmojiIdContainer.bottomAnchor).isActive = true
        condensedEmojiIdLabel.heightAnchor.constraint(equalToConstant: height).isActive = true

        labelCenterConstraint = condensedEmojiIdLabel.centerXAnchor.constraint(equalTo: condensedEmojiIdContainer.centerXAnchor)
        labelCenterConstraint?.isActive = true
    }

    private func prepareExpandedEmojiId(height: CGFloat) {
        // prepare expanded emoji id scroll view
        expandedEmojiIdScrollView.backgroundColor = UIColor.white
        expandedEmojiIdScrollView.layer.cornerRadius = cornerRadius * 1.2
        expandedEmojiIdScrollView.clipsToBounds = true
        expandedEmojiIdScrollView.layer.masksToBounds = true
        expandedEmojiIdScrollView.showsHorizontalScrollIndicator = false
        expandedEmojiIdScrollView.bounces = true

        // prepare expanded emoji id label
        condensedEmojiIdLabel.font = UIFont.systemFont(ofSize: 14.0)
        condensedEmojiIdLabel.adjustsFontSizeToFitWidth = false
        // condensedEmojiIdLabel.copyText = emojiText
        expandedEmojiIdLabel.numberOfLines = 0
        expandedEmojiIdLabel.adjustsFontSizeToFitWidth = false
        expandedEmojiIdLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap(_:))))
        expandedEmojiIdLabel.isUserInteractionEnabled = true
        expandedEmojiIdLabel.layer.masksToBounds = true
        expandedEmojiIdLabel.backgroundColor = Theme.shared.colors.creatingWalletEmojisLabelBackground
        expandedEmojiIdLabel.textAlignment = .center
        expandedEmojiIdLabel.textColor = Theme.shared.colors.emojisSeparator!
        expandedEmojiIdLabel.text = getExpandedEmojiId() + " "
        expandedEmojiIdLabel.font = UIFont.systemFont(ofSize: 14.0)
        expandedEmojiIdLabel.letterSpacing(value: 1.6)
        expandedEmojiIdLabel.sizeToFit()
        expandedEmojiIdLabel.frame = CGRect(
            x: 14,
            y: 0,
            width: expandedEmojiIdLabel.frame.width,
            height: height
        )
        expandedEmojiIdScrollView.contentSize = CGSize(
            width: expandedEmojiIdLabel.frame.size.width + 14*2,
            height: height
        )
        expandedEmojiIdScrollView.addSubview(expandedEmojiIdLabel)
    }

    @objc func tap(_ gestureRecognizer: UITapGestureRecognizer) {
        if tapActionIsDisabled { return }
        if expanded {
            shrink(callTapCompletion: true)
        } else {
            expand(callTapCompletion: true)
        }
    }

    func expand(completion: (() -> Void)? = nil, callTapCompletion: Bool = false, animated: Bool = true) {
        guard let scrollViewFrame = condensedEmojiIdContainer.globalFrame else { return }
        tapActionIsDisabled = true
        expanded = true
        // If they're typing somewhere, close the keyboard
        superVC?.view.endEditing(true)
        // fade out label container
        // fade in blackout
        fadeView(view: condensedEmojiIdContainer, fadeOut: true)
        if blackoutWhileExpanded {
            UIApplication.shared.keyWindow?.addSubview(blackoutView)
            fadeView(view: blackoutView, fadeOut: false, maxAlpha: 0.65)
            showCopyEmojiIdButton()
            showHexPubKeyCopyTip()
        }
        // add and show scroll view
        let padding = UIDevice.current.userInterfaceIdiom == .pad ? 60 : Theme.shared.sizes.appSidePadding
        let scrollViewTargetWidth = blackoutView.frame.width - padding * 2
        expandedEmojiIdScrollView.frame = scrollViewFrame
        // animate scroll view frame
        let scrollViewTargetFrame = CGRect(
            x: padding,
            y: scrollViewFrame.origin.y,
            width: scrollViewTargetWidth,
            height: scrollViewFrame.height
        )
        UIApplication.shared.keyWindow?.addSubview(expandedEmojiIdScrollView)
        if animated {
            expandedEmojiIdScrollView.alpha = 0
            expandedEmojiIdScrollView.setContentOffset(
                CGPoint(x: expandedEmojiIdLabel.frame.width / 2, y: 0),
                animated: false
            )
            fadeView(view: expandedEmojiIdScrollView, fadeOut: false)
            UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0) {
                [weak self] in
                self?.expandedEmojiIdScrollView.frame = scrollViewTargetFrame
            }
            UIView.animate(withDuration: 0.5, animations: {
                [weak self] in
                self?.expandedEmojiIdScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            }) {
                [weak self] (_) in
                self?.tapActionIsDisabled = false
            }
        } else {
            expandedEmojiIdScrollView.alpha = 1
            expandedEmojiIdScrollView.frame = scrollViewTargetFrame
            tapActionIsDisabled = false
        }
        if callTapCompletion == true {
            tapToExpand?(true)
        }
    }

    override var alpha: CGFloat {
        get {
            return super.alpha
        }
        set {
            super.alpha = newValue
            expandedEmojiIdScrollView.alpha = newValue
        }
    }

    func shrink(completion: (() -> Void)? = nil, callTapCompletion: Bool = false, animated: Bool = true) {
        guard let scrollViewFrame = condensedEmojiIdContainer.globalFrame else { return }
        tapActionIsDisabled = true
        expanded = false
        let scrolled = expandedEmojiIdScrollView.contentOffset.x > 0
        expandedEmojiIdScrollView.setContentOffset(
            CGPoint(x: 0, y: 0),
            animated: animated
        )
        // hide copy emoji id button & public key hex tip
        if blackoutWhileExpanded {
            DispatchQueue.main.asyncAfter(deadline: .now() + ((scrolled && animated) ? 0.30 : 0)) {
                [weak self] in
                self?.hideExpandedViews(
                    animated: true,
                    scrollViewFrame: scrollViewFrame,
                    callTapCompletion: callTapCompletion
                )
                self?.hideCopyEmojiIdButton {
                    completion?()
                }
                self?.hideHexPubKeyCopyTip()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + ((scrolled && animated) ? 0.30 : 0)) {
                [weak self] in
                self?.hideExpandedViews(
                    animated: animated,
                    scrollViewFrame: scrollViewFrame,
                    callTapCompletion: callTapCompletion
                )
                completion?()
            }
        }
    }

    private func hideExpandedViews(animated: Bool,
                                   scrollViewFrame: CGRect,
                                   callTapCompletion: Bool) {
        if !animated {
            if blackoutWhileExpanded {
                blackoutView.removeFromSuperview()
            }
            expandedEmojiIdScrollView.removeFromSuperview()
            condensedEmojiIdContainer.alpha = 1
            if callTapCompletion == true {
                tapToExpand?(false)
            }
            return
        }
        UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0) {
            [weak self] in
            self?.expandedEmojiIdScrollView.frame = scrollViewFrame
        }
        if self.blackoutWhileExpanded {
            self.fadeView(view: self.blackoutView, fadeOut: true) {
                [weak self] in
                self?.blackoutView.removeFromSuperview()
            }
        }
        // fade out scroll view
        self.fadeView(view: self.expandedEmojiIdScrollView, fadeOut: true) {
            [weak self] in
            self?.expandedEmojiIdScrollView.removeFromSuperview()
        }
        // fade in condensed emoji id
        self.fadeView(view: self.condensedEmojiIdContainer, fadeOut: false) {
            [weak self] in
            self?.tapActionIsDisabled = false
            if callTapCompletion == true {
                self?.tapToExpand?(false)
            }
        }
    }

    private func getCondensedEmojiId() -> String {
        let firstThreeChar = emojiText.prefix(3)
        let lastThreeChar = emojiText.suffix(3)
        return "\(firstThreeChar)•••\(lastThreeChar)"
    }

    private func getExpandedEmojiId() -> String {
        return emojiText.insertSeparator(" | ", atEvery: 3)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            superVC?.navigationController?.navigationBar.layer.zPosition = 0
            hideCopyEmojiIdButton()
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if clipsToBounds || isHidden || alpha == 0 {
            return nil
        }

        for subview in subviews.reversed() {
            let subPoint = subview.convert(point, from: self)
            if let result = subview.hitTest(subPoint, with: event) {
                return result
            }
        }
        return super.hitTest(point, with: event)
    }

    deinit {
        UIApplication.shared.menuTabBarController?.tabBar.alpha = 1
        UIApplication.shared.menuTabBarController?.tabBar.isUserInteractionEnabled = true
    }
}

// MARK: blackout behavior

extension EmojiIdView {

    private func showCopyEmojiIdButton(completion: (() -> Void)? = nil) {
        emojiMenu.alpha = 0.0
        emojiMenu.title = localized("emoji.copy")

        emojiMenu.completion = {
            [weak self] isLongPress in
            guard let self = self else { return }
            self.tapActionIsDisabled = true
            if isLongPress {
                self.copyToClipboard(string: self.pubKeyHex)
            } else {
                self.copyToClipboard(string: self.emojiText)
            }
            self.hideCopyEmojiIdButton()
            self.showCopiedView {
                [weak self] in
                self?.shrink(callTapCompletion: true)
            }
        }

        UIApplication.shared.keyWindow?.addSubview(emojiMenu)
        guard let globalFrame = condensedEmojiIdContainer.globalFrame else { return }
        let emojiMenuSize = CGSize(width: 119, height: 37)
        let xPosition = (bounds.width / 2) - (emojiMenuSize.width / 2) + 25
        emojiMenu.alpha = 0.0
        emojiMenu.frame = CGRect(
            x: xPosition,
            y: globalFrame.origin.y + globalFrame.height,
            width: emojiMenuSize.width,
            height: emojiMenuSize.height
        )
        emojiMenu.button.alpha = 1

        UIView.animate(withDuration: 0.5,
                       delay: 0.3,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 5,
                       options: .curveEaseInOut,
                       animations: { [weak self] in
            self?.emojiMenu.alpha = 1.0
            self?.emojiMenu.frame = CGRect(x: xPosition, y: globalFrame.origin.y + 45, width: emojiMenuSize.width, height: emojiMenuSize.height)
        }) {
            (_) in
            completion?()
        }

        fadeView(view: emojiMenu, fadeOut: false)
    }

    private func showHexPubKeyCopyTip() {
        hexPubKeyTipView = UIView()
        hexPubKeyTipLabel = UILabel()
        guard let tipView = hexPubKeyTipView,
              let tipLabel = hexPubKeyTipLabel,
              let parentView = UIApplication.shared.keyWindow else {
            return
        }
        parentView.addSubview(tipView)
        parentView.bringSubviewToFront(tipView)

        tipView.backgroundColor = UIColor.white
        tipView.layer.cornerRadius = 4

        tipView.translatesAutoresizingMaskIntoConstraints = false
        tipView.widthAnchor.constraint(
            equalTo: parentView.widthAnchor,
            constant: -Theme.shared.sizes.appSidePadding
        ).isActive = true
        tipView.centerXAnchor.constraint(
            equalTo: parentView.centerXAnchor
        ).isActive = true
        hexPubKeyTipViewBottomConstraint = tipView.bottomAnchor.constraint(
            equalTo: parentView.safeBottomAnchor,
            constant: hexPubKeyTipViewHiddenBottomConstraint
        )
        hexPubKeyTipViewBottomConstraint?.isActive = true

        tipLabel.text = localized("emoji.hex_tip")
        tipLabel.font = Theme.shared.fonts.profileMiddleLabel
        tipLabel.textColor = Theme.shared.colors.profileMiddleLabel!
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        tipView.addSubview(tipLabel)
        tipLabel.interlineSpacing(spacingValue: 2)
        tipLabel.leadingAnchor.constraint(
            equalTo: tipView.leadingAnchor,
            constant: 12
        ).isActive = true
        tipLabel.trailingAnchor.constraint(
            equalTo: tipView.trailingAnchor,
            constant: -12
        ).isActive = true
        tipLabel.topAnchor.constraint(
            equalTo: tipView.topAnchor,
            constant: 12
        ).isActive = true
        tipView.bottomAnchor.constraint(
            equalTo: tipLabel.bottomAnchor,
            constant: 12
        ).isActive = true
        tipLabel.numberOfLines = 0
        tipLabel.lineBreakMode = .byWordWrapping
        tipLabel.sizeToFit()
        parentView.layoutIfNeeded()

        hexPubKeyTipViewBottomConstraint?.constant =  -Theme.shared.sizes.appSidePadding / 2
        UIView.animate(
            withDuration: 0.5,
            delay: 0.3,
            options: .curveEaseInOut) {
            parentView.layoutIfNeeded()
        }
    }

    private func hideCopyEmojiIdButton(completion: (() -> Void)? = nil) {
        fadeView(view: emojiMenu, fadeOut: true) { [weak self] in
            self?.emojiMenu.removeFromSuperview()
            completion?()
        }
    }

    private func hideHexPubKeyCopyTip() {
        hexPubKeyTipViewBottomConstraint?.constant =  hexPubKeyTipViewHiddenBottomConstraint
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: .curveEaseInOut) {
            UIApplication.shared.keyWindow?.layoutIfNeeded()
        } completion: {
            [weak self]
            (_) in
            self?.hexPubKeyTipView?.removeFromSuperview()
            self?.hexPubKeyTipViewBottomConstraint = nil
            self?.hexPubKeyTipLabel = nil
            self?.hexPubKeyTipView = nil
        }
    }

    private func fadeView(view: UIView, fadeOut: Bool, maxAlpha: CGFloat = 1.0, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.35, animations: {
            view.alpha = fadeOut ? 0.0 : maxAlpha
        }) { _ in
            completion?()
        }
    }
}

private class EmojiMenuView: UIView {

    let button = TextButton()
    var completion: ((Bool) -> Void)?

    var title: String? {
        didSet {
            button.setTitle(localized(title ?? ""), for: .normal)
            button.titleLabel?.font = Theme.shared.fonts.copyButton
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupButton()
    }

    @objc func onTap(_ sender: Any?) {
        completion?(false)
    }

    @objc func onLongPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            completion?(true)
        }
    }

    override func draw(_ rect: CGRect) {
        let bubbleSpace = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y + 5, width: self.bounds.width, height: self.bounds.height - 5)
        let bubblePath = UIBezierPath(roundedRect: bubbleSpace, cornerRadius: 4.0)

        UIColor.white.setStroke()
        UIColor.white.setFill()
        bubblePath.stroke()
        bubblePath.fill()

        let trianglePath = UIBezierPath()
        let startPoint = CGPoint(x: (bounds.maxX / 2) - 3, y: bounds.minY + 5)
        let tipPoint = CGPoint(x: bounds.maxX / 2, y: bounds.minY)
        let endPoint = CGPoint(x: (bounds.maxX / 2) + 3, y: bounds.minY + 5)

        trianglePath.move(to: startPoint)
        trianglePath.addLine(to: tipPoint)
        trianglePath.addLine(to: endPoint)
        trianglePath.close()
        UIColor.white.setStroke()
        UIColor.white.setFill()
        trianglePath.stroke()
        trianglePath.fill()
    }

    private func setupButton() {
        button.setVariation(.secondary)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        button.topAnchor.constraint(equalTo: topAnchor, constant: 3).isActive = true
        button.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        button.heightAnchor.constraint(equalTo: heightAnchor, constant: -3).isActive = true

        button.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
        button.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPress)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: "COPIED" function & view

extension EmojiIdView {

    func copyToClipboard(string: String) {
        let board = UIPasteboard.general
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        board.string = string
    }

    private func showCopiedView(completion: (() -> Void)? = nil) {
        // frames
        let containerFrame = CGRect(
            x: expandedEmojiIdScrollView.frame.origin.x,
            y: expandedEmojiIdScrollView.frame.origin.y,
            width: expandedEmojiIdScrollView.frame.size.width,
            height: expandedEmojiIdScrollView.frame.size.height
        )
        let subviewFrame = CGRect(
            x: 0,
            y: 0,
            width: expandedEmojiIdScrollView.frame.size.width,
            height: expandedEmojiIdScrollView.frame.size.height
        )
        // container
        let containerView = UIView()
        containerView.isUserInteractionEnabled = true
        containerView.alpha = 0.0
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = Theme.shared.colors.txCellValuePositiveText?.cgColor
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = cornerRadius
        containerView.frame = containerFrame
        // green background
        let greenView = UIView()
        greenView.backgroundColor = Theme.shared.colors.txCellValuePositiveText?.withAlphaComponent(0.12)
        greenView.translatesAutoresizingMaskIntoConstraints = false
        greenView.frame = subviewFrame
        // label
        let copiedLabel = UILabel()
        copiedLabel.text = localized("emoji.copied")
        copiedLabel.font = Theme.shared.fonts.copiedLabel
        copiedLabel.textColor = Theme.shared.colors.textButtonSecondary
        // copiedLabel.translatesAutoresizingMaskIntoConstraints = false
        copiedLabel.frame = subviewFrame
        copiedLabel.textAlignment = .center
        // add subviews
        containerView.addSubview(greenView)
        containerView.addSubview(copiedLabel)
        UIApplication.shared.keyWindow?.addSubview(containerView)
        UIApplication.shared.keyWindow?.bringSubviewToFront(containerView)

        UIView.animate(withDuration: CATransaction.animationDuration(),
                       animations: {
            containerView.alpha = 1.0
        }) {(_) in
            UIView.animate(withDuration: CATransaction.animationDuration(),
                           delay: 0.5,
                           animations: {
                containerView.alpha = 0.0
            }) {
                (_) in
                containerView.removeFromSuperview()
                greenView.removeFromSuperview()
                copiedLabel.removeFromSuperview()
                completion?()
            }
        }
    }

}
