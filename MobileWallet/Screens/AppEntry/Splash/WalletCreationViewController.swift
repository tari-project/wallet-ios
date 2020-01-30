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

class WalletCreationViewController: UIViewController {
    // MARK: - Variables and constants

    // MARK: - Outlets
    @IBOutlet weak var createEmojiButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var topWhiteView: UIView!
    @IBOutlet weak var bottomWhiteView: UIView!
    @IBOutlet weak var animationView: AnimationView!
    @IBOutlet weak var createEmojiButton: ActionButton!
    @IBOutlet weak var emojiImageView: UIImageView!
    @IBOutlet weak var topImageView: UIImageView!

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
                                                            .font: Theme.shared.fonts.createWalletSecondLabelSecondText ?? UIFont.systemFont(ofSize: 12),
                                                            .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel ?? .black,
          .kern: -0.33
        ])

        let splitString = secondLabelString.components(separatedBy: "\n")
        if splitString.count > 0 {
            let length = splitString[0].count
            attributedString.addAttribute(.font,
                                          value: Theme.shared.fonts.createWalletSecondLabelFirstText ?? UIFont.systemFont(ofSize: 12),
                                          range: NSRange(location: 0, length: length))

            secondLabel.attributedText = attributedString
        }

        createEmojiButton.setTitle(NSLocalizedString("Continue & Create Emoji ID", comment: "Create button on wallet creation"), for: .normal)

        topImageView.image = topImageView.image?.withRenderingMode(.alwaysTemplate)
        topImageView.tintColor = .black
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
            //self.displaySecondLabelAnimation()
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
                                                                .font: Theme.shared.fonts.createWalletSecondLabelSecondText ?? UIFont.systemFont(ofSize: 12),
                                                                .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel ?? .black,
                                                                .kern: -0.33
            ])

            let splitString = secondLabelString.components(separatedBy: "\n")
            if splitString.count > 0 {
                let length = splitString[0].count
                attributedString.addAttribute(.font,
                                              value: Theme.shared.fonts.createWalletSecondLabelFirstText ?? UIFont.systemFont(ofSize: 12),
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
        //print("run checkmark animation")
        loadAnimation()
        startAnimation()
    }

    private func loadAnimation() {
        let animation = Animation.named("CheckMark")
        animationView.animation = animation
    }

    private func startAnimation() {
        animationView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { [weak self] (_) in
                guard let self = self else { return }
                self.showLastScreenAnimation()
            }
        )
    }

    private func showLastScreenAnimation() {
        self.createEmojiButtonConstraint.constant = 0

        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabel.alpha = 1.0
            self.thirdLabel.alpha = 1.0
            self.createEmojiButton.alpha = 1.0
            self.emojiImageView.alpha = 1.0
            self.view.layoutIfNeeded()
        })
    }

    // MARK: - Actions
    @IBAction func navigateToHoome(_ sender: Any) {
        performSegue(withIdentifier: "SplashToHome", sender: nil)
    }
}
