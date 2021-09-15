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

    var emojiIdView: EmojiIdView! = EmojiIdView()

    let titleLabel = UILabel()
    let backButton = UIButton()
    var backButtonAction: (() -> Void)?

    let rightButton = UIButton()
    let progressView = UIProgressView()
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
        setupProgressView()
        clipsToBounds = false

        layer.shadowOpacity = 0
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowRadius = 10
        layer.shadowColor = Theme.shared.colors.defaultShadow!.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProgress(_ progress: Float) {
        self.progressView.setProgress(progress, animated: true)
    }

    private func setupTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        centerPositioningConstraint = titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        topPositioningConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16.0)
        topPositioningConstraint?.isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 22.0).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        // Style
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
        // Style
        backButton.backgroundColor = .clear
    }

    private func setupRightButton() {
        rightButton.isHidden = true
        rightButton.titleLabel?.adjustsFontSizeToFitWidth = true

        addSubview(rightButton)

        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        let trailing = rightButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15.0)
        trailing.isActive = true
        trailing.priority = .defaultLow
        rightButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        rightButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 15).isActive = true
        rightButton.addTarget(self, action: #selector(rightButtonAction(_sender:)), for: .touchUpInside)
    }

    private func setupProgressView() {
        progressView.progressTintColor = Theme.shared.colors.navigationBarPurple
        progressView.progress = 0.5
        progressView.isHidden = true

        addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false

        progressView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        progressView.topAnchor.constraint(equalTo: bottomAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 4.0).isActive = true
    }

    func showEmojiId(_ publicKey: PublicKey, inViewController: UIViewController) throws {
        let ( _, emojisError) = publicKey.emojis
        guard emojisError == nil else { throw emojisError! }
        emojiIdView.setupView(pubKey: publicKey,
                              textCentered: true,
                              inViewController: inViewController)

        emojiIdView.tapToExpand = { expanded in
            UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
                self?.backButton.alpha = expanded ? 0.0 : 1.0
            }
        }
        addSubview(emojiIdView)
        emojiIdView.translatesAutoresizingMaskIntoConstraints = false
        emojiIdView.topAnchor.constraint(
            equalTo: safeAreaLayoutGuide.topAnchor,
            constant: 27
        ).isActive = true
        emojiIdView.leadingAnchor.constraint(
            equalTo: leadingAnchor,
            constant: Theme.shared.sizes.appSidePadding
        ).isActive = true
        emojiIdView.trailingAnchor.constraint(
            equalTo: trailingAnchor,
            constant: -Theme.shared.sizes.appSidePadding
        ).isActive = true
    }

    func hideEmoji(animated: Bool = true) {
        UIView.animate(withDuration: animated ? CATransaction.animationDuration() : 0.0, animations: {
            [weak self] in
            self?.emojiIdView.alpha = 0.0
        }) { [weak self] _ in
            self?.emojiIdView.removeFromSuperview()
            self?.emojiIdView = nil
        }
    }

    func showShadow(animated: Bool = true) {
        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            guard let self = self else { return }
            self.layer.shadowOpacity = 0.1
        }
    }

    func hideShadow(animated: Bool = true) {
        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            guard let self = self else { return }
            self.layer.shadowOpacity = 0.0
        }
    }

    @objc public func backAction(_sender: UIButton) {
        if backButtonAction != nil {
            backButtonAction?()
        } else {
            let topController = UIApplication.shared.topController()
            guard let navigationController = topController as? UINavigationController else {
                topController?.dismiss(animated: true)
                return
            }
            if navigationController.viewControllers.first == navigationController.topViewController {
                navigationController.dismiss(animated: true)
            } else {
                navigationController.popViewController(animated: true)
            }
            hideEmoji(animated: false)
        }
    }

    @objc public func rightButtonAction(_sender: UIButton) {
        rightButtonAction?()
    }
}
