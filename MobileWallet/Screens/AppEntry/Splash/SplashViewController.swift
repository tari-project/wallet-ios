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
    let generalContainer = UIView()
    let videoView = UIView()
    let versionLabel = UILabel()
    let animationContainer = AnimationView()
    let elementsContainer = UIView()
    let createWalletButton = ActionButton()
    let titleLabel = UILabel()
    let gemImageView = UIImageView()
    let disclaimerText = UITextView()
    let restoreButton = UIButton()

    var distanceTitleSubtitle = NSLayoutConstraint()
    var animationContainerBottomAnchor: NSLayoutConstraint?
    var animationContainerBottomAnchorToVideo: NSLayoutConstraint?
    private let progressFeedbackView = FeedbackView()
    private lazy var authStepPassed: Bool = {
        UserDefaults.Key.authStepPassed.boolValue()
    }()

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadAnimation()
        handleWalletEvents()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupVideoAnimation()
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
        // Handle tor progress
        TariEventBus.onMainThread(self, eventType: .torConnectionProgress) {
            [weak self] (result) in
            guard let self = self else { return }

            if let progress: Int = result?.object as? Int {
                if progress == 0 {
                    var attributes = EKAttributes.topToast
                    attributes.entryBackground = .color(color: EKColor(Theme.shared.colors.successFeedbackPopupBackground!))
                    attributes.screenBackground = .clear
                    attributes.shadow = .active(
                        with: .init(
                            color: EKColor(Theme.shared.colors.feedbackPopupBackground!),
                            opacity: 0.35,
                            radius: 10,
                            offset: .zero
                        )
                    )
                    attributes.displayDuration = .infinity
                    attributes.screenInteraction = .forward
                }
                self.progressFeedbackView.setupSuccess(title: "Tor bootstrapping: \(progress)%")
            }
        }

        // Handle on tor connected
        TariEventBus.onMainThread(self, eventType: .torConnected) { [weak self] (_) in
            guard let self = self else { return }
            self.progressFeedbackView.setupSuccess(title: "Tor connection established")
        }

        TariEventBus.onMainThread(self, eventType: .torConnectionFailed) { [weak self] (result) in
            guard let _ = self else { return }

            let error: Error? = result?.object as? Error

            UserFeedback.shared.error(
                title: localized("tor.error.title"),
                description: localized("tor.error.description"),
                error: error
            )
        }
    }

    private func onTorSuccess(_ onComplete: @escaping () -> Void) {
        // Handle if tor ports opened later
        TariEventBus.onMainThread(self, eventType: .torPortsOpened) { [weak self] (_) in
            guard let self = self else { return }
            TariEventBus.unregister(self, eventType: .torPortsOpened)
            onComplete()
        }
        if TariLib.shared.torPortsOpened {
            TariEventBus.unregister(self, eventType: .torPortsOpened)
            onComplete()
        }
    }

    private func checkExistingWallet() {
        if TariLib.shared.walletExists {
            // Authenticate user -> start animation -> wait for tor -> start wallet -> navigate to home
            localAuthenticationContext.authenticateUser {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1,
                    execute: {
                        [weak self] in
                        guard let self = self else { return }
                        self.startAnimation {
                            self.onTorSuccess {
                                self.waitForWalletStart {
                                    self.navigateToHome()
                                }
                            }
                        }
                    }
                )
            }
        } else {
            AppKeychainWrapper.removeBackupPasswordFromKeychain()
            videoView.isHidden = false
            titleLabel.isHidden = false
            createWalletButton.isHidden = false
            disclaimerText.isHidden = false
            restoreButton.isHidden = false
            Tracker.shared.track("/onboarding/introduction", "Onboarding - Introduction")
        }
    }

    private func waitForWalletStart(onComplete: @escaping () -> Void, onError: (() -> Void)? = nil) {
        if TariLib.shared.walletState != .started {
            TariEventBus.onMainThread(self, eventType: .walletStateChanged) {
                [weak self]
                (sender) in
                guard let self = self else { return }
                let walletState = sender!.object as! TariLib.WalletState
                switch walletState {
                case .started:
                    TariEventBus.unregister(self, eventType: .walletStateChanged)
                    onComplete()
                case .startFailed:
                    TariEventBus.unregister(self, eventType: .walletStateChanged)
                    onError?()
                default:
                    break
                }
            }
        } else {
            onComplete()
        }
    }

    private func createWalletBackup() {
        if ICloudBackup.shared.iCloudBackupsIsOn && !ICloudBackup.shared.isValidBackupExists() {
            do {
                let password = AppKeychainWrapper.loadBackupPasswordFromKeychain()
                try ICloudBackup.shared.createWalletBackup(password: password)
            } catch {
                var title = localized("iCloud_backup.error.title.create_backup")

                if let localizedError = error as? LocalizedError, localizedError.failureReason != nil {
                   title = localizedError.failureReason!
                }
                UserFeedback.shared.error(title: title, description: error.localizedDescription, error: nil)
            }
        }
    }

    private func createNewWallet() {
        do {
            waitForWalletStart {
                [weak self] in
                guard let self = self else { return }
                Tracker.shared.track(
                    "/onboarding/create_wallet",
                    "Onboarding - Create Wallet"
                )
                if let _ = self.ticketTopLayoutConstraint {
                    self.topAnimationAndRemoveVideoAnimation { [weak self] () in
                        guard let self = self else { return }
                        self.navigateToHome()
                    }
                }
            } onError: {
                [weak self] in
                guard let self = self else { return }
                UserFeedback.shared.error(
                    title: localized("wallet.error.title"),
                    description: localized("wallet.error.create_new_wallet")
                )
                self.createWalletButton.variation = .normal
            }
            try TariLib.shared.createNewWallet(seedWords: nil)
        } catch {
            TariEventBus.unregister(self, eventType: .walletStateChanged)
            UserFeedback.shared.error(
                title: localized("wallet.error.title"),
                description: localized("wallet.error.create_new_wallet"),
                error: error
            )
            createWalletButton.variation = .normal
        }
    }

    @objc func onCreateWalletTap() {
        createWalletButton.variation = .loading
        onTorSuccess {
            self.createNewWallet()
        }
    }

    @objc func onRestoreWalletTap() {
        let restoreWalletViewController = RestoreWalletViewController()
        navigationController?.pushViewController(restoreWalletViewController, animated: true)
    }

    func startAnimation(onComplete: @escaping () -> Void) {
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
            // Calling this here in case they did not succesfully register the token in the onboarding
            NotificationManager.shared.requestAuthorization()

            let nav = AlwaysPoppableNavigationController()
            let tabBarController = MenuTabBarController()
            nav.setViewControllers([tabBarController], animated: false)

            if let window = UIApplication.shared.keyWindow {
                let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
                tabBarController.view.addSubview(overlayView)
                window.rootViewController = nav

                UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
                    overlayView.alpha = 0
                }, completion: { _ in
                    overlayView.removeFromSuperview()
                })
            }
        } else {
            let vc = WalletCreationViewController()
            vc.startFromLocalAuth = !authStepPassed && walletExistsInitially
            if let window = view.window {
                let transition: CATransition = CATransition()
                transition.duration = 0.5
                transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                transition.type = CATransitionType.push
                transition.subtype = CATransitionSubtype.fromTop

                window.layer.add(Theme.shared.transitions.pullDownOpen, forKey: kCATransition)
                navigationController?.view.layer.add(transition, forKey: kCATransition)
                navigationController?.pushViewController(vc, animated: false)
            }
        }

        TariEventBus.unregister(self)
    }

}
