//  WalletCreationViewController.swift

/*
	Package MobileWallet
	Created by Gabriel Lupu on 29/01/2020
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

class WalletCreationViewController: UIViewController {
    typealias LottieAnimation = Animation.LottieAnimation

    // MARK: - States
    private enum WalletCreationState {
        case initial
        case createEmojiId
        case showEmojiId
        case localAuthentication
        case enableNotifications
    }

    // MARK: - Variables and constants
    var startFromLocalAuth: Bool = false

    private var state: WalletCreationState = .createEmojiId

    private var loadingCircle = AnimationView()

    private var stackView = UIStackView()
    private var stackViewCenterYConstraint: NSLayoutConstraint?

    private var numpadImageView = UIImageView()
    private let animationView = AnimationView()
    private var animationViewHeightConstraint: NSLayoutConstraint?
    private var animationViewWidthConstraint: NSLayoutConstraint?

    private let userEmojiContainer = EmoticonView()
    private let tapToSeeButtonContainer = UIView()

    private let firstLabel = TransitionLabel()
    private let secondLabel = TransitionLabel()
    private let thirdLabel = UILabel()

    private let continueButton = ActionButton()

    private var continueButtonConstraint: NSLayoutConstraint?
    private var continueButtonSecondShowConstraint: NSLayoutConstraint?
    private var continueButtonShowConstraint: NSLayoutConstraint?

    private let radialGradient: RadialGradientView = RadialGradientView(insideColor: Theme.shared.colors.accessAnimationViewShadow!, outsideColor: Theme.shared.colors.creatingWalletBackground!)

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        prepareSubviews(for: .initial)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if startFromLocalAuth {
            startFromAuth()
        } else {
            showInitialScreen()
        }
    }

    private func startFromAuth() {
        state = .localAuthentication
        prepareSubviews(for: .localAuthentication)
        showLocalAuthentication()
        Tracker.shared.track("/local_auth", "Local Authentication")
    }

    // MARK: - Actions

    private func hideSubviews(completion: (() -> Void)?) {
        let duration: TimeInterval = 1.0
        hideContinueButton()
        firstLabel.hideLabel(duration: duration)
        secondLabel.hideLabel(duration: duration)

        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.thirdLabel.alpha = 0.0
            self?.animationView.alpha = 0.0
            self?.numpadImageView.alpha = 0.0
            self?.userEmojiContainer.alpha = 0.0
            self?.tapToSeeButtonContainer.alpha = 0.0
            self?.view.layoutIfNeeded()
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                self.animationView.stop()
                self.stackView.setCustomSpacing(0, after: self.userEmojiContainer)
                self.stackView.setCustomSpacing(0, after: self.secondLabel)
                self.stackView.setCustomSpacing(0, after: self.animationView)
                self.stackViewCenterYConstraint?.constant = 0.0

                self.numpadImageView.isHidden = true
                self.userEmojiContainer.isHidden = true

                completion?()
        })
    }

    private func showContinueButton() {
        continueButtonConstraint?.isActive = false
        continueButtonShowConstraint?.isActive = true
        continueButtonSecondShowConstraint?.isActive = true

        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.continueButton.alpha = 1.0
            self?.view.layoutIfNeeded()
        }
    }

    private func hideContinueButton() {
        continueButton.hideButtonWithAlpha { [weak self] in
            self?.continueButtonShowConstraint?.isActive = false
            self?.continueButtonSecondShowConstraint?.isActive = false
            self?.continueButtonConstraint?.isActive = true
            self?.view.layoutIfNeeded()
        }
    }

    private func playLottieAnimation(_ animation: LottieAnimation, completion: ((Bool) -> Void)? = nil) {
        updateConstraintsAnimationView(animation: animation)
        animationView.animation = Animation.named(animation)
        animationView.alpha = 1.0
        animationView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: completion
        )
    }

    @objc public func tapToSeeButtonAction(_ sender: UIButton) {
        userEmojiContainer.expand()
        tapToExpandAction()
    }

    private func tapToExpandAction() {
        if self.state == .showEmojiId {
            showContinueButton()
            tapToSeeButtonContainer.alpha = 0.0
        }
    }

    @objc func onNavigateNext() {
        switch state {
        case .createEmojiId:
            hideSubviews { [weak self] in
                self?.prepareSubviews(for: .showEmojiId)
                self?.playLottieAnimation(.emojiWheel, completion: { [weak self] _ in
                    self?.updateConstraintsAnimationView(animation: .none)
                    self?.showYourEmoji()
                })
                Tracker.shared.track("/onboarding/create_emoji_id", "Onboarding - Create Emoji Id")
            }
        case .showEmojiId:
            hideSubviews { [weak self] in
                self?.prepareSubviews(for: .localAuthentication)
                self?.showLocalAuthentication()
            }
        case .localAuthentication:
            runAuth()
        case .enableNotifications:
            runNotificationRequest()
        case .initial: break
        }
    }

    private func runNotificationRequest() {
        NotificationManager.shared.requestAuthorization {_ in
            DispatchQueue.main.async {
                Tracker.shared.track("/onboarding/enable_push_notif", "Onboarding - Enable Push Notifications")

                let newNavigationController = AlwaysPoppableNavigationController()
                let homeViewController = HomeViewController()
                newNavigationController.setViewControllers([homeViewController], animated: false)

                if let window = UIApplication.shared.windows.first {
                    let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
                    homeViewController.view.addSubview(overlayView)
                    window.rootViewController = newNavigationController

                    UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
                        overlayView.alpha = 0
                    }, completion: { _ in
                        overlayView.removeFromSuperview()
                    })
                }
            }
        }
    }

    private func runAuth() {
        let context = LAContext()
        let reason = firstLabel.text ?? ""

        switch context.biometricType {
        case .faceID, .touchID, .pin:
            let policy: LAPolicy = context.biometricType == .pin ? .deviceOwnerAuthentication : .deviceOwnerAuthenticationWithBiometrics

            context.evaluatePolicy(policy, localizedReason: reason) {
                [weak self] success, _ in

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if success {
                        self.successAuth()
                        Tracker.shared.track("/onboarding/enable_local_auth", "Onboarding - Enable Local Authentication")
                    } else {
                        let alert = UIAlertController(title: NSLocalizedString("There was an error", comment: "Auth failed"),
                                                      message: "",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Try again", comment: "Try again button"),
                                                      style: .default,
                                                      handler: nil))

                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        case .none:
            let alert = UIAlertController(title: NSLocalizedString("Authentication Error", comment: "No biometric or passcode"),
                                          message: NSLocalizedString("Tari Aurora was not able to authenticate you. Do you still want to proceed?", comment: "No biometric or passcode"),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"),
                                          style: .cancel,
                                          handler: nil))

            alert.addAction(UIAlertAction(title: NSLocalizedString("Proceed", comment: "Proceed button"), style: .default, handler: { [weak self] _ in
                self?.successAuth()
            }))

            self.present(alert, animated: true, completion: nil)
        }
    }

    private func successAuth() {
        UserDefaults.standard.set(true, forKey: "authStepPassed")
        hideSubviews { [weak self] in
            self?.prepareSubviews(for: .enableNotifications)
            self?.showEnableNotifications()
        }
    }
}

// MARK: - Starting states
extension WalletCreationViewController {

    // MARK: - Show Initial
    private func showInitialScreen() {
        loadingCircle.alpha = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.firstLabel.showLabel()
            self?.secondLabel.showLabel()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.hideSubviews(completion: {
                DispatchQueue.main.async { [weak self] in
                    self?.playLottieAnimation(.checkMark, completion: { [weak self] _ in
                        self?.updateConstraintsAnimationView(animation: .none)
                        self?.showCreateYourEmojiIdScreen()
                    })
                    UIView.animate(withDuration: 0.5, animations: { [weak self] in
                        self?.loadingCircle.alpha = 0.0
                        self?.view.layoutIfNeeded()
                    })
                }
            })
        }
    }

    // MARK: - Create Your Emoji ID
    private func showCreateYourEmojiIdScreen() {
        prepareSubviews(for: .createEmojiId)

        playLottieAnimation(.nerdEmoji)
        firstLabel.showLabel(duration: 1.0)
        secondLabel.showLabel(duration: 1.0)
        view.layoutIfNeeded()

        showContinueButton()

        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.thirdLabel.alpha = 1.0
        })
    }

    // MARK: - Show Emoji ID
    private func showYourEmoji() {
        secondLabel.showLabel(duration: 1.0)
        userEmojiContainer.isHidden = false
        view.layoutIfNeeded()

        UIView.animate(withDuration: 1, animations: { [weak self] in
            self?.thirdLabel.alpha = 1.0
            self?.userEmojiContainer.alpha = 1.0
        }) { [weak self] (_) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.userEmojiContainer.shrink(completion: { [weak self] in
                    self?.tapToSeeButtonContainer.alpha = 1.0
                })
            }
            self?.state = .showEmojiId
        }
    }

    // MARK: - Show Local Auth
    private func showLocalAuthentication() {
        showContinueButton()

        let currentType = LAContext().biometricType
        switch currentType {
        case .faceID:
            playLottieAnimation(.faceID)
        case .touchID:
            playLottieAnimation(.touchID)
        case .pin, .none:
            numpadImageView.isHidden = false
            UIView.animate(withDuration: 1.0) { [weak self] in
                self?.numpadImageView.alpha = 1.0
            }
        }

        secondLabel.showLabel(duration: 1.0)
        view.layoutIfNeeded()

        UIView.animate(withDuration: 1, animations: { [weak self] in
            self?.radialGradient.alpha = 0.2
            self?.thirdLabel.alpha = 1.0
            self?.view.layoutIfNeeded()
        }) { [weak self] (_) in
            self?.state = .localAuthentication
        }
    }

    // MARK: - Show Enable Notifications
    private func showEnableNotifications() {
        playLottieAnimation(.notification)
        firstLabel.showLabel(duration: 1.0)
        secondLabel.showLabel(duration: 1.0)
        view.layoutIfNeeded()

        showContinueButton()

        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.thirdLabel.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.state = .enableNotifications
        }
    }

}

// MARK: - Preparing subviews for next state
extension WalletCreationViewController {

    private func prepareSubviews(for state: WalletCreationState) {
        switch state {
        case .initial: prepareForInitialState()
        case .createEmojiId: prepareForCreateEmojiId()
        case .showEmojiId: prepareForShowEmojiID()
        case .localAuthentication: prepareForLocalAuthentication()
        case .enableNotifications: prepareForEnableNotifications()
        }
    }

    private func prepareForInitialState() {
        updateConstraintsAnimationView(animation: .none)
        firstLabel.text = NSLocalizedString("Hold on a sec…", comment: "Second label on wallet creation Top")
        secondLabel.text = NSLocalizedString("We’re creating your wallet.", comment: "Second label on wallet creation Bottom")
        continueButton.setTitle(NSLocalizedString("Create Your Emoji ID", comment: "Create button on wallet creation"), for: .normal)
    }

    private func prepareForCreateEmojiId() {
        firstLabel.text = NSLocalizedString("We’re off to a great start!", comment: "Second label on wallet creation Top")
        secondLabel.text = NSLocalizedString("Now, let’s create your Emoji ID.", comment: "Second label on wallet creation Bottom")
        thirdLabel.text = String(
            format: NSLocalizedString(
                "Your Emoji ID is your wallet address.\n It’s how your friends can find you and send you %@!",
                comment: "Third label on wallet creation"
            ),
            TariSettings.shared.network.currencyDisplayTicker
        )

        stackView.setCustomSpacing(16, after: secondLabel)
    }

    private func prepareForShowEmojiID() {
        let thisIsYourEmojiString = NSLocalizedString("This is your Emoji ID", comment: "Splash show your emoji ID")
        let attributedString = NSMutableAttributedString(string: thisIsYourEmojiString, attributes: [
            .font: Theme.shared.fonts.createWalletEmojiIDFirstText!,
            .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel!,
            .kern: -0.33
        ])
        attributedString.addAttribute(.font, value: Theme.shared.fonts.createWalletEmojiIDSecondText!, range: NSRange(location: 13, length: 8))
        secondLabel.attributedText = attributedString

        let curency = TariSettings.shared.network.currencyDisplayTicker
        thirdLabel.text = NSLocalizedString(
            "Your Emoji ID is your wallet’s address, and how others can find you and send you \(curency)!", comment: "Emoji Id third label on wallet creation")
        stackView.setCustomSpacing(16, after: secondLabel)

        continueButton.setTitle(NSLocalizedString("Continue", comment: "This is your emoji screen on wallet creation"), for: .normal)

        if let pubKey = TariLib.shared.tariWallet?.publicKey.0 {
            userEmojiContainer.setUpView(
                pubKey: pubKey,
                type: .buttonView,
                textCentered: true,
                inViewController: self,
                showContainerViewBlur: false
            )
            self.userEmojiContainer.expand(animated: false)
            self.userEmojiContainer.tapToExpand = { [weak self] expanded in
                if self?.state == .showEmojiId {
                    self?.showContinueButton()
                    UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
                        self?.tapToSeeButtonContainer.alpha = expanded ? 0.0 : 1.0
                    }
                }
            }
        }

        stackView.setCustomSpacing(30, after: userEmojiContainer)
    }

    private func prepareForLocalAuthentication() {
        let secondLabelString = NSLocalizedString("🔑 Let’s secure your wallet. 🔑", comment: "Splash face/touch ID")
        let attributedString = NSMutableAttributedString(string: secondLabelString, attributes: [
            .font: Theme.shared.fonts.createWalletEmojiIDSecondText!,
            .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel!,
            .kern: -0.33
        ])
        self.secondLabel.attributedText = attributedString

        self.thirdLabel.text = String(
            format: NSLocalizedString(
                "Sleep well at night knowing you’ve taken precautions to keep your %@ wallet safe and sound.",
                comment: "Face ID third label on wallet creation"
            ),
            TariSettings.shared.network.currencyDisplayTicker
        )
        stackView.setCustomSpacing(16, after: secondLabel)
        stackViewCenterYConstraint?.constant = -85
        view.layoutIfNeeded()

        let currentType = LAContext().biometricType
        switch currentType {
        case .faceID:
            stackView.setCustomSpacing(54, after: animationView)
            self.continueButton.setTitle(NSLocalizedString("Secure with Face ID", comment: "Enable authentication on wallet creation"), for: .normal)
        case .touchID:
            stackView.setCustomSpacing(58, after: animationView)
            self.continueButton.setTitle(NSLocalizedString("Secure with Touch ID", comment: "Enable authentication on wallet creation"), for: .normal)
        case .pin, .none:
            stackView.setCustomSpacing(5, after: numpadImageView)
            self.continueButton.setTitle(NSLocalizedString("Secure with Pin", comment: "Enable authentication on wallet creation"), for: .normal)
        }
    }

    private func prepareForEnableNotifications() {
        let secondLabelStringTop = NSLocalizedString("Don’t miss out when people", comment: "Splash EnableNotifications")
        let secondLabelStringBottom = NSLocalizedString("send you money.", comment: "Splash EnableNotifications")
        firstLabel.font = Theme.shared.fonts.createWalletNotificationsFirstLabel
        secondLabel.font = Theme.shared.fonts.createWalletNotificationsSecondLabel
        firstLabel.text = secondLabelStringTop
        secondLabel.text = secondLabelStringBottom
        thirdLabel.font = Theme.shared.fonts.createWalletNotificationsThirdLabel
        thirdLabel.text = NSLocalizedString("Enable push notifications to keep tabs on your payments.", comment: "Create Wallet enable Notifications screen")

        continueButton.setTitle(NSLocalizedString("Turn on Notifications", comment: "Create Wallet Turn on Notifications"), for: .normal)

        stackViewCenterYConstraint?.constant = -90
        stackView.setCustomSpacing(16, after: secondLabel)
    }
}

// MARK: - Setup subviews
extension WalletCreationViewController {

    private func setupView() {
        setupStackView()
        setupTapToSeeFullEmojiButton()
        setupRadialGradientView()
        setupContinueButton()
        setupPendingAnimation()

        view.backgroundColor = Theme.shared.colors.creatingWalletBackground
    }

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .center

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackViewCenterYConstraint = stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0)
        stackViewCenterYConstraint?.isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25).isActive = true

        setupUserEmojiContainer()
        setupNumpadImageView()
        setupAnimationView()
        setupFirstLabel()
        setupSecondLabel()
        setupThirdLabel()
    }

    private func setupUserEmojiContainer() {
        userEmojiContainer.alpha = 0.0
        userEmojiContainer.isHidden = true
        stackView.addArrangedSubview(userEmojiContainer)
        stackView.setCustomSpacing(30, after: userEmojiContainer)
        userEmojiContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        userEmojiContainer.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    }

    private func setupAnimationView() {
        animationView.backgroundBehavior = .pauseAndRestore

        stackView.addArrangedSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationViewWidthConstraint = animationView.widthAnchor.constraint(equalToConstant: 0)
        animationViewHeightConstraint = animationView.heightAnchor.constraint(equalToConstant: 0)

        animationViewWidthConstraint?.isActive = true
        animationViewHeightConstraint?.isActive = true
    }

    private func setupFirstLabel() {
        firstLabel.font = Theme.shared.fonts.createWalletSecondLabelFirstText
        stackView.addArrangedSubview(firstLabel)
    }

    private func setupSecondLabel() {
        secondLabel.font = Theme.shared.fonts.createWalletSecondLabelSecondText
        stackView.addArrangedSubview(secondLabel)
    }

    private func setupThirdLabel() {
        thirdLabel.alpha = 0.0
        thirdLabel.font = Theme.shared.fonts.createWalletThirdLabel
        thirdLabel.textColor = Theme.shared.colors.creatingWalletThirdLabel
        thirdLabel.textAlignment = .center
        thirdLabel.numberOfLines = 0
        stackView.addArrangedSubview(thirdLabel)
    }

    private func setupPendingAnimation() {
        loadingCircle.backgroundBehavior = .pauseAndRestore
        loadingCircle.animation = Animation.named(.pendingCircleAnimation)
        loadingCircle.alpha = 0.0

        view.addSubview(loadingCircle)
        loadingCircle.translatesAutoresizingMaskIntoConstraints = false
        loadingCircle.widthAnchor.constraint(equalToConstant: 45).isActive = true
        loadingCircle.heightAnchor.constraint(equalToConstant: 45).isActive = true
        loadingCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loadingCircle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true

        loadingCircle.play(fromProgress: 0, toProgress: 1, loopMode: .loop)
    }

    private func updateConstraintsAnimationView(animation: LottieAnimation) {
        switch animation {
        case .none:
            animationViewWidthConstraint?.constant = 0.0
            animationViewHeightConstraint?.constant = 0.0
        case .checkMark:
            animationViewWidthConstraint?.constant = 43.75
            animationViewHeightConstraint?.constant = 30.0
        case .faceID, .touchID:
            animationViewWidthConstraint?.constant = 138
            animationViewHeightConstraint?.constant = 138
        case .notification:
            animationViewWidthConstraint?.constant = 220
            animationViewHeightConstraint?.constant = 250
        case .emojiWheel:
            animationViewWidthConstraint?.constant = stackView.bounds.width
            animationViewHeightConstraint?.constant = stackView.bounds.width
        case .nerdEmoji:
            animationViewWidthConstraint?.constant = 55.0
            animationViewHeightConstraint?.constant = 55.0

        default: break
        }

        view.layoutIfNeeded()
    }

    private func setupContinueButton() {
        continueButton.addTarget(self, action: #selector(onNavigateNext), for: .touchUpInside)
        continueButton.alpha = 0.0
        view.addSubview(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                constant: Theme.shared.sizes.appSidePadding).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                 constant: -Theme.shared.sizes.appSidePadding).isActive = true
        continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                                constant: 0).isActive = true

        continueButtonConstraint = continueButton.topAnchor.constraint(equalTo: view.bottomAnchor)
        continueButtonShowConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        continueButtonShowConstraint?.priority = UILayoutPriority(rawValue: 999)

        continueButtonSecondShowConstraint = continueButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        continueButtonSecondShowConstraint?.priority = UILayoutPriority(rawValue: 1000)

        continueButtonConstraint?.isActive = true
    }

    private func setupRadialGradientView() {
        radialGradient.alpha = 0.0
        view.insertSubview(radialGradient, belowSubview: stackView)
        radialGradient.translatesAutoresizingMaskIntoConstraints = false
        radialGradient.widthAnchor.constraint(equalTo: animationView.widthAnchor, multiplier: 1.3).isActive = true
        radialGradient.heightAnchor.constraint(equalTo: animationView.heightAnchor, multiplier: 1.3).isActive = true

        radialGradient.centerYAnchor.constraint(equalTo: animationView.centerYAnchor).isActive = true
        radialGradient.centerXAnchor.constraint(equalTo: animationView.centerXAnchor).isActive = true
    }

    private func setupNumpadImageView() {
        numpadImageView.image = Theme.shared.images.createWalletNumpad!
        numpadImageView.isHidden = true
        numpadImageView.alpha = 0.0
        stackView.addArrangedSubview(numpadImageView)
        numpadImageView.translatesAutoresizingMaskIntoConstraints = false
        numpadImageView.widthAnchor.constraint(equalToConstant: 213).isActive = true
        numpadImageView.heightAnchor.constraint(equalToConstant: 232).isActive = true
    }

    private func setupTapToSeeFullEmojiButton() {
        tapToSeeButtonContainer.backgroundColor = .clear
        tapToSeeButtonContainer.alpha = 0.0
        view.addSubview(tapToSeeButtonContainer)

        tapToSeeButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        tapToSeeButtonContainer.bottomAnchor.constraint(equalTo: userEmojiContainer.topAnchor, constant: 3).isActive = true
        tapToSeeButtonContainer.widthAnchor.constraint(equalToConstant: 159).isActive = true
        tapToSeeButtonContainer.heightAnchor.constraint(equalToConstant: 38).isActive = true
        tapToSeeButtonContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true

        let button = UIButton()
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.backgroundColor = Theme.shared.colors.tapToSeeFullEmojiBackground!
        button.setTitle(NSLocalizedString("Tap to see full Emoji ID", comment: "Tap to see full Emoji ID in wallet creation"), for: .normal)
        button.addTarget(self, action: #selector(tapToSeeButtonAction(_ :)), for: .touchUpInside)
        button.setTitleColor(Theme.shared.colors.tapToSeeFullEmoji!, for: .normal)
        button.titleLabel?.font = Theme.shared.fonts.tapToSeeFullEmojiLabel!

        tapToSeeButtonContainer.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false

        button.topAnchor.constraint(equalTo: tapToSeeButtonContainer.topAnchor).isActive = true
        button.widthAnchor.constraint(equalTo: tapToSeeButtonContainer.widthAnchor).isActive = true
        button.heightAnchor.constraint(equalToConstant: 33).isActive = true
        button.centerXAnchor.constraint(equalTo: tapToSeeButtonContainer.centerXAnchor).isActive = true

        let arrow = UIImageView()
        arrow.image = Theme.shared.images.createWalletDownArrow!
        tapToSeeButtonContainer.addSubview(arrow)

        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.topAnchor.constraint(equalTo: button.bottomAnchor).isActive = true
        arrow.widthAnchor.constraint(equalToConstant: 7).isActive = true
        arrow.heightAnchor.constraint(equalToConstant: 5).isActive = true
        arrow.centerXAnchor.constraint(equalTo: button.centerXAnchor, constant: 0).isActive = true
    }
}
