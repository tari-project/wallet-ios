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

    var containerView: UIView!
    var label: UILabel!
    var expanded: Bool = false
    var type: EmoticonViewType = .normalView

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

    private var emojiText: String!
    private let RADIUS_POINTS: CGFloat = 12.0

    private var superVc: UIViewController!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setUpView (emojiText: String, type: EmoticonViewType, textCentered: Bool, inViewController vc: UIViewController) {
        self.superVc = vc
        self.emojiText = emojiText
        self.backgroundColor = .clear
        if type == .normalView {
            label = UILabel()
            label.numberOfLines = 0
            self.addSubview(label)

            self.layer.cornerRadius = 6.0
            self.layer.masksToBounds = true
            label.backgroundColor = Theme.shared.colors.creatingWalletEmojisLabelBackground!
            label.textAlignment = .center
            label.textColor = Theme.shared.colors.creatingWalletEmojisSeparator!

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

            let labelContainer = UIView()
            self.addSubview(labelContainer)
            labelContainer.translatesAutoresizingMaskIntoConstraints = false

            if textCentered {
                labelContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                labelContainer.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            } else {
                labelContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
                labelContainer.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            }

            labelInitialWidth = labelContainer.widthAnchor.constraint(equalToConstant: 152)
            labelInitialWidth?.isActive = true
            labelContainer.heightAnchor.constraint(equalToConstant: 32).isActive = true

            labelContainer.layer.shadowColor = Theme.shared.colors.emojiButtonShadow!.cgColor
            labelContainer.layer.shadowOffset = .zero
            labelContainer.layer.shadowRadius = RADIUS_POINTS * 1.2
            labelContainer.layer.shadowOpacity = 0.1
            labelContainer.clipsToBounds = true
            labelContainer.layer.masksToBounds = false

            label = UILabel()
            labelContainer.addSubview(label)

            label.layer.cornerRadius = 12.0
            label.layer.masksToBounds = true
            label.backgroundColor = Theme.shared.colors.creatingWalletEmojisLabelBackground
            label.textAlignment = .center
            label.lineBreakMode = .byTruncatingMiddle
            label.textColor = Theme.shared.colors.creatingWalletEmojisSeparator!
            label.text = emojiText

            label.translatesAutoresizingMaskIntoConstraints = false
            label.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor, constant: 0).isActive = true
            label.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor, constant: 0).isActive = true
            label.topAnchor.constraint(equalTo: labelContainer.topAnchor, constant: 0).isActive = true
            label.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor, constant: 0).isActive = true
            label.heightAnchor.constraint(equalToConstant: 32).isActive = true

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
        }

        self.superVc.navigationController?.navigationBar.layer.zPosition = 0
    }

    @objc func tap(_ gestureRecognizer: UITapGestureRecognizer) {
        if !expanded {
            enableFullScreen()
            expanded = true
        } else {
            disableFullScreen()
            expanded = false
        }
    }

    private func disableFullScreen() {
        self.labelInitialWidth?.constant = 152
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.containerView.alpha = 0.0
            self.superVc.navigationController?.navigationBar.layer.zPosition = 0
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
        }
    }

    private func enableFullScreen() {
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

        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.containerView.alpha = 0.7
            self.superVc.navigationController?.navigationBar.layer.zPosition = -1
            self.layoutIfNeeded()
        })
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
