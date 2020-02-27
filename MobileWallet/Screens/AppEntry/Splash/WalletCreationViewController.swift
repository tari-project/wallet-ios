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

enum WalletCreationState {
    case createEmojiId
    case showEmojiId
    case localAuthentification
    case enableNotifications
}

class WalletCreationViewController: UIViewController {
    // MARK: - Variables and constants
    var state: WalletCreationState = .createEmojiId
    // MARK: - Outlets
    var createEmojiButtonConstraint: NSLayoutConstraint?
    var createEmojiButtonSecondConstraint: NSLayoutConstraint?
    var firstLabelTopConstraint: NSLayoutConstraint?
    var firstLabel: UILabel!
    var secondLabel: UILabel!
    var thirdLabel: UILabel!
    var topWhiteView: UIView!
    var bottomWhiteView: UIView!
    var animationView: AnimationView!
    var emojiWheelView: AnimationView!
    var nerdAnimationView: AnimationView!
    var createEmojiButton: ActionButton!
    var topImageView: UIImageView!
    var userEmojiContainer: EmoticonView!
    var localAuthentificationImageView: UIImageView!

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstLabelAnimation()
    }

    // MARK: - Private functions

    private func updateConstraintsTopWhiteView() {
        topWhiteView = UIView()
        topWhiteView.backgroundColor = Theme.shared.colors.creatingWalletBackground
        view.addSubview(topWhiteView)
        topWhiteView.translatesAutoresizingMaskIntoConstraints = false
        topWhiteView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 0).isActive = true
        topWhiteView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: 0).isActive = true
        topWhiteView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                          constant: 0).isActive = true
    }

    private func updateConstraintsNerdAnimationView() {
        nerdAnimationView = AnimationView()
        view.addSubview(nerdAnimationView)
        nerdAnimationView.translatesAutoresizingMaskIntoConstraints = false
        nerdAnimationView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        nerdAnimationView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        nerdAnimationView.heightAnchor.constraint(equalToConstant: 80).isActive = true
    }

    private func updateConstraintsFirstLabel() {
        firstLabel = UILabel()
        firstLabel.numberOfLines = 1
        firstLabel.textAlignment = .center
        view.addSubview(firstLabel)
        firstLabel.translatesAutoresizingMaskIntoConstraints = false
        firstLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
    }

    private func updateConstraintsSecondLabel() {
        secondLabel = UILabel()
        secondLabel.numberOfLines = 0
        secondLabel.alpha = 0.0
        secondLabel.textAlignment = .center
        view.addSubview(secondLabel)
        secondLabel.translatesAutoresizingMaskIntoConstraints = false
        secondLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        secondLabel.topAnchor.constraint(equalTo: nerdAnimationView.bottomAnchor, constant: 0).isActive = true
    }

    private func updateConstraintsAnimationView() {
        animationView = AnimationView()
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        animationView.widthAnchor.constraint(equalToConstant: 35).isActive = true
        animationView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        animationView.topAnchor.constraint(equalTo: secondLabel.topAnchor, constant: 0).isActive = true
    }

    private func updateConstraintsBottomWhiteView() {
        bottomWhiteView = UIView()
        view.addSubview(bottomWhiteView)
        bottomWhiteView.backgroundColor = Theme.shared.colors.creatingWalletBackground
        bottomWhiteView.translatesAutoresizingMaskIntoConstraints = false
        bottomWhiteView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 0).isActive = true
        bottomWhiteView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: 0).isActive = true
        bottomWhiteView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -52).isActive = true
        bottomWhiteView.topAnchor.constraint(equalTo: topWhiteView.bottomAnchor, constant: 0).isActive = true
        bottomWhiteView.topAnchor.constraint(equalTo: secondLabel.bottomAnchor, constant: 0).isActive = true

        firstLabelTopConstraint = firstLabel.topAnchor.constraint(equalTo: bottomWhiteView.topAnchor, constant: 8)
        firstLabelTopConstraint?.isActive = true

        bottomWhiteView.heightAnchor.constraint(equalTo: topWhiteView.heightAnchor, multiplier: 1).isActive = true

    }

    func updateConstraintsThirdLabel() {
        thirdLabel = UILabel()
        thirdLabel.numberOfLines = 0
        thirdLabel.alpha = 0.0
        thirdLabel.textAlignment = .center
        view.addSubview(thirdLabel)
        thirdLabel.translatesAutoresizingMaskIntoConstraints = false
        thirdLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                            constant: 0).isActive = true
        thirdLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Theme.shared.sizes.appSidePadding).isActive = true
        thirdLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Theme.shared.sizes.appSidePadding).isActive = true
        thirdLabel.topAnchor.constraint(equalTo: secondLabel.bottomAnchor, constant: 18).isActive = true
    }

    private func updateConstraintsEmojiButton() {
        createEmojiButton = ActionButton()
        createEmojiButton.addTarget(self, action: #selector(navigateToHome), for: .touchUpInside)
        createEmojiButton.alpha = 0.0
        view.addSubview(createEmojiButton)
        createEmojiButton.translatesAutoresizingMaskIntoConstraints = false
        createEmojiButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Theme.shared.sizes.appSidePadding).isActive = true
        createEmojiButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Theme.shared.sizes.appSidePadding).isActive = true
        createEmojiButton.centerXAnchor.constraint(equalTo: view.centerXAnchor,
        constant: 0).isActive = true
        createEmojiButtonConstraint = createEmojiButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 70)
        createEmojiButtonConstraint?.isActive = true
        createEmojiButtonConstraint?.priority = UILayoutPriority(rawValue: 999)

        createEmojiButtonSecondConstraint = view.bottomAnchor.constraint(greaterThanOrEqualTo: createEmojiButton.bottomAnchor, constant: 20)
        createEmojiButtonSecondConstraint?.priority = UILayoutPriority(rawValue: 1000)
        createEmojiButtonSecondConstraint?.isActive = false

    }

    private func updateConstraintsTopImageView() {
        topImageView = UIImageView()
        view.addSubview(topImageView)
        topImageView.translatesAutoresizingMaskIntoConstraints = false
        topImageView.image = Theme.shared.images.currencySymbol//UIImage(named: "Gem")
        topImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                              constant: 0).isActive = true
        topImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        topImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        topImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 70).isActive = true
    }

    private func updateConstraintsEmojiWheelView() {
        emojiWheelView = AnimationView()
        view.addSubview(emojiWheelView)
        emojiWheelView.translatesAutoresizingMaskIntoConstraints = false
        emojiWheelView.centerXAnchor.constraint(equalTo: view.centerXAnchor,
        constant: 0).isActive = true
        emojiWheelView.centerYAnchor.constraint(equalTo: view.centerYAnchor,
        constant: 0).isActive = true
        emojiWheelView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 0).isActive = true
        emojiWheelView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: 0).isActive = true
        emojiWheelView.widthAnchor.constraint(equalTo: emojiWheelView.heightAnchor, multiplier: 1.0/1.0).isActive = true

    }

    private func updateConstraintsLocalAuthentificationImageView() {
        localAuthentificationImageView = UIImageView()
        localAuthentificationImageView.alpha = 0.0
        view.addSubview(localAuthentificationImageView)
        localAuthentificationImageView.translatesAutoresizingMaskIntoConstraints = false
        localAuthentificationImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        localAuthentificationImageView.widthAnchor.constraint(equalToConstant: 138).isActive = true
        localAuthentificationImageView.heightAnchor.constraint(equalToConstant: 138).isActive = true
        firstLabel.topAnchor.constraint(equalTo: localAuthentificationImageView.bottomAnchor, constant: 20).isActive = true
    }

    private func updateConstraintsUserEmojiContainer() {
        userEmojiContainer = EmoticonView()
        userEmojiContainer.alpha = 0.0
        view.addSubview(userEmojiContainer)
        userEmojiContainer.translatesAutoresizingMaskIntoConstraints = false
        userEmojiContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Theme.shared.sizes.appSidePadding).isActive = true
        userEmojiContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Theme.shared.sizes.appSidePadding).isActive = true
        secondLabel.topAnchor.constraint(equalTo: userEmojiContainer.bottomAnchor, constant: 20).isActive = true
        userEmojiContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
    }

    private func setupView() {
        updateConstraintsTopWhiteView()
        updateConstraintsNerdAnimationView()
        updateConstraintsFirstLabel()
        updateConstraintsSecondLabel()
        updateConstraintsAnimationView()
        updateConstraintsBottomWhiteView()
        updateConstraintsThirdLabel()
        updateConstraintsEmojiButton()
        updateConstraintsTopImageView()
        updateConstraintsEmojiWheelView()
        updateConstraintsLocalAuthentificationImageView()
        updateConstraintsUserEmojiContainer()

        firstLabel.text = NSLocalizedString("Hello Friend", comment: "First label on wallet creation")
        firstLabel.font = Theme.shared.fonts.createWalletFirstLabel
        firstLabel.textColor = Theme.shared.colors.creatingWalletFirstLabel

        thirdLabel.text = NSLocalizedString("Your Emoji ID is your wallet address.\n It’s how your friends can find you and send you Tari.", comment: "Third label on wallet creation")
        thirdLabel.font = Theme.shared.fonts.createWalletThirdLabel
        thirdLabel.textColor = Theme.shared.colors.creatingWalletThirdLabel

        let secondLabelString = NSLocalizedString("Just a sec…\nYour wallet is being created", comment: "Second label on wallet creation")
        let attributedString = NSMutableAttributedString(string: secondLabelString,
                                                         attributes: [
                                                            .font: Theme.shared.fonts.createWalletSecondLabelSecondText!,
                                                            .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel!,
          .kern: -0.33
        ])

        let splitString = secondLabelString.components(separatedBy: "\n")
        if splitString.count > 0 {
            let length = splitString[0].count
            attributedString.addAttribute(.font,
                                          value: Theme.shared.fonts.createWalletSecondLabelFirstText!,
                                          range: NSRange(location: 0, length: length))

            secondLabel.attributedText = attributedString
        }

        createEmojiButton.setTitle(NSLocalizedString("Continue & Create Emoji ID", comment: "Create button on wallet creation"), for: .normal)

        topImageView.image = topImageView.image?.withRenderingMode(.alwaysTemplate)
        topImageView.tintColor = .black

        self.view.backgroundColor = Theme.shared.colors.creatingWalletBackground
    }

    private func firstLabelAnimation() {
        firstLabelTopConstraint?.constant = -50.0

        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        }) { (_) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self else { return }
                self.removeFirstLabelAnimation()
            }
        }
    }

    private func removeFirstLabelAnimation() {
        UIView.animate(withDuration: 2, animations: { [weak self] in
            guard let self = self else { return }
            self.firstLabel.alpha = 0.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.displaySecondLabelAnimation()
        }
    }

    private func displaySecondLabelAnimation() {
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabel.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self else { return }
                self.removeSecondLabelAnimation()
            }
        }
    }

    private func removeSecondLabelAnimation() {
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabel.alpha = 0.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            let secondLabelString = NSLocalizedString("Awesome!\nNow create your Emoji ID", comment: "Second label on wallet creation")
            let attributedString = NSMutableAttributedString(string: secondLabelString,
                                                             attributes: [
                                                                .font: Theme.shared.fonts.createWalletSecondLabelSecondText!,
                                                                .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel!,
                                                                .kern: -0.33
            ])

            let splitString = secondLabelString.components(separatedBy: "\n")
            if splitString.count > 0 {
                let length = splitString[0].count
                attributedString.addAttribute(.font,
                                              value: Theme.shared.fonts.createWalletSecondLabelFirstText!,
                                              range: NSRange(location: 0, length: length))

                self.secondLabel.attributedText = attributedString
            }
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                guard let self = self else { return }
                self.runCheckMarkAnimation()
            }
        }
    }

    private func runCheckMarkAnimation() {
        loadCheckMarkAnimation()
        startCheckMarkAnimation()
    }

    private func loadCheckMarkAnimation() {
        let animation = Animation.named("CheckMark")
        animationView.animation = animation
    }

    private func startCheckMarkAnimation() {
        animationView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { [weak self] (_) in
                guard let self = self else { return }
                self.showCreateYourEmojiIdScreen()
            }
        )
    }

    private func runEmojiWheelAnimation() {
        loadEmojiWheelAnimation()
        startEmojiWheelAnimation()
    }

    private func startEmojiWheelAnimation() {
        emojiWheelView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { [weak self] (_) in
                guard let self = self else { return }
                self.showYourEmoji()
            }
        )
    }

    private func loadEmojiWheelAnimation() {
        let animation = Animation.named("EmojiWheel")
        emojiWheelView.animation = animation
    }

    private func runNerdEmojiAnimation() {
        loadNerdEmojiAnimation()
        startNerdEmojiAnimation()
    }

    private func loadNerdEmojiAnimation() {
        let animation = Animation.named("NerdEmojiAnimation")
        nerdAnimationView.animation = animation
    }

    private func startNerdEmojiAnimation() {
        nerdAnimationView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { (_) in
            }
        )
    }

    private func showCreateYourEmojiIdScreen() {
        createEmojiButtonConstraint?.constant = 0
        createEmojiButtonSecondConstraint?.isActive = true
        runNerdEmojiAnimation()

        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabel.alpha = 1.0
            self.thirdLabel.alpha = 1.0
            self.createEmojiButton.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
        }
    }

    private func showYourEmoji() {
        createEmojiButtonConstraint?.constant = 0
        createEmojiButtonSecondConstraint?.isActive = true
        createEmojiButton.animateIn()
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabel.alpha = 1.0
            self.thirdLabel.alpha = 1.0
            self.userEmojiContainer.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.state = .showEmojiId
        }
    }

    private func showLocalAuthentification() {
        self.createEmojiButton.animateIn()
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabel.alpha = 1.0
            self.thirdLabel.alpha = 1.0
            self.localAuthentificationImageView.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.state = .localAuthentification
        }
    }

    private func updateLabelsForShowEmojiId() {
        let secondLabelString = NSLocalizedString("This is your Emoji ID", comment: "Splash show your emoji ID")
        let attributedString = NSMutableAttributedString(string: secondLabelString, attributes: [
            .font: Theme.shared.fonts.createWalletEmojiIDFirstText!,
          .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel!,
          .kern: -0.33
        ])
        attributedString.addAttribute(.font, value: Theme.shared.fonts.createWalletEmojiIDSecondText!, range: NSRange(location: 13, length: 8))

        self.secondLabel.attributedText = attributedString
        self.thirdLabel.text = NSLocalizedString("This set of emojis is your wallet address. It’s how your friends can find you and send you Tari.", comment: "Emoji Id third label on wallet creation")

        self.createEmojiButton.setTitle(NSLocalizedString("Continue", comment: "This is your emoji screen on wallet creation"), for: .normal)

        if let pubKey = TariLib.shared.tariWallet?.publicKey.0 {
            let (emojis, _) = pubKey.emojis
            self.userEmojiContainer.setUpView(emojiText: emojis,
                                              type: .normalView,
                                              textCentered: true,
                                              inViewController: self)
        }
    }

    private func updateLabelsForLocalAuthentification() {
        let currentType = LAContext().biometricType
        switch currentType {
        case .faceID:
            let secondLabelString = NSLocalizedString("Protect your wallet with Face ID", comment: "Splash face ID")
            let attributedString = NSMutableAttributedString(string: secondLabelString, attributes: [
              .font: Theme.shared.fonts.createWalletEmojiIDFirstText!,
              .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel!,
              .kern: -0.33
            ])
            attributedString.addAttribute(.font,
                                          value: Theme.shared.fonts.createWalletEmojiIDSecondText!,
                                          range: NSRange(location: 25, length: 7))
            self.secondLabel.attributedText = attributedString

            self.thirdLabel.text = NSLocalizedString("We recommend using Face ID to protect your Tari wallet for security and ease of use.",
                                                     comment: "Face ID third label on wallet creation")

            self.createEmojiButton.setTitle(NSLocalizedString("Enable Face ID",
                                                              comment: "Enable Face ID on wallet creation"),
                                            for: .normal)

            self.localAuthentificationImageView.image = Theme.shared.images.createWalletFaceID!
        case .touchID:

            let secondLabelString = NSLocalizedString("Protect your wallet with Touch ID", comment: "Splash face ID")
            let attributedString = NSMutableAttributedString(string: secondLabelString, attributes: [
              .font: Theme.shared.fonts.createWalletEmojiIDFirstText!,
              .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel!,
              .kern: -0.33
            ])
            attributedString.addAttribute(.font,
                                          value: Theme.shared.fonts.createWalletEmojiIDSecondText!,
                                          range: NSRange(location: 25, length: 8))
            self.secondLabel.attributedText = attributedString

            self.thirdLabel.text = NSLocalizedString("We recommend using Touch ID to access your Tari wallet for security and ease of use.",
                                                     comment: "Face ID third label on wallet creation")

            self.createEmojiButton.setTitle(NSLocalizedString("Enable Touch ID",
                                                              comment: "Enable Touch ID on wallet creation"),
                                            for: .normal)
            self.localAuthentificationImageView.image = Theme.shared.images.createWalletTouchID!
        case .none:
            // for iOS we do not implement Device PIN. So i will show the same thing just to be sure we show something on Simulator.
            let secondLabelString = NSLocalizedString("Protect your wallet with Touch ID", comment: "Splash face ID")
            let attributedString = NSMutableAttributedString(string: secondLabelString, attributes: [
              .font: Theme.shared.fonts.createWalletEmojiIDFirstText!,
              .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel!,
              .kern: -0.33
            ])
            attributedString.addAttribute(.font,
                                          value: Theme.shared.fonts.createWalletEmojiIDSecondText!,
                                          range: NSRange(location: 25, length: 8))
            self.secondLabel.attributedText = attributedString

            self.thirdLabel.text = NSLocalizedString("We recommend using Touch ID to access your Tari wallet for security and ease of use.",
                                                     comment: "Face ID third label on wallet creation")

            self.createEmojiButton.setTitle(NSLocalizedString("Enable Touch ID",
                                                              comment: "Enable Touch ID on wallet creation"),
                                            for: .normal)
            // To Do: change the image to faceID once karim provide to me.
            self.localAuthentificationImageView.image = Theme.shared.images.createWalletTouchID!
        }
    }

    // MARK: - Actions
    @objc func navigateToHome() {
        switch state {
        case .createEmojiId:
            self.createEmojiButton.animateOut()
            UIView.animate(withDuration: 1, animations: {
                self.secondLabel.alpha = 0.0
                self.thirdLabel.alpha = 0.0
                self.nerdAnimationView.alpha = 0.0
                self.view.layoutIfNeeded()
            }) { [weak self] (_) in
                guard let self = self else { return }
                self.runEmojiWheelAnimation()
                self.updateLabelsForShowEmojiId()
            }
        case .showEmojiId:
            self.createEmojiButton.animateOut()
            UIView.animate(withDuration: 1, animations: {
                self.secondLabel.alpha = 0.0
                self.thirdLabel.alpha = 0.0
                self.userEmojiContainer.alpha = 0.0
                self.view.layoutIfNeeded()
            }) { [weak self] (_) in
                guard let self = self else { return }
                self.updateLabelsForLocalAuthentification()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    guard let self = self else { return }
                    self.showLocalAuthentification()
                }
            }
        case .localAuthentification:
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                         error: &error) {
                let reason = secondLabel.text ?? ""

                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                    [weak self] success, _ in

                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if success {
                            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                            if let nav = storyboard.instantiateInitialViewController() as? UINavigationController {
                                nav.modalPresentationStyle = .overFullScreen
                                self.present(nav, animated: true, completion: nil)
                            }
                        } else {
                            let alert = UIAlertController(title: "There was an error",
                                                          message: "",
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Try again",
                                                          style: .default,
                                                          handler: nil))

                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            } else {
                let alert = UIAlertController(title: "There is no biometry",
                                              message: "",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok",
                                              style: .default,
                                              handler: nil))

                self.present(alert, animated: true, completion: nil)
            }
        case .enableNotifications:
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            if let nav = storyboard.instantiateInitialViewController() as? UINavigationController {
                nav.modalPresentationStyle = .overFullScreen
                present(nav, animated: true, completion: nil)
            }
        }
    }
}
