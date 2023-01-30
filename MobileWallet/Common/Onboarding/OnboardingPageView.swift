//  OnboardingPageView.swift

/*
	Package MobileWallet
	Created by Browncoat on 25/01/2023
	Using Swift 5.0
	Running on macOS 13.0

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
import TariCommon

final class OnboardingPageView: DynamicThemeView {

    struct ViewModel {
        let image: UIImage?
        let titleComponents: [StylizedLabel.StylizedText]
        let messageComponents: [StylizedLabel.StylizedText]
        let footerComponents: [StylizedLabel.StylizedText]
        let actionButtonTitle: String?
        let actionButtonCallback: (() -> Void)?
    }

    // MARK: - Constants

    static var footerFont: UIFont = .Avenir.medium.withSize(11.0)
    static var footerPadding: CGFloat = 35.0

    // MARK: - Subviews

    @View private(set) var contentView = UIView()

    @View private var backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = .security.onboarding.background
        return view
    }()

    @View private var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private var titleLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.textAlignment = .center
        view.normalFont = .Avenir.medium.withSize(18.0)
        view.boldFont = .Avenir.black.withSize(18.0)
        view.separator = " "
        view.numberOfLines = 0
        return view
    }()

    @View private var messageLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.textAlignment = .center
        view.normalFont = .Avenir.medium.withSize(14.0)
        view.boldFont = .Avenir.black.withSize(14.0)
        view.separator = " "
        view.numberOfLines = 0
        return view
    }()

    @View private var actionButton: TextButton = {
        let view = TextButton()
        view.setVariation(.secondary)
        return view
    }()

    @View private var separator = UIView()

    @View private var footerNoteLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.textAlignment = .center
        view.normalFont = footerFont
        view.separator = " "
        view.numberOfLines = 0
        return view
    }()

    // MARK: - Properties

    var viewModel: ViewModel? {
        didSet { update(model: viewModel) }
    }

    var contentHeight: CGFloat = 0.0 {
        didSet { heightConstraint?.constant = contentHeight }
    }

    var footerHeight: CGFloat = 0.0 {
        didSet { footerHeightConstraint?.constant = footerHeight }
    }

    var onActionButtonTap: (() -> Void)?

    private var heightConstraint: NSLayoutConstraint?
    private var footerHeightConstraint: NSLayoutConstraint?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [contentView, backgroundImageView, imageView, titleLabel, messageLabel, actionButton, separator, footerNoteLabel].forEach(addSubview)

        let heightConstraint = contentView.heightAnchor.constraint(equalToConstant: contentHeight)
        let footerHeightConstraint = footerNoteLabel.heightAnchor.constraint(equalToConstant: footerHeight)
        self.heightConstraint = heightConstraint
        self.footerHeightConstraint = footerHeightConstraint

        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let constraints = [
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightConstraint,
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 44.0),
            backgroundImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            backgroundImageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: UIScreen.isSmallScreen ? 0.2 : 0.33),
            imageView.topAnchor.constraint(equalTo: backgroundImageView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: backgroundImageView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: backgroundImageView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: backgroundImageView.bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20.0),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 35.0),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -35.0),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20.0),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 35.0),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -35.0),
            actionButton.topAnchor.constraint(greaterThanOrEqualTo: messageLabel.bottomAnchor, constant: 12.0),
            actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 35.0),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -35.0),
            separator.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 20.0),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28.0),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28.0),
            separator.heightAnchor.constraint(equalToConstant: 1.0),
            footerHeightConstraint,
            footerNoteLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 20.0),
            footerNoteLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.footerPadding),
            footerNoteLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.footerPadding),
            footerNoteLabel.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -60.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        actionButton.onTap = { [weak self] in
            self?.onActionButtonTap?()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        backgroundImageView.tintColor = theme.brand.purple
        imageView.tintColor = theme.icons.default
        titleLabel.textColor = theme.text.heading
        messageLabel.textColor = theme.text.body
        separator.backgroundColor = theme.neutral.tertiary
        footerNoteLabel.textColor = theme.text.body
        footerNoteLabel.highlightedTextColor = theme.text.links
    }

    private func update(model: ViewModel?) {
        imageView.image = model?.image
        titleLabel.textComponents = model?.titleComponents ?? []
        messageLabel.textComponents = model?.messageComponents ?? []
        footerNoteLabel.textComponents = model?.footerComponents ?? []
        actionButton.setTitle(model?.actionButtonTitle, for: .normal)
        separator.isHidden = model?.footerComponents.isEmpty == true
    }
}

extension OnboardingPageView.ViewModel {

    static var page1: Self {
        OnboardingPageView.ViewModel(
            image: .security.onboarding.page1,
            titleComponents: [
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page1.title.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page1.title.part2.bold"), style: .bold)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page1.message.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page1.message.part2.bold"), style: .bold),
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page1.message.part3"), style: .normal)
            ],
            footerComponents: footerComponents(threshold: nil),
            actionButtonTitle: localized("onboarding.staged_wallet_security.page1.action_button"),
            actionButtonCallback: { AppRouter.presentVerifiySeedPhrase() }
        )
    }

    static var page2: Self {
        OnboardingPageView.ViewModel(
            image: .security.onboarding.page2,
            titleComponents: [
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page3.title.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page3.title.part2.bold"), style: .bold)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page3.message.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page3.message.part2.bold"), style: .bold),
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page3.message.part3"), style: .normal)
            ],
            footerComponents: footerComponents(threshold: nil),
            actionButtonTitle: localized("onboarding.staged_wallet_security.page3.action_button"),
            actionButtonCallback: { AppRouter.presentBackupSettings() }
        )
    }

    static var page3: Self {
        OnboardingPageView.ViewModel(
            image: .security.onboarding.page3,
            titleComponents: [
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page3.title.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page3.title.part2.bold"), style: .bold)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page3.message.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page3.message.part2.bold"), style: .bold),
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page3.message.part3"), style: .normal)
            ],
            footerComponents: footerComponents(threshold: StagedWalletSecurityManager.stageTwoThresholdBalance.formatted),
            actionButtonTitle: localized("onboarding.staged_wallet_security.page3.action_button"),
            actionButtonCallback: { AppRouter.presentBackupPasswordSettings() }
        )
    }

    static var page4: Self {
        OnboardingPageView.ViewModel(
            image: .security.onboarding.page4,
            titleComponents: [
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page4.title.part1"), style: .normal),
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page4.title.part2.bold"), style: .bold)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.page4.message"), style: .normal)
            ],
            footerComponents: [],
            actionButtonTitle: localized("onboarding.staged_wallet_security.page4.action_button"),
            actionButtonCallback: {}
        )
    }

    static func calculateFooterHeight(forView view: UIView) -> CGFloat {
        [OnboardingPageView.ViewModel.page1, OnboardingPageView.ViewModel.page2, OnboardingPageView.ViewModel.page3, OnboardingPageView.ViewModel.page4]
            .map { $0.footerComponents.map { $0.text }.joined(separator: " ") }
            .map { $0.height(forWidth: view.frame.width - (2.0 * OnboardingPageView.footerPadding), font: OnboardingPageView.footerFont) }
            .map { $0 * 1.2 }
            .max() ?? 0.0
    }

    private static func footerComponents(threshold: String?) -> [StylizedLabel.StylizedText] {

        let part3: String

        if let threshold {
            part3 = localized("onboarding.staged_wallet_security.footer.part3.threshold", arguments: threshold)
        } else {
            part3 = localized("onboarding.staged_wallet_security.footer.part3.any_funds")
        }

        return [
            StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.footer.part1"), style: .normal),
            StylizedLabel.StylizedText(text: localized("onboarding.staged_wallet_security.footer.part2.highlighted"), style: .highlighted),
            StylizedLabel.StylizedText(text: part3, style: .normal)
        ]
    }
}
