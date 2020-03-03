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
import SwiftEntryKit
import AVFoundation

class SplashViewController: UIViewController {
    // MARK: - Variables and constants
    var player: AVQueuePlayer!
    var playerLayer: AVPlayerLayer!
    var playerItem: AVPlayerItem!
    var playerLooper: AVPlayerLooper!
    private let localAuthenticationContext = LAContext()
    var ticketTopLayoutConstraint: NSLayoutConstraint?
    var ticketBottom: NSLayoutConstraint?
    var walletExistsInitially: Bool = false
    var alreadyReplacedVideo: Bool = false
    var isUnitTesting: Bool {
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

    private let progressFeedbackView = FeedbackView()

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadAnimation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isUnitTesting {
            titleAnimation()
            checkExistingWallet()
        }

        handleWalletEvents()
    }

    private func handleWalletEvents() {
        //Handle tor progress
        TariEventBus.onMainThread(self, eventType: .torConnectionProgress) { [weak self] (result) in
            guard let self = self else { return }

            if let progress: Int = result?.object as? Int {
                if progress == 0 {
                    var attributes = EKAttributes.topToast
                    attributes.entryBackground = .color(color: EKColor(Theme.shared.colors.successFeedbackPopupBackground!))
                    attributes.screenBackground = .clear
                    attributes.shadow = .active(with: .init(color: EKColor(Theme.shared.colors.feedbackPopupBackground!), opacity: 0.35, radius: 10, offset: .zero))
                    attributes.displayDuration = .infinity
                    attributes.screenInteraction = .forward
                    SwiftEntryKit.display(entry: self.progressFeedbackView, using: attributes)
                }

                self.progressFeedbackView.setupSuccess(title: "Tor bootstrapping: \(progress)%")
            }
        }

        //Handle on tor connected
        TariEventBus.onMainThread(self, eventType: .torConnected) { [weak self] (_) in
            guard let self = self else { return }

            self.progressFeedbackView.setupSuccess(title: "Tor connection established")

            if self.walletExistsInitially {
                self.startExistingWallet()
            } else {
                self.createNewWallet()
            }
        }

        TariEventBus.onMainThread(self, eventType: .torConnectionFailed) { [weak self] (result) in
            guard let _ = self else { return }

            let error: Error? = result?.object as? Error

            UserFeedback.shared.error(
                title: NSLocalizedString("Tor connection error", comment: "Splash screen"),
                description: NSLocalizedString("Could not establish a connection to the network", comment: "Splash screen"),
                error: error
            )
        }
    }

    private func startExistingWallet() {
        //Kick off wallet creation on a background thread
        DispatchQueue.global().async {
            do {
                try TariLib.shared.startExistingWallet()

                DispatchQueue.main.async {
                    SwiftEntryKit.dismiss()
                    self.authenticateUser()
                }
            } catch {
                DispatchQueue.main.async {
                    UserFeedback.shared.error(
                        title: NSLocalizedString("Wallet error", comment: "Splash screen"),
                        description: NSLocalizedString("Error starting existing wallet", comment: "Splash screen"),
                        error: error
                    )
                }
            }
        }
    }

    private func createNewWallet() {
        do {
            try TariLib.shared.createNewWallet()
            SwiftEntryKit.dismiss()

            if let _ = self.ticketTopLayoutConstraint {
                self.topAnimationAndRemoveVideoAnimation { [weak self] (_) in
                    guard let self = self else { return }
                    self.startAnimation()
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.startAnimation()
                }
            }
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Wallet error", comment: "Splash screen for new users"),
                description: NSLocalizedString("Failed to create a new wallet", comment: "Splash screen for new users"), error: error //TODO copy update
            )

            createWalletButton.variation = .normal
        }
    }

    // MARK: - Private functions

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

    private func checkExistingWallet() {
        if TariLib.shared.walletExists {
            TariLib.shared.startTor()
        } else {
            setupVideoAnimation()
            createWalletButton.isHidden = false
        }
    }

    @objc func onCreateWalletTap() {
        createWalletButton.variation = .loading
        TariLib.shared.startTor()
    }

    private func authenticateUser() {
        #if targetEnvironment(simulator)
        //Skip auth on simulator, quicker for development
        self.startAnimation()
        return
        #endif

        let authPolicy: LAPolicy = .deviceOwnerAuthentication

        var error: NSError?
        if localAuthenticationContext.canEvaluatePolicy(authPolicy, error: &error) {
                let reason = "Log in to your account"
                self.localAuthenticationContext.evaluatePolicy(authPolicy, localizedReason: reason ) { [weak self] success, error in
                    guard let self = self else { return }
                    if success {
                        if let _ = self.ticketTopLayoutConstraint {
                            self.topAnimationAndRemoveVideoAnimation { [weak self] (_) in
                                guard let self = self else { return }
                                self.startAnimation()
                            }
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
