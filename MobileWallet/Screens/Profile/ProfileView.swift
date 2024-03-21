//  ProfileView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 12/01/2022
	Using Swift 5.0
	Running on macOS 12.1

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

import TariCommon
import Lottie

final class ProfileView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var usernameLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.heavy.withSize(16.0)
        view.textAlignment = .center
        return view
    }()

    @View private var emojiIdView = EmojiIdView()
    @View var yatButton: BaseButton = BaseButton()

    @View private var yatSpinnerView: AnimationView = {
        let view = AnimationView()
        view.animation = Animation.named(.pendingCircleAnimation)
        view.backgroundBehavior = .pauseAndRestore
        view.loopMode = .loop
        return view
    }()

    @View private var yatOutOfSyncLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.normalFont = .Avenir.medium.withSize(13.0)
        view.boldFont = .Avenir.heavy.withSize(13.0)
        view.separator = " "
        view.textAlignment = .center
        view.numberOfLines = 0
        view.alpha = 0.0
        view.textComponents = [
            StylizedLabel.StylizedText(text: localized("profile_view.label.out_of_sync.part.1"), style: .normal),
            StylizedLabel.StylizedText(text: localized("profile_view.label.out_of_sync.part.2.bold"), style: .bold),
            StylizedLabel.StylizedText(text: localized("profile_view.label.out_of_sync.part.3"), style: .normal)
        ]
        return view
    }()

    @View private var auroraButtonsStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 40.0
        return view
    }()

    @View private var walletButton: RoundedLabeledButton = {
        let view = RoundedLabeledButton()
        view.buttonSize = 46.0
        view.padding = 12.0
        view.update(image: .Icons.wallet, text: localized("profile_view.button.wallet"))
        return view
    }()

    @View private var connectYatButton: RoundedLabeledButton = {
        let view = RoundedLabeledButton()
        view.buttonSize = 46.0
        view.padding = 12.0
        view.update(image: .Icons.Yat.logo, text: localized("profile_view.button.connect_yat"))
        return view
    }()

    @View private var shareSectionSeparator = UIView()

    @View private var shareSectionTitleLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.heavy.withSize(16.0)
        view.textAlignment = .center
        view.text = localized("profile_view.label.title.share")
        return view
    }()

    @View private var shareSectionDescriptionLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.profileMiddleLabel
        view.textAlignment = .center
        view.numberOfLines = 2
        view.adjustsFontSizeToFitWidth = true
        view.text = localized("profile_view.error.qr_code.description.with_param", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol)
        return view
    }()

    @View private var shareButtonsStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 40.0
        return view
    }()

    @View private var qrCodeButton: RoundedLabeledButton = {
        let view = RoundedLabeledButton()
        view.buttonSize = 46.0
        view.padding = 12.0
        view.update(image: .Icons.QR, text: localized("contact_book.share_bar.buttons.qr"))
        return view
    }()

    @View private var linkCodeButton: RoundedLabeledButton = {
        let view = RoundedLabeledButton()
        view.update(image: .Icons.link, text: localized("contact_book.share_bar.buttons.link"))
        view.buttonSize = 46.0
        view.padding = 12.0
        return view
    }()

    @View private var bleCodeButton: RoundedLabeledButton = {
        let view = RoundedLabeledButton()
        view.update(image: .Icons.bluetooth, text: localized("contact_book.share_bar.buttons.ble"))
        view.buttonSize = 46.0
        view.padding = 12.0
        return view
    }()

    // MARK: - Properties

    var backButtonType: NavigationBar.BackButtonType {
        get { navigationBar.backButtonType }
        set { navigationBar.backButtonType = newValue }
    }

    var isYatButtonOn: Bool = false {
        didSet { updateYatButton(isOn: isYatButtonOn) }
    }

    var isOutOfSyncLabelVisible = false {
        didSet {
            guard isOutOfSyncLabelVisible != oldValue else { return }
            updateOutOfSyncStatus()
        }
    }

    var onEditButtonTap: (() -> Void)?
    var onWalletButtonTap: (() -> Void)?
    var onConnectYatButtonTap: (() -> Void)?
    var onQrCodeButtonTap: (() -> Void)?
    var onLinkButtonTap: (() -> Void)?
    var onBleButtonTap: (() -> Void)?

    private var yatButtonOnTintColor: UIColor?
    private var yatButtonOffTintColor: UIColor?

    private var auroraButtonsTopConstraintOnYatLabelHidden: NSLayoutConstraint?
    private var auroraButtonsTopConstraintOnYatLabelShown: NSLayoutConstraint?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {

        navigationBar.title = localized("profile_view.title")
        navigationBar.update(rightButton: NavigationBar.ButtonModel(title: localized("common.edit"), callback: { [weak self] in
            self?.onEditButtonTap?()
        }))

        yatButton.imageView?.contentMode = .scaleAspectFit
    }

    private func setupConstraints() {

        [usernameLabel, emojiIdView, yatButton, yatSpinnerView, yatOutOfSyncLabel, shareSectionSeparator, shareSectionTitleLabel, shareSectionDescriptionLabel, auroraButtonsStackView, shareButtonsStackView].forEach(addSubview)
        [walletButton, connectYatButton].forEach(auroraButtonsStackView.addArrangedSubview)
        [qrCodeButton, linkCodeButton, bleCodeButton].forEach(shareButtonsStackView.addArrangedSubview)

        let auroraButtonsTopConstraintOnYatLabelHidden = auroraButtonsStackView.topAnchor.constraint(equalTo: emojiIdView.bottomAnchor, constant: 20.0)
        self.auroraButtonsTopConstraintOnYatLabelHidden = auroraButtonsTopConstraintOnYatLabelHidden
        auroraButtonsTopConstraintOnYatLabelShown = auroraButtonsStackView.topAnchor.constraint(equalTo: yatOutOfSyncLabel.bottomAnchor, constant: 20.0)

        let constraints = [
            usernameLabel.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 50.0),
            usernameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            usernameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            emojiIdView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 20.0),
            emojiIdView.widthAnchor.constraint(equalToConstant: 185.0),
            emojiIdView.heightAnchor.constraint(equalToConstant: 38.0),
            emojiIdView.centerXAnchor.constraint(equalTo: centerXAnchor),
            yatButton.leadingAnchor.constraint(equalTo: emojiIdView.trailingAnchor, constant: 4.0),
            yatButton.centerYAnchor.constraint(equalTo: emojiIdView.centerYAnchor),
            yatButton.heightAnchor.constraint(equalToConstant: 32.0),
            yatButton.widthAnchor.constraint(equalToConstant: 32.0),
            yatSpinnerView.centerXAnchor.constraint(equalTo: yatButton.centerXAnchor),
            yatSpinnerView.centerYAnchor.constraint(equalTo: yatButton.centerYAnchor),
            yatSpinnerView.heightAnchor.constraint(equalToConstant: 28.0),
            yatSpinnerView.widthAnchor.constraint(equalToConstant: 28.0),
            yatOutOfSyncLabel.topAnchor.constraint(equalTo: emojiIdView.bottomAnchor, constant: 20.0),
            yatOutOfSyncLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            yatOutOfSyncLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            auroraButtonsTopConstraintOnYatLabelHidden,
            auroraButtonsStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            shareSectionSeparator.topAnchor.constraint(equalTo: auroraButtonsStackView.bottomAnchor, constant: 20.0),
            shareSectionSeparator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            shareSectionSeparator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            shareSectionSeparator.heightAnchor.constraint(equalToConstant: 1.0),
            shareSectionTitleLabel.topAnchor.constraint(equalTo: shareSectionSeparator.bottomAnchor, constant: 20.0),
            shareSectionTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            shareSectionTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            shareSectionDescriptionLabel.topAnchor.constraint(equalTo: shareSectionTitleLabel.bottomAnchor, constant: 20.0),
            shareSectionDescriptionLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 25.0),
            shareSectionDescriptionLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -25.0),
            shareButtonsStackView.topAnchor.constraint(equalTo: shareSectionDescriptionLabel.bottomAnchor, constant: 20.0),
            shareButtonsStackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        walletButton.onTap = { [weak self] in
            self?.onWalletButtonTap?()
        }

        connectYatButton.onTap = { [weak self] in
            self?.onConnectYatButtonTap?()
        }

        qrCodeButton.onTap = { [weak self] in
            self?.onQrCodeButtonTap?()
        }

        linkCodeButton.onTap = { [weak self] in
            self?.onLinkButtonTap?()
        }

        bleCodeButton.onTap = { [weak self] in
            self?.onBleButtonTap?()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        backgroundColor = theme.backgrounds.secondary
        usernameLabel.textColor = theme.text.heading
        yatOutOfSyncLabel.textColor = theme.text.body
        shareSectionSeparator.backgroundColor = theme.neutral.tertiary
        shareSectionTitleLabel.textColor = theme.text.heading
        shareSectionDescriptionLabel.textColor = theme.text.body
        yatButtonOnTintColor = theme.icons.active
        yatButtonOffTintColor = theme.icons.inactive

        updateYatButton(isOn: isYatButtonOn)
    }

    func update(username: String?) {
        usernameLabel.text = username
    }

    private func updateOutOfSyncStatus() {

        if isOutOfSyncLabelVisible {
            auroraButtonsTopConstraintOnYatLabelHidden?.isActive = false
            auroraButtonsTopConstraintOnYatLabelShown?.isActive = true
        } else {
            auroraButtonsTopConstraintOnYatLabelShown?.isActive = false
            auroraButtonsTopConstraintOnYatLabelHidden?.isActive = true
        }

        UIView.animate(withDuration: 0.3) {
            self.yatOutOfSyncLabel.alpha = self.isOutOfSyncLabelVisible ? 1.0 : 0.0
            self.layoutIfNeeded()
        }
    }

    func update(emojiID: String, hex: String?, copyText: String, tooltopText: String?) {
        emojiIdView.copyText = copyText
        emojiIdView.tooltipText = tooltopText
        emojiIdView.update(viewModel: EmojiIdView.ViewModel(emojiID: emojiID, hex: hex))
    }

    private func updateYatButton(isOn: Bool) {
        yatButton.isHidden = false
        let icon: UIImage = isOn ? .Icons.Yat.buttonOn : .Icons.Yat.buttonOff
        yatButton.setImage(icon, for: .normal)
        yatButton.tintColor = isOn ? yatButtonOnTintColor : yatButtonOffTintColor
        yatSpinnerView.isHidden = true
        yatSpinnerView.stop()
    }

    func showYatButtonSpinner() {
        yatButton.isHidden = true
        yatSpinnerView.isHidden = false
        yatSpinnerView.play()
    }

    func hideYatButton() {
        yatButton.isHidden = true
        yatSpinnerView.isHidden = true
        yatSpinnerView.stop()
    }
}
