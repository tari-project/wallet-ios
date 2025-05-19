//  ReceiveViewController.swift

/*
	Package MobileWallet
	Created by Konrad Faltyn on 28/03/2025
	Using Swift 6.0
	Running on macOS 15.3

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

import Foundation
import UIKit
import TariCommon

class ReceiveView: BaseNavigationContentView {

    var onShareButonTap: (() -> Void)? {
        didSet {
            shareButton.onTap = onShareButonTap
        }
    }
    var onCopyEmojiButonTap: (() -> Void)? {
        didSet {
            copyEmojiButton.onTap = onCopyEmojiButonTap
        }
    }
    var onCopyBaseButonTap: (() -> Void)? {
        didSet {
            copyBaseButton.onTap = onCopyBaseButonTap
        }
    }

    @View private var qrCodeView = QRCodeView()
    @View private var qrCodeIconViewOutline = UIImageView(image: .elipse)
    @View private var qrCodeIconImageView = UIImageView(image: .gem.withRenderingMode(.alwaysTemplate))

    @View private var iconImageView = UIImageView(image: .gem.withRenderingMode(.alwaysTemplate))

    @View private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(28)
        label.text = NetworkManager.shared.currencySymbol
        return label
    }()

    @View private var yourAddressLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(14)
        label.text = "Your Address"
        return label
    }()

    @View var emojiAddressLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(14)
        return label
    }()

    @View var baseAddressLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(14)
        return label
    }()

    @View var copyEmojiButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .small)
        button.setTitle("Copy", for: .normal)
        return button
    }()

    @View var copyBaseButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .small)
        button.setTitle("Copy", for: .normal)
        return button
    }()

    @View private var networkLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(12)
        label.text = "Tari " + NetworkManager.shared.selectedNetwork.presentedName
        return label
    }()

    @View private var separatorView: UIView = {
        let view = UIView()
        return view
    }()

    @View private var addressContainerView: UIView = {
        let view = UIView()
        return view
    }()

    @View var shareButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .large)
        button.setTitle("Share", for: .normal)
        return button
    }()

    @View private var label: UILabel = {
        let view = UILabel()
        view.text = NetworkManager.shared.currencySymbol
        view.font = .Poppins.Medium.withSize(14)
        return view
    }()

    var qrCode: UIImage? {
        didSet { updateViewsState() }
    }

    override init() {
        super.init()
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func setupViews() {
        updateViewsState()
        qrCodeIconImageView.backgroundColor = .clear
        qrCodeIconViewOutline.layer.cornerRadius = qrCodeIconViewOutline.bounds.width / 2
        qrCodeIconImageView.tintColor = .white
        addressContainerView.clipsToBounds = true
        addressContainerView.layer.cornerRadius = 10

        qrCodeView.layer.cornerRadius = 24
        [qrCodeView, qrCodeIconViewOutline, qrCodeIconImageView,
         shareButton, iconImageView, titleLabel,
         networkLabel, addressContainerView, yourAddressLabel,
         emojiAddressLabel, baseAddressLabel, separatorView, copyEmojiButton, copyBaseButton].forEach(addSubview)

        NSLayoutConstraint.activate([
            qrCodeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            qrCodeView.topAnchor.constraint(equalTo: topAnchor, constant: 170),
            qrCodeView.widthAnchor.constraint(equalToConstant: 231),
            qrCodeView.heightAnchor.constraint(equalToConstant: 231),
            qrCodeIconViewOutline.centerYAnchor.constraint(equalTo: qrCodeIconImageView.centerYAnchor),
            qrCodeIconViewOutline.centerXAnchor.constraint(equalTo: qrCodeIconImageView.centerXAnchor),
            qrCodeIconViewOutline.widthAnchor.constraint(equalToConstant: 59),
            qrCodeIconViewOutline.heightAnchor.constraint(equalToConstant: 59),
            qrCodeIconImageView.centerXAnchor.constraint(equalTo: qrCodeView.centerXAnchor),
            qrCodeIconImageView.centerYAnchor.constraint(equalTo: qrCodeView.centerYAnchor),
            qrCodeIconImageView.widthAnchor.constraint(equalToConstant: 27),
            qrCodeIconImageView.heightAnchor.constraint(equalToConstant: 27),
            shareButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32),
            shareButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 28),
            shareButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -28),
            iconImageView.bottomAnchor.constraint(equalTo: qrCodeView.topAnchor, constant: -16),
            iconImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 100),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.leftAnchor.constraint(equalTo: iconImageView.rightAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            networkLabel.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 16),
            networkLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            addressContainerView.topAnchor.constraint(equalTo: qrCodeView.bottomAnchor, constant: 30),
            addressContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            addressContainerView.widthAnchor.constraint(equalToConstant: 316),
            addressContainerView.heightAnchor.constraint(equalToConstant: 140),
            yourAddressLabel.topAnchor.constraint(equalTo: addressContainerView.topAnchor, constant: 14),
            yourAddressLabel.leftAnchor.constraint(equalTo: addressContainerView.leftAnchor, constant: 14),
            emojiAddressLabel.leftAnchor.constraint(equalTo: yourAddressLabel.leftAnchor),
            emojiAddressLabel.topAnchor.constraint(equalTo: yourAddressLabel.bottomAnchor, constant: 11),
            baseAddressLabel.topAnchor.constraint(equalTo: emojiAddressLabel.bottomAnchor, constant: 30),
            baseAddressLabel.leftAnchor.constraint(equalTo: emojiAddressLabel.leftAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.leftAnchor.constraint(equalTo: addressContainerView.leftAnchor, constant: 15),
            separatorView.rightAnchor.constraint(equalTo: addressContainerView.rightAnchor, constant: -15),
            separatorView.topAnchor.constraint(equalTo: emojiAddressLabel.bottomAnchor, constant: 15),
            copyEmojiButton.centerYAnchor.constraint(equalTo: emojiAddressLabel.centerYAnchor),
            copyEmojiButton.widthAnchor.constraint(equalToConstant: 60),
            copyEmojiButton.heightAnchor.constraint(equalToConstant: 30),
            copyEmojiButton.rightAnchor.constraint(equalTo: addressContainerView.rightAnchor, constant: -15),
            copyBaseButton.centerYAnchor.constraint(equalTo: baseAddressLabel.centerYAnchor),
            copyBaseButton.widthAnchor.constraint(equalToConstant: 60),
            copyBaseButton.heightAnchor.constraint(equalToConstant: 30),
            copyBaseButton.rightAnchor.constraint(equalTo: addressContainerView.rightAnchor, constant: -15)
        ])
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)

        backgroundColor = .Background.secondary
        addressContainerView.backgroundColor = .Background.accent

        iconImageView.tintColor = .Text.primary
        titleLabel.textColor = .Text.primary
        yourAddressLabel.textColor = .Text.secondary

        separatorView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)

        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        if isDarkMode {
            qrCodeView.apply(shadow: nil)
            addressContainerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.12)
        } else {
            addressContainerView.backgroundColor = UIColor(red: 0.106, green: 0.098, blue: 0.129, alpha: 0.04)
            qrCodeView.apply(shadow: Shadow(color: .Light.Shadows.box, opacity: 1.0, radius: 13.5, offset: CGSize(width: -1.0, height: 6.5)))
        }

    }

    func setup(pagerView: UIView) {
        addSubview(pagerView)

        let constraints = [
            pagerView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            pagerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pagerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pagerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func updateViewsState() {
        guard let qrCode else {
            qrCodeView.state = .loading
            qrCodeIconImageView.isHidden = true
            qrCodeIconViewOutline.isHidden = true
            return
        }

        qrCodeIconImageView.isHidden = false
        qrCodeIconViewOutline.isHidden = false
        qrCodeView.state = .image(qrCode)
    }
}
