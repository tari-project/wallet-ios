/*
	Package MobileWallet
	Created by Konrad Faltyn on 03/03/2025
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

import UIKit
import TariCommon

class MiningView: UIView {

    @TariView private var containerView: UIView = {
        let view = UIView()
        return view
    }()

    @TariView private var graphicView: UIImageView = {
        let view = UIImageView(image: .welcomeGraphic)
        return view
    }()

    @TariView private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(24)
        label.textColor = .Text.primary
        label.text = "Start mining Tari!"
        return label
    }()

    @TariView private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(14)
        label.textColor = .Text.primary
        label.textAlignment = .center
        label.numberOfLines = 3
        label.text = "Download Tari Universe on your desktop or laptop device to start mining Tari. Launch the app and let the mining begin. It's that easy."
        return label
    }()

    @TariView private var linkButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .large)
        button.setTitle("Open Download Link", for: .normal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    var onSendMiningLinkTap: (() -> Void)? {
        didSet {
            linkButton.onTap = onSendMiningLinkTap
        }
    }

    func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 30
        containerView.layer.borderWidth = 1 / UIScreen.main.scale

        setupConstraints()
        updateTheme()
    }

    private func setupConstraints() {
        [containerView, graphicView, titleLabel, descriptionLabel, linkButton].forEach(addSubview)

        let constraints = [
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leftAnchor.constraint(equalTo: leftAnchor),
            containerView.rightAnchor.constraint(equalTo: rightAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 450),
            graphicView.centerYAnchor.constraint(equalTo: containerView.topAnchor),
            graphicView.widthAnchor.constraint(equalToConstant: 402),
            graphicView.heightAnchor.constraint(equalToConstant: 518),
            graphicView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -250),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            descriptionLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            descriptionLabel.widthAnchor.constraint(equalToConstant: 324),
            linkButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -110),
            linkButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func updateTheme() {
        containerView.backgroundColor = .Background.popup
        containerView.layer.borderColor = UIColor.Elevation.outlined.cgColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Check if the user interface style changed (light ↔ dark)
        if #available(iOS 13.0, *) {
            if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
                // Update colors, images, etc. here
                updateTheme()
            }
        }
    }
}
