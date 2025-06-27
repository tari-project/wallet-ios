//  ContactBookListPlaceholder.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 13/03/2023
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

final class ContactBookListPlaceholder: DynamicThemeView {

    struct ViewModel {
        let image: UIImage?
        let titleComponents: [StylizedLabel.StylizedText]
        let messageComponents: [StylizedLabel.StylizedText]
        let actionButtonTitle: String?
        let actionButtonCallback: (() -> Void)?
    }

    // MARK: - Subviews

    @TariView private var backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = .Images.Security.Onboarding.background
        return view
    }()

    @TariView private var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    @TariView private var titleLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.textAlignment = .center
        view.normalFont = .Poppins.Medium.withSize(18.0)
        view.boldFont = .Poppins.Black.withSize(18.0)
        view.separator = " "
        view.numberOfLines = 0
        return view
    }()

    @TariView private var messageLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.textAlignment = .center
        view.normalFont = .Poppins.Medium.withSize(14.0)
        view.boldFont = .Poppins.Black.withSize(14.0)
        view.separator = " "
        view.numberOfLines = 0
        return view
    }()

    @TariView private var actionButton: TextButton = {
        let view = TextButton()
        view.style = .secondary
        return view
    }()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [backgroundImageView, imageView, titleLabel, messageLabel, actionButton].forEach(addSubview)

        let constraints = [
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor, constant: 110.0),
            backgroundImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: UIScreen.isSmallScreen ? 0.2 : 0.33),
            imageView.topAnchor.constraint(equalTo: backgroundImageView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: backgroundImageView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: backgroundImageView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: backgroundImageView.bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20.0),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 35.0),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -35.0),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20.0),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 35.0),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -35.0),
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 12.0),
            actionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 35.0),
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -35.0),
            actionButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -60.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        backgroundImageView.tintColor = theme.brand.purple
        imageView.tintColor = theme.icons.default
        titleLabel.textColor = theme.text.heading
        messageLabel.textColor = theme.text.body
    }

    func update(viewModel: ViewModel) {
        imageView.image = viewModel.image
        titleLabel.textComponents = viewModel.titleComponents
        messageLabel.textComponents = viewModel.messageComponents
        actionButton.setTitle(viewModel.actionButtonTitle, for: .normal)
        actionButton.onTap = viewModel.actionButtonCallback
    }
}
