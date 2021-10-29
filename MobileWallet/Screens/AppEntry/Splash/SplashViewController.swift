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
import Combine

class SplashViewController: UIViewController, UITextViewDelegate {

    private enum AnimationType {
        case scaleDownLogo
        case squashLetters
    }

    // MARK: - Variables and constants
    var player: AVQueuePlayer!
    var playerLayer: AVPlayerLayer!
    var playerItem: AVPlayerItem!
    var playerLooper: AVPlayerLooper!
    private let localAuthenticationContext = LAContext()
    var ticketTopLayoutConstraint: NSLayoutConstraint?
    var ticketBottom: NSLayoutConstraint?
    var alreadyReplacedVideo: Bool = false

    // MARK: - Outlets
    let generalContainer = UIView()
    let videoView = UIView()
    let versionLabel = UILabel()
    let animationContainer = AnimationView()
    let elementsContainer = UIView()
    let createWalletButton = ActionButton()
    let selectNetworkButton = ActionButton()
    let titleLabel = UILabel()
    let gemImageView = UIImageView()
    let disclaimerText = UITextView()
    let restoreButton = UIButton()

    var distanceTitleSubtitle = NSLayoutConstraint()
    var animationContainerBottomAnchor: NSLayoutConstraint?
    var animationContainerBottomAnchorToVideo: NSLayoutConstraint?
    private let progressFeedbackView = FeedbackView()

    private var cancelables = Set<AnyCancellable>()

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupFeedbacks()
        loadAnimation()
        handleWalletEvents()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupVideoAnimation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startOnboardingFlow(animationType: .squashLetters)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        SwiftEntryKit.dismiss()
    }

    private func startOnboardingFlow(animationType: AnimationType) {
        guard !TariSettings.shared.isUnitTesting else { return }
        titleAnimation()
        checkExistingWallet(animationType: animationType)
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

    private func setupFeedbacks() {
        NetworkManager.shared.$selectedNetwork
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.update(networkName: $0.name) }
            .store(in: &cancelables)
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

    private func prepareEnviroment(animationType: AnimationType) {

        let dispatchGroup = DispatchGroup()
        var error: Wallet.WalletError?

        dispatchGroup.enter()
        onTorSuccess { dispatchGroup.leave() }

        dispatchGroup.enter()
        waitForWalletStart(
            onComplete: { dispatchGroup.leave() },
            onError: {
                error = $0
                dispatchGroup.leave()
            }
        )

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let error = error else {
                self?.navigateToHome(animationType: animationType)
                return
            }

            let description: String

            switch error {
            case .databaseDataError:
                description = localized("splash.wallet_error.description.corrupted_database")
            default:
                description = localized("splash.wallet_error.description.generic")
            }
            
            UserFeedback.shared.callToAction(
                title: localized("splash.wallet_error.title"),
                description: description,
                actionTitle: localized("splash.wallet_error.button.confirm"),
                cancelTitle: localized("common.cancel"),
                onAction: { [weak self] in
                    TariLib.shared.deleteWallet()
                    self?.updateCreateWalletButtonState()
                    self?.startOnboardingFlow(animationType: .scaleDownLogo)
                })
        }
    }

    private func navigateToHome(animationType: AnimationType) {
        switch animationType {
        case .scaleDownLogo:
            topAnimationAndRemoveVideoAnimation { [weak self] in self?.navigateToHome() }
        case .squashLetters:
            startAnimation { [weak self] in self?.navigateToHome() }
        }
    }

    private func checkExistingWallet(animationType: AnimationType) {
        if TariLib.shared.isWalletExist {
            startWalletIfNeeded()
            // Authenticate user -> start animation -> wait for tor -> start wallet -> navigate to home
            localAuthenticationContext.authenticateUser {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.prepareEnviroment(animationType: animationType)
                }
            }
        } else {
            AppKeychainWrapper.removeBackupPasswordFromKeychain()
            videoView.isHidden = false
            titleLabel.isHidden = false
            createWalletButton.isHidden = false
            selectNetworkButton.isHidden = false
            disclaimerText.isHidden = false
            restoreButton.isHidden = false
            Tracker.shared.track("/onboarding/introduction", "Onboarding - Introduction")
        }
    }

    private func startWalletIfNeeded() {
        guard TariLib.shared.walletState == .notReady else { return }
        TariLib.shared.startWallet(seedWords: nil)
    }

    private func waitForWalletStart(onComplete: @escaping () -> Void, onError: ((Wallet.WalletError) -> Void)?) {

        var cancel: AnyCancellable?

        cancel = TariLib.shared.walletStatePublisher
            .receive(on: RunLoop.main)
            .sink { walletState in
                switch walletState {
                case .started:
                    cancel?.cancel()
                    onComplete()
                case let .startFailed(error):
                    cancel?.cancel()
                    onError?(error)
                case .notReady, .starting:
                    break
                }
            }

        cancel?.store(in: &cancelables)
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
                        self?.navigateToHome()
                    }
                } else {
                    self.navigateToHome()
                }
            } onError: { [weak self] _ in
                guard let self = self else { return }
                UserFeedback.shared.error(
                    title: localized("wallet.error.title"),
                    description: localized("wallet.error.create_new_wallet")
                )
                self.createWalletButton.variation = .normal
            }
            try TariLib.shared.createNewWallet(seedWords: nil)
        } catch {
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

        guard !TariLib.shared.isWalletExist else {
            startOnboardingFlow(animationType: .scaleDownLogo)
            return
        }

        onTorSuccess {
            self.createNewWallet()
        }
    }

    @objc func onSelectNetworkButtonTap() {

        let controller = UIAlertController(title: localized("splash.action_sheet.select_network.title"), message: localized("splash.action_sheet.select_network.description"), preferredStyle: .actionSheet)

        TariNetwork.all.forEach { [weak controller] network in
            controller?.addAction(UIAlertAction(title: network.name.capitalized, style: .default, handler: { _ in
                NetworkManager.shared.selectedNetwork = network
            }))
        }

        controller.addAction(UIAlertAction(title: localized("common.cancel"), style: .destructive, handler: nil))

        present(controller, animated: true)
    }

    @objc func onRestoreWalletTap() {
        let restoreWalletViewController = RestoreWalletViewController()
        navigationController?.pushViewController(restoreWalletViewController, animated: true)
    }

    func startAnimation(onComplete: (() -> Void)? = nil) {
        animationContainer.play { _ in onComplete?() }
    }

    private func navigateToHome() {

        switch TariSettings.shared.walletSettings.configationState {
        case .notConfigured:
            moveToOnboarding(startFromLocalAuth: false)
        case .initialized:
            moveToOnboarding(startFromLocalAuth: true)
        case .authorized, .ready:
            moveToWallet()
        }

        TariEventBus.unregister(self)
    }

    private func moveToWallet() {
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
    }

    private func moveToOnboarding(startFromLocalAuth: Bool) {
        let vc = WalletCreationViewController()
        vc.startFromLocalAuth = startFromLocalAuth
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

    private func update(networkName: String) {

        if let appVersion = AppInfo.appVersion, let buildVestion = AppInfo.buildVestion {
            versionLabel.text = "\(networkName.uppercased()) v\(appVersion) (b\(buildVestion))"
        }

        selectNetworkButton.setTitle(localized("splash.button.select_network", arguments: networkName.capitalized), for: .normal)
        updateCreateWalletButtonState()
    }
    
    private func updateCreateWalletButtonState() {
        let createWalletButtonTitle = TariLib.shared.isWalletExist ? localized("splash.button.open_wallet") : localized("splash.button.create_wallet")
        createWalletButton.setTitle(createWalletButtonTitle, for: .normal)
    }
}
