//  RestoreWalletFromSeedsProgressView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 27/07/2021
	Using Swift 5.0
	Running on macOS 12.0

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
import Lottie

final class RestoreWalletFromSeedsProgressView: UIView {

    // MARK: - Subviews

    private let logoView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.tariIcon
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Theme.shared.colors.restoreFromSeedWordsProgressOverlayTitle
        view.font = Theme.shared.fonts.restoreFromSeedWordsProgressOverlayTitle
        view.textAlignment = .center
        view.text = localized("restore_from_seed_words.progress_overlay.label.title")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let descriptionLabel: UILabel = {
        let view = UILabel()
        view.textColor = Theme.shared.colors.restoreFromSeedWordsProgressOverlayDescription
        view.font = Theme.shared.fonts.restoreFromSeedWordsProgressOverlayDescription
        view.textAlignment = .center
        view.numberOfLines = 0
        view.text = localized("restore_from_seed_words.progress_overlay.label.description")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let statusLabel: UILabel = {
        let view = UILabel()
        view.textColor = Theme.shared.colors.restoreFromSeedWordsProgressOverlayTitle
        view.font = Theme.shared.fonts.restoreFromSeedWordsProgressOverlayDescription
        view.adjustsFontSizeToFitWidth = true
        view.textAlignment = .center
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let progressLabel: UILabel = {
        let view = UILabel()
        view.textColor = Theme.shared.colors.restoreFromSeedWordsProgressOverlayTitle
        view.font = Theme.shared.fonts.restoreFromSeedWordsProgressOverlayTitle
        view.textAlignment = .center
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let spinnerView: AnimationView = {
        let view = AnimationView()
        view.backgroundBehavior = .pauseAndRestore
        view.animation = Animation.named(.pendingCircleAnimation)
        view.loopMode = .loop
        view.play()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let mainContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initializers

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        backgroundColor = Theme.shared.colors.appBackground
    }

    private func setupConstraints() {

        [mainContentView, statusLabel, progressLabel, spinnerView].forEach(addSubview)
        [logoView, titleLabel, descriptionLabel].forEach(mainContentView.addSubview)

        let constraints = [
            mainContentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            mainContentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            mainContentView.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusLabel.topAnchor.constraint(equalTo: mainContentView.bottomAnchor, constant: 25.0),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            progressLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5.0),
            progressLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            progressLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            spinnerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -37.0),
            spinnerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinnerView.widthAnchor.constraint(equalToConstant: 30.0),
            spinnerView.heightAnchor.constraint(equalToConstant: 30.0)
        ]

        let mainContentConstraints = [
            logoView.topAnchor.constraint(equalTo: mainContentView.topAnchor),
            logoView.centerXAnchor.constraint(equalTo: mainContentView.centerXAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 55.0),
            logoView.heightAnchor.constraint(equalToConstant: 55.0),
            titleLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 30.0),
            titleLabel.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 25.0),
            titleLabel.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -25.0),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10.0),
            descriptionLabel.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 25.0),
            descriptionLabel.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -25.0),
            descriptionLabel.bottomAnchor.constraint(equalTo: mainContentView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints + mainContentConstraints)
    }

    // MARK: - Actions

    private func updateLogoView() {
        logoView.removeGradient()
        logoView.applyGradient()
        logoView.layer.cornerRadius = min(bounds.height, bounds.width) / 2.0
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLogoView()
    }
}
