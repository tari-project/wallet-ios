//  NavigationBar.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 15.05.2020
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

protocol NavigationBarProtocol: class {
    var title: String? { get set }
}

class NavigationBar: UIView, NavigationBarProtocol {
    enum VerticalPositioning: Equatable {
        case standart
        case center
        case custom(_ value: CGFloat)
    }

    var emoji: EmoticonView?

    let titleLabel = UILabel()
    let backButton = UIButton()
    var backButtonAction: (() -> Void)?

    let rightButton = UIButton()
    var rightButtonAction: (() -> Void)? {
        didSet {
            rightButton.isHidden = false
        }
    }

    var title: String? {
        get {
            titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    var verticalPositioning: VerticalPositioning = .standart {
        didSet {
            switch verticalPositioning {
            case .standart:
                topPositioningConstraint?.constant = 16
                centerPositioningConstraint?.isActive = false
                topPositioningConstraint?.isActive = true
            case .center:
                topPositioningConstraint?.isActive = false
                centerPositioningConstraint?.isActive = true
            case .custom(let value):
                topPositioningConstraint?.constant = value
                centerPositioningConstraint?.isActive = false
                topPositioningConstraint?.isActive = true
            }
            layoutIfNeeded()
        }
    }

    private var topPositioningConstraint: NSLayoutConstraint?
    private var centerPositioningConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = Theme.shared.colors.appBackground
        setupTitle()
        setupBackButton()
        setupRightButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        centerPositioningConstraint = titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        topPositioningConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16.0)
        topPositioningConstraint?.isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 22.0).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        //Style
        titleLabel.font = Theme.shared.fonts.navigationBarTitle
        titleLabel.textColor = Theme.shared.colors.navigationBarTint
        titleLabel.textAlignment = .center
    }

    private func setupBackButton() {
        addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        backButton.addTarget(self, action: #selector(backAction(_sender:)), for: .touchUpInside)

        let imageView = UIImageView(image: Theme.shared.images.backArrow)
        backButton.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: backButton.leadingAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 13).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        imageView.centerYAnchor.constraint(equalTo: backButton.centerYAnchor).isActive = true
        imageView.isUserInteractionEnabled = false
        //Style
        backButton.backgroundColor = .clear
    }

    private func setupRightButton() {
        rightButton.isHidden = true
        addSubview(rightButton)

        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        rightButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15.0).isActive = true
        rightButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        rightButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        rightButton.addTarget(self, action: #selector(rightButtonAction(_sender:)), for: .touchUpInside)
    }

    func showEmoji(_ publicKey: PublicKey, animated: Bool = true) throws {
        let ( _, emojisError) = publicKey.emojis
        guard emojisError == nil else { throw emojisError! }
        if emoji == nil { emoji = EmoticonView() }

        if let emojiView = emoji {
            emojiView.setUpView(pubKey: publicKey,
                                type: .buttonView,
                                textCentered: true)

            emojiView.tapToExpand = { expanded in
                UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
                    self?.backButton.alpha = expanded ? 0.0 : 1.0
                }
            }

            emojiView.alpha = 0.0
            if let window = UIApplication.shared.keyWindow {
                window.addSubview(emojiView)
                emojiView.translatesAutoresizingMaskIntoConstraints = false
                emojiView.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 27).isActive = true
                emojiView.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
                emojiView.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
            }

            UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0, delay: CATransaction.animationDuration(), options: .curveLinear, animations: {
                emojiView.alpha = 1.0
            }, completion: nil)
        }
    }

    func hideEmoji(animated: Bool = true) {
        UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0, animations: { [weak self] in
            self?.emoji?.alpha = 0.0

        }) { [weak self] _ in
            self?.emoji?.removeFromSuperview()
            self?.emoji = nil
        }
    }

    @objc public func backAction(_sender: UIButton) {
        if backButtonAction != nil {
            backButtonAction?()
        } else {
            guard let navigationController = UIApplication.shared.topController() as? UINavigationController else { return }
            navigationController.popViewController(animated: true)
            hideEmoji(animated: false)
        }
    }

    @objc public func rightButtonAction(_sender: UIButton) {
        rightButtonAction?()
    }
}
