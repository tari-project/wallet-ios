//  SplashViewControllerSetup.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/03/03
	Using Swift 5.0
	Running on macOS 10.15

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
import AVFoundation
import Lottie

extension SplashViewController {
    func setupView() {
        updateConstraintsAnimationContainer()
        updateConstraintsVideoView()
        updateConstraintsTitleLabel()
        updateConstraintsSubtitleLabel()
        updateConstraintsBottomBagroundView()
        updateConstraintsCreateWalletButton()
        updateConstraintsGemImageView()
        setupContraintsVersionLabel()
        setupMaskBackground()
        createWalletButton.isHidden = true

        createWalletButton.setTitle(NSLocalizedString("Create Your Wallet", comment: "Main action button on the onboarding screen"), for: .normal)
        titleLabel.isHidden = true

        let attributedTitleString = NSMutableAttributedString(string: NSLocalizedString("Welcome to Tari Aurora.", comment: "Title Label on the onboarding screen"))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.alignment = .center
        attributedTitleString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedTitleString.length))
        titleLabel.attributedText = attributedTitleString

        titleLabel.font = Theme.shared.fonts.splashTitleLabel
        titleLabel.textColor = Theme.shared.colors.splashTitle

        subtitleLabel.isHidden = true
        subtitleLabel.text = NSLocalizedString("Get ready to send and receive Testnet Tari with an easy-to-use crypto wallet that puts privacy first.", comment: "Subtitle Label on the onboarding screen")

        subtitleLabel.textColor = Theme.shared.colors.splashSubtitle
        subtitleLabel.font = Theme.shared.fonts.splashSubtitleLabel

        versionLabel.font = Theme.shared.fonts.splashTestnetFooterLabel
        versionLabel.textColor = Theme.shared.colors.splashVersionLabel
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let labelText = NSLocalizedString("Testnet", comment: "Bottom version label for splash screen")
            versionLabel.text = "\(labelText) V\(version)".uppercased()
        }
    }

    func loadAnimation() {
        let animation = Animation.named("SplashAnimation")
        animationContainer.animation = animation
    }

    func setupVideoAnimation() {
        if let path = Bundle.main.path(forResource: "purple_orb", ofType: "mp4") {
            _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: .default, options: .mixWithOthers)
            let pathURL = URL(fileURLWithPath: path)
            let duration = Int64( ( (Float64(CMTimeGetSeconds(AVAsset(url: pathURL).duration)) *  10.0) - 1) / 10.0 )

            player = AVQueuePlayer()
            playerLayer = AVPlayerLayer(player: player)
            playerItem = AVPlayerItem(url: pathURL)
            playerLooper = AVPlayerLooper(player: player,
                                          templateItem: playerItem,
                                          timeRange: CMTimeRange(start: CMTime.zero, end: CMTimeMake(value: duration, timescale: 1)))
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            let rect = videoView.layer.bounds
            let changedRect = CGRect(x: -160, y: -20, width: rect.width + 320, height: rect.height * 1.1)
            playerLayer.frame = changedRect
            player.play()
            videoView.layer.insertSublayer(playerLayer, at: 0)
            videoView.clipsToBounds = true
        }
    }

    func updateConstraintsAnimationContainer() {
        animationContainer = AnimationView()
        view.addSubview(animationContainer)
        animationContainer.translatesAutoresizingMaskIntoConstraints = false
        animationContainer.widthAnchor.constraint(equalToConstant: 150).isActive = true
        animationContainer.heightAnchor.constraint(equalToConstant: 80).isActive = true
        animationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true

        if TariLib.shared.walletExists {
            animationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
            walletExistsInitially = true
        } else {
            ticketTopLayoutConstraint = animationContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
            ticketTopLayoutConstraint?.isActive = true

            animationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
            walletExistsInitially = false
        }
    }

    func updateConstraintsVideoView() {
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        if TariLib.shared.walletExists {
            animationContainerBottomAnchor?.isActive = false
        } else {
            animationContainerBottomAnchor = videoView.topAnchor.constraint(equalTo: animationContainer.bottomAnchor, constant: 20)
            animationContainerBottomAnchor?.isActive = true
            videoView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
            videoView.widthAnchor.constraint(equalTo: videoView.heightAnchor, multiplier: 750.0/648.0).isActive = true
        }
    }

    func updateConstraintsTitleLabel() {
        view.addSubview(titleLabel)

        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        //titleLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true

        titleLabel.topAnchor.constraint(equalTo: videoView.bottomAnchor, constant: 40).isActive = true

        if TariLib.shared.walletExists {
            animationContainer.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: 0).isActive = true
        }
    }

    func updateConstraintsSubtitleLabel() {
        view.addSubview(subtitleLabel)

        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true

        //subtitleLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        distanceTitleSubtitle = subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: -20)
        distanceTitleSubtitle.isActive = true
    }

    func updateConstraintsBottomBagroundView() {
        view.insertSubview(bottomBackgroundView, belowSubview: subtitleLabel)
        bottomBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        bottomBackgroundView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        bottomBackgroundView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        bottomBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        bottomBackgroundView.topAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: 0).isActive = true
    }

    func updateConstraintsCreateWalletButton() {
        createWalletButton = ActionButton()
        createWalletButton.addTarget(self, action: #selector(onCreateWalletTap), for: .touchUpInside)
        view.addSubview(createWalletButton)
        createWalletButton.translatesAutoresizingMaskIntoConstraints = false

        createWalletButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        createWalletButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        createWalletButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40).isActive = true
    }

    func updateConstraintsGemImageView() {
        gemImageView = UIImageView()
        view.addSubview(gemImageView)
        gemImageView.image = UIImage(named: "Gem")
        gemImageView.translatesAutoresizingMaskIntoConstraints = false
        gemImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        gemImageView.topAnchor.constraint(equalTo: createWalletButton.bottomAnchor, constant: 35).isActive = true
        gemImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        gemImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
    }

    func setupContraintsVersionLabel() {
        view.addSubview(versionLabel)
        versionLabel.textAlignment = .center
        versionLabel.numberOfLines = 0
        versionLabel.translatesAutoresizingMaskIntoConstraints = false

        versionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        versionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Theme.shared.sizes.appSidePadding).isActive = true
        versionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Theme.shared.sizes.appSidePadding).isActive = true
        versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        versionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16).isActive = true
        versionLabel.topAnchor.constraint(equalTo: gemImageView.bottomAnchor, constant: 16).isActive = true
    }

    func setupMaskBackground() {
        view.addSubview(maskBackgroundView)
        maskBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        maskBackgroundView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 0).isActive = true
        maskBackgroundView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: 0).isActive = true
        maskBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                     constant: 0).isActive = true
        maskBackgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                  constant: 0).isActive = true
        maskBackgroundView.backgroundColor = .black
    }

    func titleAnimation() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.distanceTitleSubtitle.constant = 40.0
            self.view.layoutIfNeeded()
        }
    }

    func maskBackgroundAnimation() {
        UIView.animate(withDuration: 2) { [weak self] in
            guard let self = self else { return }
            self.maskBackgroundView.alpha = 0.0
            self.view.layoutIfNeeded()
        }
    }

    func topAnimationAndRemoveVideoAnimation(onComplete: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.ticketTopLayoutConstraint?.isActive = false
            self.animationContainerBottomAnchor?.isActive = false
            self.animationContainerBottomAnchorToVideo?.isActive = false
            self.ticketBottom?.isActive = false
            self.videoView.isHidden = true
            self.animationContainer.bottomAnchor.constraint(equalTo: self.titleLabel.topAnchor, constant: 0).isActive = true

            UIView.animate(withDuration: 1.0, animations: { [weak self] in
                guard let self = self else { return }
                self.titleLabel.alpha = 0.0
                self.subtitleLabel.alpha = 0.0
                self.createWalletButton.alpha = 0.0
                self.gemImageView.alpha = 0.0
                self.versionLabel.alpha = 0.0
                self.view.layoutIfNeeded()
            }) { [weak self] (_) in
                guard let self = self else { return }
                self.startAnimation(onComplete: onComplete)
            }
        }
    }
}
