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
    var walletExistsInitially: Bool = false
    var alreadyReplacedVideo: Bool = false

    // MARK: - Outlets
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var animationContainer: AnimationView!
    @IBOutlet weak var createWalletButton: ActionButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var distanceTitleSubtitle: NSLayoutConstraint!
    @IBOutlet weak var animationContainerTopAnchor: NSLayoutConstraint!
    @IBOutlet weak var animationContainerBottomAnchor: NSLayoutConstraint!

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()

        createWalletButton.isHidden = true
        setupView()
        loadAnimation()
        setupConstraintsAnimationContainer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        titleAnimation()
        checkExistingWallet()
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
        createWalletButton.setTitle(NSLocalizedString("Create Wallet", comment: "Main action button on the onboarding screen"), for: .normal)
        titleLabel.text = NSLocalizedString("A crypto wallet that’s easy to use.", comment: "Title Label on the onboarding screen")
        titleLabel.font = Theme.shared.fonts.splashTitleLabel
        titleLabel.textColor = Theme.shared.colors.splashTitleColor

        subtitleLabel.text = NSLocalizedString("Tari wallet puts you and your privacy at the core of everything and is still easy to use.", comment: "Subtitle Label on the onboarding screen")

        versionLabel.font = Theme.shared.fonts.splashTestnetFooterLabel
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let labelText = NSLocalizedString("Testnet", comment: "Bottom version label for splash screen")
            versionLabel.text = "\(labelText) V\(version)".uppercased()
        }
    }

    private func setupConstraintsAnimationContainer() {
        if TariLib.shared.walletExists {
            animationContainer.translatesAutoresizingMaskIntoConstraints = false
            animationContainer.widthAnchor.constraint(equalToConstant: 240).isActive = true
            animationContainer.heightAnchor.constraint(equalToConstant: 128).isActive = true
            animationContainerTopAnchor.isActive = false
            animationContainerBottomAnchor.isActive = false
            animationContainer.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: 0).isActive = true
            animationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
            walletExistsInitially = true
        } else {
            animationContainer.translatesAutoresizingMaskIntoConstraints = false
            animationContainer.widthAnchor.constraint(equalToConstant: 240).isActive = true
            animationContainer.heightAnchor.constraint(equalToConstant: 128).isActive = true
            ticketTop = animationContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
            ticketTop?.isActive = true
            animationContainer.bottomAnchor.constraint(equalTo: videoView.topAnchor, constant: 40).isActive = true
            animationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
            walletExistsInitially = false
        }
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

            authenticateUser()
        } else {
            setupVideoAnimation()
            createWalletButton.isHidden = false
        }
    }

    @IBAction func createWallet(_ sender: Any) {
        do {
            try TariLib.shared.createNewWallet()
            authenticateUser()
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to create new wallet", comment: ""),
                description: NSLocalizedString("", comment: ""), error: error //TODO copy update
            )
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

        createWalletButton.animateOut()

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
            performSegue(withIdentifier: "WalletExistsToHome", sender: nil)
        } else {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "WalletCreationViewController") as? WalletCreationViewController {
                vc.modalPresentationStyle = .fullScreen
                let transition = CATransition()
                transition.duration = 0.5
                transition.type = CATransitionType.push
                transition.subtype = CATransitionSubtype.fromBottom
                view.window!.layer.add(transition, forKey: kCATransition)
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
}
