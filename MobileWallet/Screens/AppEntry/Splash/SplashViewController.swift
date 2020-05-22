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

class SplashViewController: UIViewController, UITextViewDelegate {
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

    // MARK: - Outlets
    var videoView = UIView()
    var versionLabel = UILabel()
    var animationContainer = AnimationView()
    var elementsContainer = UIView()
    var createWalletButton = ActionButton()
    var titleLabel = UILabel()
    var gemImageView = UIImageView()
    var disclaimerText = UITextView()

    var distanceTitleSubtitle = NSLayoutConstraint()
    var animationContainerBottomAnchor: NSLayoutConstraint?
    var animationContainerBottomAnchorToVideo: NSLayoutConstraint?
    private let progressFeedbackView = FeedbackView()
    private lazy var authStepPassed: Bool = {
        UserDefaults.standard.bool(forKey: "authStepPassed")
    }()

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadAnimation()

        handleWalletEvents()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !TariSettings.shared.isUnitTesting {
            titleAnimation()
            checkExistingWallet()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        SwiftEntryKit.dismiss()
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
                }

                self.progressFeedbackView.setupSuccess(title: "Tor bootstrapping: \(progress)%")
            }
        }

        //Handle on tor connected
        TariEventBus.onMainThread(self, eventType: .torConnected) { [weak self] (_) in
            guard let self = self else { return }

            self.progressFeedbackView.setupSuccess(title: "Tor connection established")
        }

        TariEventBus.onMainThread(self, eventType: .torConnectionFailed) { [weak self] (result) in
            guard let _ = self else { return }

            let error: Error? = result?.object as? Error

            UserFeedback.shared.error(
                title: NSLocalizedString("Tor connection error", comment: "Splash screen"),
                description: NSLocalizedString("Could not establish a connection to the network.", comment: "Splash screen"),
                error: error
            )
        }
    }

    private func onTorSuccess(_ onComplete: @escaping () -> Void) {
        if TariLib.shared.torPortsOpened {
            onComplete()
            return
        }

        //Handle if tor ports opened later
        TariEventBus.onMainThread(self, eventType: .torPortsOpened) { [weak self] (_) in
            guard let _ = self else { return }
            onComplete()
        }
    }

    private func startExistingWallet(onComplete: @escaping () -> Void) {
        //Kick off wallet creation on a background thread
        DispatchQueue.global().async {
            do {
                try TariLib.shared.startExistingWallet()
                    DispatchQueue.main.async {
                        onComplete()
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

            Tracker.shared.track("/onboarding/create_wallet", "Onboarding - Create Wallet")

            if let _ = self.ticketTopLayoutConstraint {
                self.topAnimationAndRemoveVideoAnimation { [weak self] () in
                    guard let self = self else { return }
                    self.navigateToHome()
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.navigateToHome()
                }
            }
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Wallet error", comment: "Splash screen for new users"),
                description: NSLocalizedString("Failed to create a new wallet", comment: "Splash screen for new users"),
                error: error //TODO copy update
            )

            createWalletButton.variation = .normal
        }
    }

    private func checkExistingWallet() {
        if TariLib.shared.walletExists {
            //Authenticate user -> start animation -> wait for tor -> start wallet -> navigate to home
            authenticateUser {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                    guard let self = self else { return }
                    self.startAnimation {
                        self.onTorSuccess {
                            self.startExistingWallet {
                                self.navigateToHome()
                            }
                        }
                    }
                })
            }

        } else {
            //No wallet exists, setup for welcome splash screen
            setupVideoAnimation()
            titleLabel.isHidden = false
            //subtitleLabel.isHidden = false
            createWalletButton.isHidden = false
            disclaimerText.isHidden = false

            Tracker.shared.track("/onboarding/introduction", "Onboarding - Introduction")
        }
    }

    @objc func onCreateWalletTap() {
        createWalletButton.variation = .loading
        //TariLib.shared.startTor()
        onTorSuccess {
            self.createNewWallet()
        }
    }

    private func authenticateUser(onSuccess: @escaping () -> Void) {
        #if targetEnvironment(simulator)
        //Skip auth on simulator, quicker for development
        onSuccess()
        return
        #endif

        switch localAuthenticationContext.biometricType {
        case .faceID, .touchID, .pin:
            let policy: LAPolicy = localAuthenticationContext.biometricType == .pin ? .deviceOwnerAuthentication : .deviceOwnerAuthenticationWithBiometrics
            let reason = "Log in to your account"
            localAuthenticationContext.evaluatePolicy(policy, localizedReason: reason) {
                [weak self] success, error in

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if success {
                        if let _ = self.ticketTopLayoutConstraint {
                            self.topAnimationAndRemoveVideoAnimation { [weak self] () in
                                guard let _ = self else { return }
                                onSuccess()
                            }
                        } else {
                            DispatchQueue.main.async { [weak self] in
                                guard let _ = self else { return }
                                onSuccess()
                            }
                        }
                    } else {
                        let reason = error?.localizedDescription ?? NSLocalizedString("Failed to authenticate", comment: "Failed Face/Touch ID alert")
                        TariLogger.error("Biometrics auth failed", error: error)
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.authenticationFailedAlertOptions(reason: reason, onSuccess: onSuccess)
                        }
                    }
                }
            }
        case .none:
            let alert = UIAlertController(title: NSLocalizedString("Authentication Error", comment: "No biometric or passcode") ,
                                          message: NSLocalizedString("Tari Aurora was not able to authenticate you. Do you still want to proceed?", comment: "No biometric or passcode"),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Try again", comment: "Try again button"),
                                          style: .cancel,
                                          handler: { [weak self] _ in
                                            self?.authenticateUser(onSuccess: onSuccess)
            }))

            alert.addAction(UIAlertAction(title: NSLocalizedString("Proceed", comment: "Proceed button"), style: .default, handler: { _ in
                onSuccess()
            }))

            self.present(alert, animated: true, completion: nil)
        }
    }

    private func authenticationFailedAlertOptions(reason: String, onSuccess: @escaping () -> Void) {
        let alert = UIAlertController(title: NSLocalizedString("Authentication failed", comment: "Auth failed"), message: reason, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Try again", comment: "Try again button"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.authenticateUser(onSuccess: onSuccess)
        }))

        alert.addAction(UIAlertAction(title: NSLocalizedString("Open settings", comment: "Open settings button"), style: .default, handler: { [weak self] _ in
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

    func startAnimation(onComplete: @escaping () -> Void) {
        #if targetEnvironment(simulator)
          //animationContainer.animationSpeed = 5
        #endif

        animationContainer.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { [weak self] (_) in
                guard let _ = self else { return }
                onComplete()
            }
        )
    }

    private func navigateToHome() {
        if walletExistsInitially && authStepPassed {
            //Calling this here in case they did not succesfully register the token in the onboarding
            NotificationManager.shared.requestAuthorization()

            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            if let nav = storyboard.instantiateInitialViewController() as? UINavigationController {
                if let window = UIApplication.shared.windows.first {
                    let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
                    if let vc = nav.viewControllers.first {
                        vc.view.addSubview(overlayView)
                        window.rootViewController = nav
                        UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
                            overlayView.alpha = 0
                        }, completion: { _ in
                            overlayView.removeFromSuperview()
                        })
                    }
                }
            }
        } else {
            let vc = WalletCreationViewController()
            vc.startFromLocalAuth = !authStepPassed && walletExistsInitially

            vc.modalPresentationStyle = .fullScreen
            if let window = view.window {
                window.layer.add(Theme.shared.transitions.pullDownOpen, forKey: kCATransition)
                present(vc, animated: false, completion: nil)
            }
        }
    }
}
