//  ProfileViewController.swift

/*
	Package MobileWallet
	Created by Gabriel Lupu on 04/02/2020
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

class ProfileViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emojiContainer: UIView!
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var copyEmojiButton: TextButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var middleLabel: UILabel!
    @IBOutlet weak var qrContainer: UIView!
    @IBOutlet weak var qrImageView: UIImageView!

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()

        customizeViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addShadowToQRView()
    }

    // MARK: - Private functions
    private func customizeTitleLabel() {
        let shareYourEmojiString = NSLocalizedString("Share your Emoji ID to receive Tari", comment: "profile title label")
        let attributedString = NSMutableAttributedString(string: shareYourEmojiString,
                                                         attributes: [.font: Theme.shared.fonts.profileTitleLightLabel!,
                                                                      .foregroundColor: Theme.shared.colors.profileTitleTextColor!,
                                                                      .kern: -0.33])
        attributedString.addAttribute(.font,
                                      value: Theme.shared.fonts.profileTitleRegularLabel!,
                                      range: NSRange(location: 11, length: 8))

        titleLabel.attributedText = attributedString
    }

    private func customizeEmoji() {
        if let pubKey = TariLib.shared.tariWallet?.publicKey.0 {
            let (emojis, _) = pubKey.emojis

            self.emojiLabel.textColor = Theme.shared.colors.creatingWalletEmojisSeparator
            self.emojiLabel.text = String(emojis.enumerated().map { $0 > 0 && $0 % 4 == 0 ? ["|", $1] : [$1]}.joined())
        }
    }

    private func customizeCopyMyEmojiButton() {
        copyEmojiButton.setVariation(.secondary)
        let titleButton = NSLocalizedString("Copy my emoji ID", comment: "Profile title button")
        self.copyEmojiButton.setTitle(titleButton, for: .normal)
    }

    private func customizeSeparatorView() {
        separatorView.backgroundColor = Theme.shared.colors.profileSeparatorView!
    }

    private func customizeMiddleLabel() {
        let middleLabelText = NSLocalizedString("Transacting in person? Your sender can get your emoji ID by scanning this QR code in their Tari app", comment: "Profile middle label")

        self.middleLabel.text = middleLabelText
        self.middleLabel.font = Theme.shared.fonts.profileMiddleLabel
        self.middleLabel.textColor = Theme.shared.colors.profileMiddleLabel!
    }

    private func genQRCode() {

        guard let wallet = TariLib.shared.tariWallet else {
            return
        }

        let (walletPublicKey, pubKeyError) = wallet.publicKey
        if pubKeyError != nil {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to access wallet public key", comment: "Profile View Controller"), description: ""
            )
        }
        let qrText = walletPublicKey?.emojis.0 ?? ""
        let vcard = qrText.data(using: .utf8)

        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(vcard, forKey: "inputMessage")
        filter?.setValue("L", forKey: "inputCorrectionLevel")

        if let output = filter?.outputImage {
            let scaleX = qrImageView.frame.size.width / output.extent.size.width
            let scaleY = qrImageView.frame.size.height / output.extent.size.height
            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            let scaledOutput = output.transformed(by: transform)
            qrImageView.image = UIImage(ciImage: scaledOutput)
        }
    }

    private func customizeViews() {
        customizeTitleLabel()
        customizeEmoji()
        customizeCopyMyEmojiButton()
        customizeSeparatorView()
        customizeMiddleLabel()
        genQRCode()
    }

    private func copyToClipboard() {
        let pasteboard = UIPasteboard.general
        pasteboard.string = emojiLabel.text ?? ""
    }

    private func sendHapticNotification() {
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
        impactFeedbackgenerator.impactOccurred()
    }

    private func addShadowToQRView() {
        qrContainer.layer.shadowOpacity = 0.5
        qrContainer.layer.shadowOffset = CGSize(width: 20, height: 20)
        qrContainer.layer.shadowRadius = 3.0
        qrContainer.layer.shadowColor = Theme.shared.colors.profileQRShadow?.cgColor

        let shadowRect: CGRect = qrContainer.bounds.insetBy(dx: 4, dy: 4)
        qrContainer.layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
        qrContainer.layer.shouldRasterize = true
        qrContainer.layer.rasterizationScale = UIScreen.main.scale
        qrContainer.layer.masksToBounds = false
    }

    // MARK: - Actions
    @IBAction func onDismissAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onCopyEmojiAction(_ sender: Any) {
        copyToClipboard()
        sendHapticNotification()

        UIView.transition(with: copyEmojiButton,
                          duration: 2.0,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
                            guard let self = self else { return }
                            let titleButton = NSLocalizedString("Copied!",
                                                                comment: "Profile copied button")
                            self.copyEmojiButton.setTitle(titleButton,
                                                          for: .normal)
        },
                          completion: { [weak self] (_) in
                            guard let self = self else { return }
                            let titleButton = NSLocalizedString("Copy my emoji ID",
                                                                comment: "Profile title button")
                            self.copyEmojiButton.setTitle(titleButton,
                                                          for: .normal)
        })
    }

}
