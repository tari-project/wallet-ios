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

import UIKit
import TariCommon
import Lottie

final class ProfileView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var emojiIdView = EmojiIdView()
    @View var yatButton: BaseButton = BaseButton()

    @View private var yatSpinnerView: AnimationView = {
        let view = AnimationView()
        view.animation = Animation.named(.pendingCircleAnimation)
        view.backgroundBehavior = .pauseAndRestore
        view.loopMode = .loop
        return view
    }()

    @View var middleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.profileMiddleLabel
        view.textAlignment = .center
        view.numberOfLines = 2
        view.adjustsFontSizeToFitWidth = true
        return view
    }()

    @View var reconnectYatButton: TextButton = {
        let view = TextButton()
        view.setTitle(localized("profile_view.button.recconect_yat"), for: .normal)
        return view
    }()

    @View private var buttonsStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 40.0
        return view
    }()

    @View private var qrCodeButton: ContactBookShareButton = {
        let view = ContactBookShareButton()
        view.buttonSize = 80.0
        view.padding = 15.0
        view.update(image: .icons.qr, text: localized("contact_book.share_bar.buttons.qr"))
        return view
    }()

    @View private var linkCodeButton: ContactBookShareButton = {
        let view = ContactBookShareButton()
        view.update(image: .icons.link, text: localized("contact_book.share_bar.buttons.link"))
        view.buttonSize = 80.0
        view.padding = 15.0
        return view
    }()

    @View private var bleCodeButton: ContactBookShareButton = {
        let view = ContactBookShareButton()
        view.update(image: .icons.bluetooth, text: localized("contact_book.share_bar.buttons.ble"))
        view.buttonSize = 80.0
        view.padding = 15.0
        return view
    }()

    @View private var requestTokensButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("profile_view.button.request_tokens"), for: .normal)
        return view
    }()

    // MARK: - Properties

    var isYatButtonOn: Bool = false {
        didSet { updateYatButton(isOn: isYatButtonOn) }
    }

    var onEditButtonTap: (() -> Void)?
    var onQrCodeButtonTap: (() -> Void)?
    var onLinkButtonTap: (() -> Void)?
    var onBleButtonTap: (() -> Void)?
    var onRequestTokensButtonTap: (() -> Void)?

    private var yatButtonOnTintColor: UIColor?
    private var yatButtonOffTintColor: UIColor?

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

        [emojiIdView, yatButton, yatSpinnerView, middleLabel, reconnectYatButton, buttonsStackView, requestTokensButton].forEach(addSubview)
        [qrCodeButton, linkCodeButton, bleCodeButton].forEach(buttonsStackView.addArrangedSubview)

        let constraints = [
            emojiIdView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 25.0),
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
            middleLabel.topAnchor.constraint(equalTo: emojiIdView.bottomAnchor, constant: 40.0),
            middleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 40.0),
            middleLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -40.0),
            reconnectYatButton.topAnchor.constraint(equalTo: middleLabel.bottomAnchor),
            reconnectYatButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            buttonsStackView.topAnchor.constraint(equalTo: reconnectYatButton.bottomAnchor, constant: 20.0),
            buttonsStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            requestTokensButton.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 40.0), // TODO: Small screen
            requestTokensButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            requestTokensButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        qrCodeButton.onTap = { [weak self] in
            self?.onQrCodeButtonTap?()
        }

        linkCodeButton.onTap = { [weak self] in
            self?.onLinkButtonTap?()
        }

        bleCodeButton.onTap = { [weak self] in
            self?.onBleButtonTap?()
        }

        requestTokensButton.onTap = { [weak self] in
            self?.onRequestTokensButtonTap?()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        backgroundColor = theme.backgrounds.secondary
        middleLabel.textColor = theme.text.body
        reconnectYatButton.setTitleColor(theme.text.links, for: .normal)
        yatButtonOnTintColor = theme.icons.active
        yatButtonOffTintColor = theme.icons.inactive

        updateYatButton(isOn: isYatButtonOn)
    }

    func update(emojiID: String, hex: String?, copyText: String, tooltopText: String?) {
        emojiIdView.copyText = copyText
        emojiIdView.tooltipText = tooltopText
        emojiIdView.update(viewModel: EmojiIdView.ViewModel(emojiID: emojiID, hex: hex))
    }

    private func updateYatButton(isOn: Bool) {
        yatButton.isHidden = false
        let icon = isOn ? Theme.shared.images.yatButtonOn : Theme.shared.images.yatButtonOff
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
