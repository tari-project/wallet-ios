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
    @IBOutlet weak var createEmojiButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var bottomWhiteView: UIView!
    @IBOutlet weak var animationView: AnimationView!
    @IBOutlet weak var emojiWheelView: AnimationView!
    @IBOutlet weak var nerdAnimationView: AnimationView!
    @IBOutlet weak var createEmojiButton: ActionButton!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var userEmojiLabel: UILabel!
    @IBOutlet weak var userEmojiContainer: UIView!
    @IBOutlet weak var localAuthentificationImageView: UIImageView!

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

    private func setupView() {
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
        self.userEmojiLabel.backgroundColor = Theme.shared.colors.creatingWalletEmojisLabelBackground
    }

    private func firstLabelAnimation() {
        self.firstLabelTopConstraint.constant = -50.0

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
        self.createEmojiButtonConstraint.constant = 20
        self.runNerdEmojiAnimation()

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
        self.createEmojiButtonConstraint.constant = 20
        self.createEmojiButton.animateIn()
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabel.alpha = 1.0
            self.thirdLabel.alpha = 1.0
            self.userEmojiLabel.alpha = 1.0
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

            self.userEmojiLabel.textColor = Theme.shared.colors.creatingWalletEmojisSeparator
            self.userEmojiLabel.text = String(emojis.enumerated().map { $0 > 0 && $0 % 4 == 0 ? ["|", $1] : [$1]}.joined())
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
    @IBAction func navigateToHoome(_ sender: Any) {
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
                self.userEmojiLabel.alpha = 0.0
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
                            self.performSegue(withIdentifier: "SplashToHome", sender: nil)
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
            performSegue(withIdentifier: "SplashToHome", sender: nil)
        }
    }
}
