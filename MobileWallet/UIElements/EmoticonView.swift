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

enum EmoticonViewType {
    case normalView
    case buttonView
}

class EmoticonView: UIView {

    var containerView = UIView()
    weak var blackoutParent: UIView?
    private lazy var blackoutView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        guard let bounds =  UIApplication.shared.keyWindow?.bounds else { return view }
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (onTap(_:))))
        view.frame = bounds
        view.alpha = 0.0
        return view
    }()
    var scrollView = UIScrollView()
    lazy var label = UILabelWithPadding(copiableViewParent: labelContainer)
    var expanded: Bool = false
    var type: EmoticonViewType = .normalView
    var blackoutWhileExpanded = true
    private var initialWidth: CGFloat = CGFloat(172)
    var tapToExpand: ((_ expanded: Bool) -> Void)?
    private var backgroundTop: NSLayoutConstraint?
    private var backgroundLeft: NSLayoutConstraint?
    private var backgroundRight: NSLayoutConstraint?
    private var backgroundBottom: NSLayoutConstraint?

    private var containerViewLeadingInitial: NSLayoutConstraint?
    private var containerViewTrailingInitial: NSLayoutConstraint?
    private var containerViewTopInitial: NSLayoutConstraint?
    private var containerViewBottomInitial: NSLayoutConstraint?

    private var labelInitialWidth: NSLayoutConstraint?
    private var labelWidthConstraint: NSLayoutConstraint?
    private var labelCenterConstraint: NSLayoutConstraint?

    private let emojiMenu = EmojiMenuView()

    private let labelContainer = UIView()

    private var emojiText: String!
    private var pubKeyHex: String!

    var cornerRadius: CGFloat = 6.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
            scrollView.layer.cornerRadius = cornerRadius
            label.cornerRadius = cornerRadius
        }
    }

    private var superVc: UIViewController?

    func setUpView(pubKey: PublicKey,
                   type: EmoticonViewType,
                   textCentered: Bool,
                   inViewController vc: UIViewController? = nil,
                   initialWidth: CGFloat = CGFloat(172),
                   initialHeight: CGFloat = CGFloat(38),
                   showContainerViewBlur: Bool = true,
                   cornerRadius: CGFloat = 6.0) {
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.letterSpacing(value: 3.0)
        superVc = vc

        emojiText = pubKey.emojis.0
        pubKeyHex = pubKey.hex.0
        self.backgroundColor = .clear

        label.copyText = emojiText

        if type == .normalView {
            label.numberOfLines = 0
            addSubview(label)
            layer.masksToBounds = true
            label.backgroundColor = Theme.shared.colors.creatingWalletEmojisLabelBackground!
            label.textAlignment = .center
            label.textColor = Theme.shared.colors.emojisSeparator!
            label.text = emojiText.insertSeparator("|", atEvery: 3)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
            label.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        }

        if type == .buttonView {
            containerView = UIView()
            containerView.backgroundColor = Theme.shared.colors.emoticonBlackBackgroundAlpha!
            containerView.alpha = 0.0
            addSubview(containerView)
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerViewLeadingInitial = containerView.widthAnchor.constraint(equalToConstant: 0)
            containerViewLeadingInitial?.isActive = true
            containerViewTrailingInitial = containerView.heightAnchor.constraint(equalToConstant: 0)
            containerViewTrailingInitial?.isActive = true

            containerViewTopInitial = containerView.centerXAnchor.constraint(equalTo: centerXAnchor)
            containerViewTopInitial?.isActive = true
            containerViewBottomInitial = containerView.centerYAnchor.constraint(equalTo: centerYAnchor)
            containerViewBottomInitial?.isActive = true

            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap(_:))))

            blackoutWhileExpanded = showContainerViewBlur

            self.addSubview(labelContainer)
            labelContainer.translatesAutoresizingMaskIntoConstraints = false

            labelContainer.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

            if textCentered {
                labelContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            } else {
                labelContainer.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            }

            self.initialWidth = initialWidth
            labelInitialWidth = labelContainer.widthAnchor.constraint(equalToConstant: initialWidth)
            labelInitialWidth?.isActive = true
            labelContainer.heightAnchor.constraint(equalToConstant: initialHeight).isActive = true

            labelContainer.layer.shadowColor = Theme.shared.colors.emojiButtonShadow!.cgColor
            labelContainer.layer.shadowOffset = .zero
            labelContainer.layer.shadowRadius = cornerRadius * 1.2
            labelContainer.layer.shadowOpacity = 1.0
            labelContainer.clipsToBounds = true
            labelContainer.layer.masksToBounds = false

            scrollView = UIScrollView()
            scrollView.showsHorizontalScrollIndicator = false
            labelContainer.addSubview(scrollView)
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.centerXAnchor.constraint(equalTo: labelContainer.centerXAnchor).isActive = true
            scrollView.widthAnchor.constraint(equalTo: labelContainer.widthAnchor).isActive = true
            scrollView.topAnchor.constraint(equalTo: labelContainer.topAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor).isActive = true

            scrollView.layer.masksToBounds = true

            label.padding = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
            scrollView.addSubview(label)

            label.layer.masksToBounds = true
            label.backgroundColor = Theme.shared.colors.creatingWalletEmojisLabelBackground
            label.textAlignment = .center
            label.textColor = Theme.shared.colors.emojisSeparator!
            determineEmojiLabelText(emojiText: emojiText)
            label.translatesAutoresizingMaskIntoConstraints = false

            label.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
            label.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
            label.heightAnchor.constraint(equalToConstant: initialHeight).isActive = true

            labelCenterConstraint = label.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
            labelCenterConstraint?.isActive = true

            self.cornerRadius = cornerRadius
        }

        superVc?.navigationController?.navigationBar.layer.zPosition = 0
    }

    @objc func tap(_ gestureRecognizer: UITapGestureRecognizer) {
        if expanded {
            shrink(callTapCompletion: true)
        } else {
            expand(callTapCompletion: true)
        }
    }

    func expand(completion: (() -> Void)? = nil, callTapCompletion: Bool = false, animated: Bool = true) {
        expanded = true
        enableFullScreen(callTapCompletion: callTapCompletion, completion: completion, animated: animated)
        if blackoutWhileExpanded {
            showBlackoutView()
        }
    }

    func shrink(completion: (() -> Void)? = nil, callTapCompletion: Bool = false, animated: Bool = true) {
        expanded = false
        if blackoutWhileExpanded {
            hideBlackoutView()
        }
        disableFullScreen(callTapCompletion: callTapCompletion, completion: completion, animated: animated)
    }

    private func disableFullScreen(callTapCompletion: Bool, completion: (() -> Void)? = nil, animated: Bool = true) {
        UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0, animations: { [weak self] in
            guard let initialWidth = self?.initialWidth else { return }
            self?.containerView.alpha = 0.0
            self?.labelInitialWidth?.constant = initialWidth
            self?.layoutIfNeeded()
            }, completion: { [weak self] _ in

                self?.backgroundLeft?.isActive = false
                self?.backgroundRight?.isActive = false
                self?.backgroundTop?.isActive = false
                self?.backgroundBottom?.isActive = false

                self?.containerViewLeadingInitial?.isActive = true
                self?.containerViewTrailingInitial?.isActive = true
                self?.containerViewBottomInitial?.isActive = true
                self?.containerViewTopInitial?.isActive = true

                self?.labelCenterConstraint?.isActive = true

                guard let emojiText = self?.emojiText else { return }
                self?.determineEmojiLabelText(emojiText: emojiText)

                completion?()

                if callTapCompletion == true {
                    self?.tapToExpand?(false)
                }
        })
    }

    private func enableFullScreen(callTapCompletion: Bool, completion:(() -> Void)? = nil, animated: Bool = true) {
        determineEmojiLabelText(emojiText: emojiText)
        runFullScreen(callTapCompletion: callTapCompletion, animated: animated)
    }

    private func runFullScreen(callTapCompletion: Bool, animated: Bool = true) {
        if backgroundLeft == nil && backgroundRight == nil && backgroundBottom == nil && backgroundTop == nil {
            if let superview = self.superview {
                backgroundLeft = containerView.leadingAnchor.constraint(equalTo: superview.leadingAnchor)
                backgroundRight = containerView.trailingAnchor.constraint(equalTo: superview.trailingAnchor)
                backgroundTop = containerView.topAnchor.constraint(equalTo: superview.topAnchor)
                backgroundBottom = containerView.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            }
        }

        containerViewLeadingInitial?.isActive = false
        containerViewTrailingInitial?.isActive = false
        containerViewBottomInitial?.isActive = false
        containerViewTopInitial?.isActive = false

        backgroundLeft?.isActive = true
        backgroundRight?.isActive = true
        backgroundTop?.isActive = true
        backgroundBottom?.isActive = true

        labelCenterConstraint?.isActive = false

        self.layoutIfNeeded()

        self.labelInitialWidth?.constant = self.frame.width

        //If they're typing somewhere, close the keyboard
        superVc?.view.endEditing(true)

        if callTapCompletion == true {
            tapToExpand?(true)
        }

        scrollView.contentOffset = CGPoint(x: 30, y: 0)

        UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0, animations: { [weak self] in
            self?.scrollView.contentOffset = CGPoint(x: -30, y: 0)
            self?.layoutIfNeeded()
        }) { [weak self] (_) in
            UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0, animations: { [weak self] in
                self?.scrollView.contentOffset = CGPoint(x: 30, y: 0)
                self?.layoutIfNeeded()
            }) { [weak self] (_) in
                UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0, animations: { [weak self] in
                    self?.scrollView.contentOffset = CGPoint(x: -10, y: 0)
                    self?.layoutIfNeeded()
                }) { [weak self] (_) in
                    self?.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                }
            }
        }
    }

    private func determineEmojiLabelText(emojiText: String) {
        let firstThreeChar = emojiText.prefix(3)
        let lastThreeChar = emojiText.suffix(3)

        let expandedString = emojiText.insertSeparator(" | ", atEvery: 3)
        label.textColor = expanded ? Theme.shared.colors.emojisSeparatorExpanded! : Theme.shared.colors.emojisSeparator!
        label.text = expanded ? expandedString : "\(firstThreeChar)•••\(lastThreeChar)"
        label.copyText = emojiText
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            superVc?.navigationController?.navigationBar.layer.zPosition = 0
            hideMenu()
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
}

// MARK: blackout behavior

extension EmoticonView {
    private func showBlackoutView() {
        if let parent = blackoutParent {
            guard let sv = superview else { return }
            parent.insertSubview(blackoutView, belowSubview: parent == sv ? self : sv)
        } else {
            insertSubview(blackoutView, belowSubview: containerView)
            guard let gf = globalFrame else { return }
            blackoutView.frame = CGRect(x: -gf.origin.x, y: -gf.origin.y, width: blackoutView.bounds.width, height: blackoutView.bounds.height)
        }

        fadeView(view: blackoutView, fade: false, maxAlpha: 0.62)
        showMenu()
    }

    private func hideBlackoutView() {
        fadeView(view: blackoutView, fade: true) { [weak self] in
            self?.blackoutView.removeFromSuperview()
        }
        hideMenu()
    }

    private func showMenu() {
        emojiMenu.alpha = 0.0
        emojiMenu.title = NSLocalizedString("emoji.copy", comment: "Emoji view")

        emojiMenu.completion = { [weak self] isLongPress in
            guard let self = self else { return }
            if isLongPress {
                self.label.copyText = self.pubKeyHex
            } else {
                self.label.copyText = self.emojiText
            }
            self.label.copy(nil)
            self.hideMenu()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                self?.shrink(callTapCompletion: true)
            })
        }

        UIApplication.shared.keyWindow?.addSubview(emojiMenu)
        guard let globalFrame = labelContainer.globalFrame else { return }
        let emojiMenuSize = CGSize(width: 119, height: 37)
        let xPosition = (bounds.width / 2) - (emojiMenuSize.width / 2) + 25
        emojiMenu.alpha = 0.0
        emojiMenu.frame = CGRect(x: xPosition, y: globalFrame.origin.y + globalFrame.height, width: emojiMenuSize.width, height: emojiMenuSize.height)

        UIView.animate(withDuration: 0.5, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .curveEaseInOut, animations: { [weak self] in
            self?.emojiMenu.alpha = 1.0
            self?.emojiMenu.frame = CGRect(x: xPosition, y: globalFrame.origin.y + 45, width: emojiMenuSize.width, height: emojiMenuSize.height)
        })

        fadeView(view: emojiMenu, fade: false)
    }
    private func hideMenu() {
        fadeView(view: emojiMenu, fade: true) { [weak self] in
            self?.emojiMenu.removeFromSuperview()
        }
    }

    @objc private func onTap(_ sender: Any?) {
        shrink(callTapCompletion: true)
    }

    private func fadeView(view: UIView, fade: Bool, maxAlpha: CGFloat = 1.0, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: CATransaction.animationDuration(), animations: {
            view.alpha = fade ? 0.0 : maxAlpha
        }) { _ in
            completion?()
        }
    }
}

private class EmojiMenuView: UIView {

    private let button = TextButton()
    var completion: ((Bool) -> Void)?

    var title: String? {
        didSet {
            button.setTitle(NSLocalizedString(title ?? "", comment: ""), for: .normal)
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
        button.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        button.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        button.heightAnchor.constraint(equalTo: heightAnchor, constant: -5).isActive = true

        button.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
        button.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPress)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
