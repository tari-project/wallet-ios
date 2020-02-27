//  SplashViewController.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/05
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
import Lottie
import LocalAuthentication
import AVFoundation

class SplashViewController: UIViewController {
    // MARK: - Variables and constants
    private var player: AVQueuePlayer!
    private var playerLayer: AVPlayerLayer!
    private var playerItem: AVPlayerItem!
    private var playerLooper: AVPlayerLooper!
    private let localAuthenticationContext = LAContext()
    var ticketTop: NSLayoutConstraint?
    var ticketBottom: NSLayoutConstraint?
    var walletExistsInitially: Bool = false
    var alreadyReplacedVideo: Bool = false
    var unitTesting: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    // MARK: - Outlets
    var videoView: UIView!
    var versionLabel: UILabel!
    var animationContainer: AnimationView!
    var createWalletButton: ActionButton!
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var bottomBackgroundView: UIView!
    var gemImageView: UIImageView!
    var distanceTitleSubtitle: NSLayoutConstraint!
    var animationContainerBottomAnchor: NSLayoutConstraint?
    var animationContainerBottomAnchorToVideo: NSLayoutConstraint?

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadAnimation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !unitTesting {
            titleAnimation()
            checkExistingWallet()
        }
    }

    // MARK: - Private functions
    private func setupVideoAnimation() {
        if let path = Bundle.main.path(forResource: "1-Intro", ofType: "mp4") {

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
            playerLayer.frame = videoView.layer.bounds
            player.play()
            videoView.layer.insertSublayer(playerLayer, at: 0)
            videoView.clipsToBounds = true

            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        }
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        if !alreadyReplacedVideo {
            if let path = Bundle.main.path(forResource: "2-Loop", ofType: "mp4") {
                let pathURL = URL(fileURLWithPath: path)
                let duration = Int64( ( (Float64(CMTimeGetSeconds(AVAsset(url: pathURL).duration)) *  10.0) - 1) / 10.0 )

                playerItem = AVPlayerItem(url: pathURL)
                player.replaceCurrentItem(with: playerItem)

                playerLooper = AVPlayerLooper(player: player,
                                              templateItem: playerItem,
                                              timeRange: CMTimeRange(start: CMTime.zero, end: CMTimeMake(value: duration, timescale: 1)))
                alreadyReplacedVideo = true
            }
        }
    }

    private func setupView() {
        updateConstraintsAnimationContainer()
        updateConstraintsVideoView()
        updateConstraintsTitleLabel()
        updateConstraintsSubtitleLabel()
        updateConstraintsBottomBagroundView()
        updateConstraintsCreateWalletButton()
        updateConstraintsGemImageView()
        setupContraintsVersionLabel()
        createWalletButton.isHidden = true

        createWalletButton.setTitle(NSLocalizedString("Create Wallet", comment: "Main action button on the onboarding screen"), for: .normal)
        titleLabel.text = NSLocalizedString("A crypto wallet that’s easy to use.", comment: "Title Label on the onboarding screen")
        titleLabel.font = Theme.shared.fonts.splashTitleLabelFont
        titleLabel.textColor = Theme.shared.colors.splashTitle

        subtitleLabel.text = NSLocalizedString("Tari wallet puts you and your privacy at the core of everything and is still easy to use.", comment: "Subtitle Label on the onboarding screen")

        subtitleLabel.textColor = Theme.shared.colors.splashSubtitle
        subtitleLabel.font = Theme.shared.fonts.splashSubtitleLabelFont

        versionLabel.font = Theme.shared.fonts.splashTestnetFooterLabel
        versionLabel.textColor = Theme.shared.colors.splashVersionLabel
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let labelText = NSLocalizedString("Testnet", comment: "Bottom version label for splash screen")
            versionLabel.text = "\(labelText) V\(version)".uppercased()
        }
    }

    private func updateConstraintsAnimationContainer() {
        animationContainer = AnimationView()
        view.addSubview(animationContainer)
        animationContainer.translatesAutoresizingMaskIntoConstraints = false
        animationContainer.widthAnchor.constraint(equalToConstant: 240).isActive = true
        animationContainer.heightAnchor.constraint(equalToConstant: 128).isActive = true
        animationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true

        if TariLib.shared.walletExists {
            animationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
            walletExistsInitially = true
        } else {
            ticketTop = animationContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
            ticketTop?.isActive = true

            animationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                                        constant: 0).isActive = true
            walletExistsInitially = false
        }
    }

    private func updateConstraintsVideoView() {
        videoView = UIView()
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        if TariLib.shared.walletExists {
            animationContainerBottomAnchor?.isActive = false
        } else {
            animationContainerBottomAnchor = videoView.topAnchor.constraint(equalTo: animationContainer.bottomAnchor,
            constant: 0)
            animationContainerBottomAnchor?.isActive = true

            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
            videoView.widthAnchor.constraint(equalTo: videoView.heightAnchor, multiplier: 750.0/748.0).isActive = true
        }
    }

    private func updateConstraintsTitleLabel() {
        titleLabel = UILabel()
        view.addSubview(titleLabel)

        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true

        if TariLib.shared.walletExists {
            animationContainer.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: 0).isActive = true
        }
    }

    private func updateConstraintsSubtitleLabel() {
        subtitleLabel = UILabel()
        view.addSubview(subtitleLabel)

        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Theme.shared.sizes.appSidePadding).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Theme.shared.sizes.appSidePadding).isActive = true

        subtitleLabel.topAnchor.constraint(equalTo: videoView.bottomAnchor, constant: 100).isActive = true
        distanceTitleSubtitle = subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: -100)
        distanceTitleSubtitle.isActive = true
    }

    private func updateConstraintsBottomBagroundView() {
        bottomBackgroundView = UIView()
        view.insertSubview(bottomBackgroundView, belowSubview: subtitleLabel)
        bottomBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        bottomBackgroundView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 0).isActive = true
        bottomBackgroundView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: 0).isActive = true
        bottomBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                     constant: 0).isActive = true
        bottomBackgroundView.topAnchor.constraint(equalTo: subtitleLabel.topAnchor,
                                                  constant: 0).isActive = true
        bottomBackgroundView.backgroundColor = .black
    }

    private func updateConstraintsCreateWalletButton() {
        createWalletButton = ActionButton()
        createWalletButton.addTarget(self, action: #selector(createWallet), for: .touchUpInside)
        view.addSubview(createWalletButton)
        createWalletButton.translatesAutoresizingMaskIntoConstraints = false

        createWalletButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Theme.shared.sizes.appSidePadding).isActive = true
        createWalletButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Theme.shared.sizes.appSidePadding).isActive = true
        createWalletButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor,
                                                constant: 25).isActive = true

    }

    private func updateConstraintsGemImageView() {
        gemImageView = UIImageView()
        view.addSubview(gemImageView)
        gemImageView.image = UIImage(named: "Gem")
        gemImageView.translatesAutoresizingMaskIntoConstraints = false
        gemImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        gemImageView.topAnchor.constraint(equalTo: createWalletButton.bottomAnchor, constant: 35).isActive = true
        gemImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        gemImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
    }

    private func setupContraintsVersionLabel() {
        versionLabel = UILabel()
        view.addSubview(versionLabel)
        versionLabel.textAlignment = .center
        versionLabel.numberOfLines = 0
        versionLabel.translatesAutoresizingMaskIntoConstraints = false

        versionLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.bottomAnchor, constant: 0).isActive = true
        versionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Theme.shared.sizes.appSidePadding).isActive = true
        versionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Theme.shared.sizes.appSidePadding).isActive = true
        versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        versionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16).isActive = true
        versionLabel.topAnchor.constraint(equalTo: gemImageView.bottomAnchor, constant: 16).isActive = true
    }

    private func titleAnimation() {
        self.distanceTitleSubtitle.constant = 26.0
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        }
    }

    private func topAnimationAndRemoveVideoAnimation() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.ticketTop?.isActive = false
            self.animationContainerBottomAnchor?.isActive = false
            self.animationContainerBottomAnchorToVideo?.isActive = false
            self.ticketBottom?.isActive = false
            self.videoView.isHidden = true
            self.animationContainer.bottomAnchor.constraint(equalTo: self.titleLabel.topAnchor, constant: 0).isActive = true

            UIView.animate(withDuration: 2.0, animations: { [weak self] in
                guard let self = self else { return }
                self.view.layoutIfNeeded()
            }) { [weak self] (_) in
                guard let self = self else { return }
                self.startAnimation()
            }
        }
    }

    private func checkExistingWallet() {
        if TariLib.shared.walletExists {
            do {
                try TariLib.shared.startExistingWallet()
            } catch {
                fatalError(error.localizedDescription)
            }

            #if targetEnvironment(simulator)
                startAnimation()
            #else
                authenticateUser()
            #endif
        } else {
            setupVideoAnimation()
            createWalletButton.isHidden = false
        }
    }

    @objc func createWallet() {
        createWalletButton.variation = .loading

        do {
            try TariLib.shared.createNewWallet()

            if let _ = self.ticketTop {
                self.topAnimationAndRemoveVideoAnimation()
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.startAnimation()
                }
            }
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to create new wallet", comment: ""),
                description: NSLocalizedString("", comment: ""), error: error //TODO copy update
            )

            createWalletButton.variation = .normal
        }
    }

    private func authenticateUser() {
        let authPolicy: LAPolicy = .deviceOwnerAuthentication

        var error: NSError?
        if localAuthenticationContext.canEvaluatePolicy(authPolicy, error: &error) {
                let reason = "Log in to your account"
                self.localAuthenticationContext.evaluatePolicy(authPolicy, localizedReason: reason ) { [weak self] success, error in
                    guard let self = self else { return }
                    if success {
                        if let _ = self.ticketTop {
                            self.topAnimationAndRemoveVideoAnimation()
                        } else {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                self.startAnimation()
                            }
                        }

                    } else {
                        let reason = error?.localizedDescription ?? NSLocalizedString("Failed to authenticate", comment: "Failed Face ID alert")
                        print(reason)
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.authenticationFailedAlertOptions(reason: reason)
                        }
                    }
                }
        } else {
            let reason = error?.localizedDescription ?? NSLocalizedString("No available biometrics available", comment: "Failed Face ID alert")
            print(reason)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.authenticationFailedAlertOptions(reason: reason)
            }
        }
    }

    private func authenticationFailedAlertOptions(reason: String) {
        let alert = UIAlertController(title: "Authentication failed", message: reason, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try again", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.authenticateUser()
        }))

        alert.addAction(UIAlertAction(title: "Open settings", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.openAppSettings()
        }))

        self.present(alert, animated: true, completion: nil)
    }

    private func openAppSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings)
        }
    }

    private func loadAnimation() {
        let animation = Animation.named("SplashAnimation")
        animationContainer.animation = animation
    }

    private func startAnimation() {
        #if targetEnvironment(simulator)
          animationContainer.animationSpeed = 5
        #endif

        animationContainer.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { [weak self] (_) in
                guard let self = self else { return }
                self.navigateToHome()
            }
        )
    }

    private func navigateToHome() {
        if walletExistsInitially {
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            if let nav = storyboard.instantiateInitialViewController() as? UINavigationController {
                nav.modalPresentationStyle = .overFullScreen
                self.present(nav, animated: true, completion: nil)
            }
        } else {
            let vc = WalletCreationViewController()
            vc.modalPresentationStyle = .fullScreen
            let transition = CATransition()
            transition.duration = 0.5
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromBottom
            if let window = view.window {
                window.layer.add(transition, forKey: kCATransition)
                present(vc, animated: false, completion: nil)
            }
        }
    }
}
