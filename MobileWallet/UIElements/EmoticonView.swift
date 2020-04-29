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
    var scrollView = UIScrollView()
    lazy var label: UILabelWithPadding = UILabelWithPadding(copiableViewParent: labelContainer)
    var expanded: Bool = false
    var type: EmoticonViewType = .normalView
    var shouldShowBlurContainerViewWhenExpanded = true
    var enableCopy: Bool = true
    private var initialWidth: CGFloat = CGFloat(172)
    var tapToExpand: (() -> Void)?
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

    private let labelContainer = UIView()

    private var emojiText: String!

    var cornerRadius: CGFloat = 6.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
            scrollView.layer.cornerRadius = cornerRadius
            label.cornerRadius = cornerRadius
        }
    }

    private var superVc: UIViewController!

    func setUpView(emojiText: String,
                   type: EmoticonViewType,
                   textCentered: Bool,
                   inViewController vc: UIViewController,
                   initialWidth: CGFloat = CGFloat(172),
                   initialHeight: CGFloat = CGFloat(32),
                   showContainerViewBlur: Bool = true,
                   cornerRadius: CGFloat = 6.0) {
        self.label.longPressGesture.isEnabled = false
        self.superVc = vc
        self.emojiText = emojiText
        self.backgroundColor = .clear
        if type == .normalView {
            label.numberOfLines = 0
            self.addSubview(label)
            self.layer.masksToBounds = true
            label.backgroundColor = Theme.shared.colors.creatingWalletEmojisLabelBackground!
            label.textAlignment = .center
            label.textColor = Theme.shared.colors.emojisSeparator!

            label.text = String(emojiText.enumerated().map { $0 > 0 && $0 % 4 == 0 ? ["|", $1] : [$1]}.joined())

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
            self.addSubview(containerView)
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerViewLeadingInitial = containerView.widthAnchor.constraint(equalToConstant: 0)
            containerViewLeadingInitial?.isActive = true
            containerViewTrailingInitial = containerView.heightAnchor.constraint(equalToConstant: 0)
            containerViewTrailingInitial?.isActive = true

            containerViewTopInitial = containerView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0)
            containerViewTopInitial?.isActive = true
            containerViewBottomInitial = containerView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0)
            containerViewBottomInitial?.isActive = true

            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap(_:))))

            shouldShowBlurContainerViewWhenExpanded = showContainerViewBlur

            self.addSubview(labelContainer)
            labelContainer.translatesAutoresizingMaskIntoConstraints = false

            if textCentered {
                labelContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                labelContainer.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            } else {
                labelContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
                labelContainer.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
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
            scrollView.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor,
                                                constant: 0).isActive = true
            scrollView.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor,
                                                 constant: 0).isActive = true
            scrollView.topAnchor.constraint(equalTo: labelContainer.topAnchor,
                                            constant: 0).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor,
                                               constant: 0).isActive = true

            scrollView.layer.masksToBounds = true

            label.padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            scrollView.addSubview(label)

            label.layer.masksToBounds = true
            label.backgroundColor = Theme.shared.colors.creatingWalletEmojisLabelBackground
            label.textAlignment = .center
            label.textColor = Theme.shared.colors.emojisSeparator!
            determineEmojiLabelText(emojiText: emojiText)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 0).isActive = true
            label.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 0).isActive = true
            label.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0).isActive = true
            label.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0).isActive = true
            label.heightAnchor.constraint(equalToConstant: initialHeight).isActive = true

            if textCentered {
                let leftView = UIView()
                let rightView = UIView()

                self.addSubview(leftView)
                leftView.translatesAutoresizingMaskIntoConstraints = false
                leftView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
                leftView.trailingAnchor.constraint(equalTo: labelContainer.leadingAnchor, constant: 0).isActive = true
                leftView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
                leftView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
                self.addSubview(rightView)
                rightView.translatesAutoresizingMaskIntoConstraints = false
                rightView.leadingAnchor.constraint(equalTo: labelContainer.trailingAnchor, constant: 0).isActive = true
                rightView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
                rightView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
                rightView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
                leftView.widthAnchor.constraint(equalTo: rightView.widthAnchor, multiplier: 1).isActive = true
            }
            self.cornerRadius = cornerRadius
        }

        self.superVc.navigationController?.navigationBar.layer.zPosition = 0
    }

    @objc func tap(_ gestureRecognizer: UITapGestureRecognizer) {
        expand(!expanded, callTapCompletion: true)
    }

    func expand(_ expand: Bool, completion: (() -> Void)? = nil, callTapCompletion: Bool = false, animated: Bool = true) {
        expanded = expand
        if enableCopy == true {
            label.longPressGesture.isEnabled = expand
            label.hideMenu()
        }
        if expand == true {
            enableFullScreen(callTapCompletion: callTapCompletion, completion: completion, animated: animated)
        } else {
            disableFullScreen(completion: completion, animated: animated)
        }
    }

    private func disableFullScreen(completion: (() -> Void)? = nil, animated: Bool = true) {
        self.labelInitialWidth?.constant = initialWidth
        determineEmojiLabelText(emojiText: emojiText)
        UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0, animations: { [weak self] in
            guard let self = self else { return }
            if self.shouldShowBlurContainerViewWhenExpanded {
                self.containerView.alpha = 0.0
                self.superVc.navigationController?.navigationBar.layer.zPosition = 0
            }
            self.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.backgroundLeft?.isActive = false
            self.backgroundRight?.isActive = false
            self.backgroundTop?.isActive = false
            self.backgroundBottom?.isActive = false

            self.containerViewLeadingInitial?.isActive = true
            self.containerViewTrailingInitial?.isActive = true
            self.containerViewBottomInitial?.isActive = true
            self.containerViewTopInitial?.isActive = true

            completion?()
        }
    }

    private func enableFullScreen(callTapCompletion: Bool, completion:(() -> Void)? = nil, animated: Bool = true) {

        UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0, animations: { [weak self] in
            guard let self = self else { return }
            self.label.alpha = 0.0
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.determineEmojiLabelText(emojiText: self.emojiText)
            self.runFullScreenAnimation(callTapCompletion: callTapCompletion)
            UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0, animations: { [weak self] in
                guard let self = self else { return }
                self.label.alpha = 1.0
            }) {(_) in
                completion?()
            }
        }
    }

    private func runFullScreenAnimation(callTapCompletion: Bool) {
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

            self.layoutIfNeeded()

            self.labelInitialWidth?.constant = self.frame.width

            //If they're typing somewhere, close the keyboard
            superVc.view.endEditing(true)

            if shouldShowBlurContainerViewWhenExpanded {
                UIView.animate(withDuration: 0.5, animations: { [weak self] in
                    guard let self = self else { return }
                    self.containerView.alpha = 0.7
                    self.superVc.navigationController?.navigationBar.layer.zPosition = -1
                    self.layoutIfNeeded()
                })
            }

        if callTapCompletion == true {
            tapToExpand?()
        }

            scrollView.contentOffset = CGPoint(x: 30, y: 0)

            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                guard let self = self else { return }
                self.scrollView.contentOffset = CGPoint(x: -30, y: 0)
                self.layoutIfNeeded()
            }) { [weak self] (_) in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.3, animations: { [weak self] in
                    guard let self = self else { return }
                    self.scrollView.contentOffset = CGPoint(x: 30, y: 0)
                    self.layoutIfNeeded()
                }) { [weak self] (_) in
                    guard let self = self else { return }
                    UIView.animate(withDuration: 0.3, animations: { [weak self] in
                        guard let self = self else { return }
                        self.scrollView.contentOffset = CGPoint(x: -10, y: 0)
                        self.layoutIfNeeded()
                    }) { [weak self] (_) in
                        guard let self = self else { return }
                        self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
                    }
                }
            }
    }

    private func determineEmojiLabelText(emojiText: String) {
        let firstThreeChar = emojiText.prefix(3)
        let lastThreeChar = emojiText.suffix(3)

        let expandedString = self.emojiText.insertSeparator(" | ", atEvery: 3)
        label.textColor = expanded ? Theme.shared.colors.emojisSeparatorExpanded! : Theme.shared.colors.emojisSeparator!
        label.text = expanded ? expandedString : "\(firstThreeChar)...\(lastThreeChar)"
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            self.superVc.navigationController?.navigationBar.layer.zPosition = 0
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
