//  SplashView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 21/07/2022
	Using Swift 5.0
	Running on macOS 12.4

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

import Lottie
import TariCommon
import UIKit

final class SplashView: DynamicThemeView {

    // MARK: - Subviews

//    @View private var animatedLogoView: AnimationView = {
//        let view = AnimationView()
//        view.animation = Animation.named(.splash)
//        view.backgroundBehavior = .pauseAndRestore
//        return view
//    }()
//
//    @View private var videoView: VideoView = {
//        let view = VideoView()
//        view.url = Bundle.main.url(forResource: "purple_orb", withExtension: "mp4")
//        return view
//    }()

    @View private var iconView: UIImageView = {
        let image = UIImage(named: "GemBlackSmall")
        let view = UIImageView(image: image?.withRenderingMode(.alwaysTemplate))
        return view
    }()

    @View private var staticSplashView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    @View private var separatorView: UIView = {
        let view = UIView()
        return view
    }()

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Typography.appTitle
        view.textAlignment = .center
        view.numberOfLines = 1
        view.attributedText = NSMutableAttributedString(string: localized("splash.title"), attributes: [NSAttributedString.Key.kern: -1])
        view.adjustsFontSizeToFitWidth = true
        return view
    }()

    @View private var importWalletLabel: StylisedLabel = {
        let label = StylisedLabel(withStyle: .body2)
        label.text = localized("splash.import_wallet_label")
        return label
    }()

    @View private var importWalletLabelContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .Background.primary.withAlphaComponent(0.8)
        view.layer.cornerRadius = 8
        return view
    }()

    @View private var importWallet = StylisedButton(withStyle: .primary, withSize: .large)
    @View private var createWallet = StylisedButton(withStyle: .outlined, withSize: .large)

    @View private var disclaimerTextView: UnselectableTextView = {
        let view = UnselectableTextView()
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.isEditable = false
        return view
    }()

    @View private var versionLabel: StylisedLabel = {
        let view = StylisedLabel(withStyle: .body2)
        return view
    }()

    // MARK: - Properties

    var importWalletButtonTitle: String? {
        get { importWallet.title(for: .normal) }
        set { importWallet.setTitle(newValue, for: .normal) }
    }

//    var isCreateWalletButtonSpinnerVisible: Bool = false {
//        didSet { importWallet.style = isCreateWalletButtonSpinnerVisible ? .loading : .normal }
//    }

    var createWalletButtonTitle: String? {
        get { createWallet.title(for: .normal) }
        set { createWallet.setTitle(newValue, for: .normal) }
    }

    var versionText: String? {
        get { versionLabel.text }
        set { versionLabel.text = newValue ?? "" }
    }

    var onCreateWalletButtonTap: (() -> Void)?
    var onRestoreWalletButtonTap: (() -> Void)?

    private var idleLogoConstraint: NSLayoutConstraint?
    private var walletCreatedLogoConstraint: NSLayoutConstraint?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupDisclamerView()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    override func update(theme: AppTheme) {
        setupViews()
    }

    private func setupViews() {
        backgroundColor = theme.backgrounds.primary
        separatorView.backgroundColor = theme.text.title?.withAlphaComponent(0.08)
        titleLabel.textColor = theme.text.title
        iconView.tintColor = theme.text.title
        staticSplashView.image = theme.graphics.splashScreenImage
    }

    private func setupConstraints() {
        [iconView, staticSplashView, titleLabel, importWalletLabelContainer, importWallet, createWallet, separatorView, disclaimerTextView, versionLabel].forEach(addSubview)

        importWalletLabelContainer.addSubview(importWalletLabel)

        let constraints = [
            titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 63),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -10),
            staticSplashView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 103),
            staticSplashView.heightAnchor.constraint(equalToConstant: 599),
            staticSplashView.centerXAnchor.constraint(equalTo: centerXAnchor),
            staticSplashView.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),
            staticSplashView.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor),
            staticSplashView.centerXAnchor.constraint(equalTo: centerXAnchor),
            importWalletLabelContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            importWalletLabelContainer.bottomAnchor.constraint(equalTo: importWallet.topAnchor, constant: -10),
            importWalletLabelContainer.leadingAnchor.constraint(equalTo: importWalletLabel.leadingAnchor, constant: -12),
            importWalletLabelContainer.trailingAnchor.constraint(equalTo: importWalletLabel.trailingAnchor, constant: 12),
            importWalletLabelContainer.topAnchor.constraint(equalTo: importWalletLabel.topAnchor, constant: -6),
            importWalletLabelContainer.bottomAnchor.constraint(equalTo: importWalletLabel.bottomAnchor, constant: 6),
            importWalletLabel.centerXAnchor.constraint(equalTo: importWalletLabelContainer.centerXAnchor),
            importWalletLabel.centerYAnchor.constraint(equalTo: importWalletLabelContainer.centerYAnchor),
            importWallet.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 22.0),
            importWallet.widthAnchor.constraint(lessThanOrEqualTo: staticSplashView.widthAnchor),
            importWallet.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -22.0),
            importWallet.centerXAnchor.constraint(equalTo: centerXAnchor),
            createWallet.topAnchor.constraint(equalTo: importWallet.bottomAnchor, constant: 15.0),
            createWallet.widthAnchor.constraint(lessThanOrEqualTo: staticSplashView.widthAnchor),
            createWallet.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 22.0),
            createWallet.centerXAnchor.constraint(equalTo: centerXAnchor),
            createWallet.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -22.0),
            separatorView.topAnchor.constraint(equalTo: createWallet.bottomAnchor, constant: 16),
            separatorView.widthAnchor.constraint(equalTo: createWallet.widthAnchor),
            separatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            versionLabel.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 16.0),
            versionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            disclaimerTextView.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: -3.0),
            disclaimerTextView.centerXAnchor.constraint(equalTo: centerXAnchor),
            disclaimerTextView.widthAnchor.constraint(equalToConstant: 275),
            disclaimerTextView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        importWallet.onTap = { [weak self] in
            self?.onRestoreWalletButtonTap?()
        }

        createWallet.onTap = { [weak self] in
            self?.onCreateWalletButtonTap?()
        }
    }

    private func setupDisclamerView() {
        let textColor: UIColor = .Text.body

        disclaimerTextView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.underlineColor: textColor,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let userAgreementLinkText = localized("splash.disclaimer.param.user_agreement")
        let privacyPolicyLinkText = localized("splash.disclaimer.param.privacy_policy")
        let text = String(format: localized("splash.disclaimer.with_params"), userAgreementLinkText, privacyPolicyLinkText)

        let attributedText = NSMutableAttributedString(string: text)

        if let userAgreementStartIndex = text.indexDistance(of: userAgreementLinkText) {
            let range = NSRange(location: userAgreementStartIndex, length: userAgreementLinkText.count)
            attributedText.addAttribute(.link, value: TariSettings.shared.userAgreementUrl, range: range)
        }

        if let privacyPolicyStartIndex = text.indexDistance(of: privacyPolicyLinkText) {
            let range = NSRange(location: privacyPolicyStartIndex, length: privacyPolicyLinkText.count)
            attributedText.addAttribute(.link, value: TariSettings.shared.privacyPolicyUrl, range: range)
        }

        disclaimerTextView.attributedText = attributedText
        disclaimerTextView.textColor = textColor
        disclaimerTextView.textAlignment = .center
        disclaimerTextView.font = Typography.body2
    }

    // MARK: - Actions

    func updateLayout(showInterface: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        if showInterface {
            walletCreatedLogoConstraint?.isActive = false
            idleLogoConstraint?.isActive = true
//            videoView.startPlayer()
        } else {
            idleLogoConstraint?.isActive = false
            walletCreatedLogoConstraint?.isActive = true
        }

        let alpha = showInterface ? 1.0 : 0.0

        importWallet.isAnimated = showInterface
        createWallet.isAnimated = showInterface

        let transition = {
            self.layoutIfNeeded()
            self.staticSplashView.alpha = alpha
            self.titleLabel.alpha = alpha
            self.importWallet.alpha = alpha
            self.createWallet.alpha = alpha
            self.disclaimerTextView.alpha = alpha
            self.versionLabel.alpha = alpha
        }

        if animated {
            UIView.animate(withDuration: 1.0, animations: transition, completion: { _ in completion?() })
        } else {
            transition()
            completion?()
        }
    }

    func playLogoAnimation(completion: @escaping () -> Void) {
        completion()
//        animatedLogoView.play(completion: { _ in completion() })
    }
}
