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

final class SplashView: UIView {
    
    // MARK: - Subviews
    
    @View private var animatedLogoView: AnimationView = {
        let view = AnimationView()
        view.animation = Animation.named(.splash)
        view.backgroundBehavior = .pauseAndRestore
        return view
    }()
    
    @View private var videoView: VideoView = {
        let view = VideoView()
        view.url = Bundle.main.url(forResource: "purple_orb", withExtension: "mp4")
        return view
    }()
    
    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("splash.title")
        view.font = .Avenir.black.withSize(30.0)
        view.interlineSpacing(spacingValue: 0)
        view.textColor = .static.white
        view.textAlignment = .center
        view.numberOfLines = 2
        view.adjustsFontSizeToFitWidth = true
        return view
    }()
    
    @View private var createWalletButton: ActionButton = ActionButton()
    @View private var selectNetworkButton = ActionButton()
    
    @View private var restoreWalletButton: TextButton = {
        let view = TextButton()
        view.setTitle(localized("splash.restore_wallet"), for: .normal)
        return view
    }()
    
    @View private var disclaimerTextView: UnselectableTextView = {
        let view = UnselectableTextView()
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.isEditable = false
        return view
    }()
    
    @View private var tariIconView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.currencySymbol
        view.tintColor = .static.white
        return view
    }()
    
    @View private var versionLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.heavy.withSize(9.0)
        view.textColor = .static.mediumGrey
        view.textAlignment = .center
        return view
    }()
    
    // MARK: - Properties
    
    var createWalletButtonTitle: String? {
        get { createWalletButton.title(for: .normal) }
        set { createWalletButton.setTitle(newValue, for: .normal) }
    }
    
    var isCreateWalletButtonSpinnerVisible: Bool = false {
        didSet { createWalletButton.variation = isCreateWalletButtonSpinnerVisible ? .loading : .normal }
    }
    
    var selectNetworkButtonTitle: String? {
        get { selectNetworkButton.title(for: .normal) }
        set { selectNetworkButton.setTitle(newValue, for: .normal) }
    }
    
    var versionText: String? {
        get { versionLabel.text }
        set { versionLabel.text = newValue }
    }
    
    var onCreateWalletButtonTap: (() -> Void)?
    var onSelectNetworkButtonTap: (() -> Void)?
    var onRestoreWalletButtonTap: (() -> Void)?
    
    private var idleLogoConstraint: NSLayoutConstraint?
    private var walletCreatedLogoConstraint: NSLayoutConstraint?
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupViews()
        setupDisclamerView()
        setupConstraints()
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        backgroundColor = .static.black
    }
    
    private func setupConstraints() {
        
        [videoView, titleLabel, createWalletButton, selectNetworkButton, restoreWalletButton, disclaimerTextView, tariIconView, versionLabel, animatedLogoView].forEach(addSubview)
        
        let idleLogoConstraint = animatedLogoView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 19.0)
        self.idleLogoConstraint = idleLogoConstraint
        walletCreatedLogoConstraint = animatedLogoView.centerYAnchor.constraint(equalTo: centerYAnchor)
        
        let constraints = [
            idleLogoConstraint,
            animatedLogoView.widthAnchor.constraint(equalToConstant: 145.0),
            animatedLogoView.heightAnchor.constraint(equalToConstant: 30.0),
            animatedLogoView.centerXAnchor.constraint(equalTo: centerXAnchor),
            videoView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 49.0),
            videoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: videoView.bottomAnchor, constant: 15.0),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            createWalletButton.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 5.0),
            createWalletButton.topAnchor.constraint(lessThanOrEqualTo: titleLabel.bottomAnchor, constant: 25.0),
            createWalletButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            createWalletButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            selectNetworkButton.topAnchor.constraint(equalTo: createWalletButton.bottomAnchor, constant: 12.0),
            selectNetworkButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            selectNetworkButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            selectNetworkButton.heightAnchor.constraint(equalToConstant: 32.0),
            restoreWalletButton.topAnchor.constraint(greaterThanOrEqualTo: selectNetworkButton.bottomAnchor, constant: 5.0),
            restoreWalletButton.topAnchor.constraint(lessThanOrEqualTo: selectNetworkButton.bottomAnchor, constant: 22.0),
            restoreWalletButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            restoreWalletButton.heightAnchor.constraint(equalToConstant: 25.0),
            disclaimerTextView.topAnchor.constraint(greaterThanOrEqualTo: restoreWalletButton.bottomAnchor, constant: 0.0),
            disclaimerTextView.topAnchor.constraint(lessThanOrEqualTo: restoreWalletButton.bottomAnchor, constant: 5.0),
            disclaimerTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            disclaimerTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            tariIconView.topAnchor.constraint(greaterThanOrEqualTo: disclaimerTextView.bottomAnchor, constant: 0.0),
            tariIconView.topAnchor.constraint(lessThanOrEqualTo: disclaimerTextView.bottomAnchor, constant: 12.0),
            tariIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            tariIconView.widthAnchor.constraint(equalToConstant: 24.0),
            tariIconView.heightAnchor.constraint(equalToConstant: 24.0),
            versionLabel.topAnchor.constraint(equalTo: tariIconView.bottomAnchor, constant: 9.0),
            versionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            versionLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        
        createWalletButton.onTap = { [weak self] in
            self?.onCreateWalletButtonTap?()
        }
        
        selectNetworkButton.onTap = { [weak self] in
            self?.onSelectNetworkButtonTap?()
        }
        
        restoreWalletButton.onTap = { [weak self] in
            self?.onRestoreWalletButtonTap?()
        }
    }
    
    private func setupDisclamerView() {
        
        guard let textColor = UIColor.static.mediumGrey else { return }
        
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
        disclaimerTextView.font = .Avenir.medium.withSize(12.0)
    }
    
    // MARK: - Actions
    
    func updateLayout(showInterface: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        
        if showInterface {
            walletCreatedLogoConstraint?.isActive = false
            idleLogoConstraint?.isActive = true
            videoView.startPlayer()
        } else {
            idleLogoConstraint?.isActive = false
            walletCreatedLogoConstraint?.isActive = true
        }
        
        let alpha = showInterface ? 3.0 : 0.0
        
        let transition = {
            self.layoutIfNeeded()
            self.videoView.alpha = alpha
            self.titleLabel.alpha = alpha
            self.createWalletButton.alpha = alpha
            self.selectNetworkButton.alpha = alpha
            self.restoreWalletButton.alpha = alpha
            self.disclaimerTextView.alpha = alpha
            self.tariIconView.alpha = alpha
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
        animatedLogoView.play(completion: { _ in completion() })
    }
}
