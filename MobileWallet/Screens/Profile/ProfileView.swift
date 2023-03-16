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

final class ProfileView: DynamicThemeView {

    // MARK: - Subviews

    @View private var navigationBar: NavigationBar = {
        let view = NavigationBar()
        view.backButtonType = .back
        view.title = localized("profile_view.title")
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

    @View private var qrContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10.0
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale
        return view
    }()

    @View private var qrImageView = UIImageView()

    var qrCodeImage: UIImage? {
        didSet { qrImageView.image = qrCodeImage }
    }

    var isYatButtonOn: Bool = false {
        didSet { updateYatButton(isOn: isYatButtonOn) }
    }

    private var yatButtonOnTintColor: UIColor?
    private var yatButtonOffTintColor: UIColor?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()

        yatButton.imageView?.contentMode = .scaleAspectFit
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [navigationBar, emojiIdView, yatButton, yatSpinnerView, middleLabel, reconnectYatButton, qrContainer].forEach(addSubview)
        qrContainer.addSubview(qrImageView)

        var constraints = [
            navigationBar.topAnchor.constraint(equalTo: topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor),
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
            middleLabel.topAnchor.constraint(equalTo: emojiIdView.bottomAnchor, constant: 20),
            middleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 22.0),
            middleLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -22.0),
            reconnectYatButton.topAnchor.constraint(equalTo: middleLabel.bottomAnchor),
            reconnectYatButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            qrContainer.heightAnchor.constraint(equalTo: qrContainer.widthAnchor),
            qrContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            qrImageView.leadingAnchor.constraint(equalTo: qrContainer.leadingAnchor, constant: 30.0),
            qrImageView.trailingAnchor.constraint(equalTo: qrContainer.trailingAnchor, constant: -30.0),
            qrImageView.bottomAnchor.constraint(equalTo: qrContainer.bottomAnchor, constant: -30.0),
            qrImageView.topAnchor.constraint(equalTo: qrContainer.topAnchor, constant: 30.0)
        ]

        if UIDevice.current.userInterfaceIdiom == .pad {
            constraints += [
                qrContainer.topAnchor.constraint(equalTo: reconnectYatButton.bottomAnchor, constant: 100.0),
                qrContainer.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.5),
                qrContainer.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.5)
            ]
        } else {
            constraints += [
                qrContainer.topAnchor.constraint(greaterThanOrEqualTo: reconnectYatButton.bottomAnchor, constant: 10.0),
                qrContainer.topAnchor.constraint(lessThanOrEqualTo: reconnectYatButton.bottomAnchor, constant: 25.0),
                qrContainer.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 22.0),
                qrContainer.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -22.0)
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        backgroundColor = theme.backgrounds.secondary
        middleLabel.textColor = theme.text.body
        reconnectYatButton.setTitleColor(theme.text.links, for: .normal)
        yatButtonOnTintColor = theme.icons.active
        yatButtonOffTintColor = theme.icons.inactive
        qrContainer.backgroundColor = theme.components.qrBackground
        qrContainer.apply(shadow: theme.shadows.box)

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

    // MARK: - Autolayout

    override func layoutSubviews() {
        super.layoutSubviews()
        let shadowFrame: CGRect = qrContainer.bounds.insetBy(dx: 4.0, dy: 4.0)
        qrContainer.layer.shadowPath = UIBezierPath(rect: shadowFrame).cgPath
    }
}
