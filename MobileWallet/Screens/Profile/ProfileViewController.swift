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

    let emojiIdView = EmojiIdView()
    let middleLabel = UILabel()
    let bottomView = UIView()
    let qrContainer = UIView()
    let qrImageView = UIImageView()
    let navigationBar = NavigationBar()
    private var emojis: String?

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupEmojiIdView()
        setupMiddleLabel()
        setupQRContainer()
        setupQRImageView()
        generateQRCode()
        customizeViews()

        view.bringSubviewToFront(emojiIdView)

        Tracker.shared.track("/home/profile", "Profile - Wallet Info")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addShadowToQRView()
    }

    // MARK: - Private functions

    private func setupNavigationBar() {
        navigationBar.backButton.isHidden = true
        navigationBar.verticalPositioning = .center
        navigationBar.title = NSLocalizedString("profile_view.title", comment: "Profile view")
        navigationBar.backgroundColor =  Theme.shared.colors.profileBackground
        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false

        navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }

    private func setupEmojiIdView() {
        view.addSubview(emojiIdView)
        emojiIdView.translatesAutoresizingMaskIntoConstraints = false
        emojiIdView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        emojiIdView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        emojiIdView.heightAnchor.constraint(equalToConstant: 38).isActive = true
        emojiIdView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 25).isActive = true
    }

    private func setupMiddleLabel() {
        middleLabel.numberOfLines = 0
        middleLabel.textAlignment = .center
        view.addSubview(middleLabel)
        middleLabel.translatesAutoresizingMaskIntoConstraints = false
        middleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        middleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        middleLabel.topAnchor.constraint(equalTo: emojiIdView.bottomAnchor, constant: 20).isActive = true
    }

    private func setupQRContainer() {
        qrContainer.backgroundColor = Theme.shared.colors.appBackground
        let cornerRadius = CGFloat(10)
        qrContainer.layer.cornerRadius = cornerRadius
        view.addSubview(qrContainer)
        qrContainer.translatesAutoresizingMaskIntoConstraints = false
        if UIDevice.current.userInterfaceIdiom == .pad {
            qrContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
            qrContainer.topAnchor.constraint(equalTo: middleLabel.bottomAnchor, constant: 100).isActive = true
        } else {
            qrContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
            qrContainer.trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
            qrContainer.topAnchor.constraint(lessThanOrEqualTo: middleLabel.bottomAnchor, constant: 25).isActive = true
            qrContainer.topAnchor.constraint(greaterThanOrEqualTo: middleLabel.bottomAnchor, constant: 10).isActive = true
        }

        qrContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        qrContainer.heightAnchor.constraint(equalTo: qrContainer.widthAnchor, multiplier: 1).isActive = true
        let bottomConstraint = qrContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        bottomConstraint.isActive = true
        bottomConstraint.priority = UILayoutPriority(rawValue: 1)
    }

    private func setupQRImageView() {
        qrContainer.addSubview(qrImageView)
        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        qrImageView.leadingAnchor.constraint(equalTo: qrContainer.leadingAnchor, constant: 30).isActive = true
        qrImageView.trailingAnchor.constraint(equalTo: qrContainer.trailingAnchor, constant: -30).isActive = true
        qrImageView.bottomAnchor.constraint(equalTo: qrContainer.bottomAnchor, constant: -30).isActive = true
        qrImageView.topAnchor.constraint(equalTo: qrContainer.topAnchor, constant: 30).isActive = true
    }

    private func setEmojiID() {
        if let pubKey = TariLib.shared.tariWallet?.publicKey.0 {
            let (emojis, _) = pubKey.emojis

            self.emojis = emojis

            emojiIdView.setupView(pubKey: pubKey, textCentered: true, inViewController: self)
            emojiIdView.blackoutParent = view
        }
    }

    private func customizeMiddleLabel() {
        let middleLabelText = String(
            format: NSLocalizedString(
                "profile_view.error.qr_code.description.with_param",
                comment: "Profile view"
            ),
            TariSettings.shared.network.currencyDisplayTicker
        )
        self.middleLabel.text = middleLabelText
        self.middleLabel.font = Theme.shared.fonts.profileMiddleLabel
        self.middleLabel.textColor = Theme.shared.colors.profileMiddleLabel!
    }

    private func genQRCode() throws {
        guard let wallet = TariLib.shared.tariWallet else {
            throw WalletErrors.walletNotInitialized
        }

        let (walletPublicKey, walletPublicKeyError) = wallet.publicKey
        guard let pubKey = walletPublicKey else {
            throw walletPublicKeyError!
        }

        let (deeplink, deeplinkError) = pubKey.hexDeeplink
        guard deeplinkError == nil else {
            throw deeplinkError!
        }

        let deepLinkData = deeplink.data(using: .utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(deepLinkData, forKey: "inputMessage")
        filter?.setValue("L", forKey: "inputCorrectionLevel")

        if let output = filter?.outputImage {
            let scaleX = UIScreen.main.bounds.width / output.extent.size.width
            let scaleY = UIScreen.main.bounds.width / output.extent.size.height
            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            let scaledOutput = output.transformed(by: transform)
            qrImageView.image = UIImage(ciImage: scaledOutput)
        }
    }

    private func customizeViews() {
        view.backgroundColor = Theme.shared.colors.profileBackground!
        setEmojiID()
        customizeMiddleLabel()
    }

    private func generateQRCode() {
        guard let _ = TariLib.shared.tariWallet else {
            TariLib.shared.waitIfWalletIsRestarting { [weak self] (success) in
                if success == true {
                    self?.generateQRCode()
                }
            }
            return
        }

        do {
            try genQRCode()
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("profile_view.error.qr_code.title", comment: "Profile view"),
                description: "",
                error: error)
        }
    }

    private func addShadowToQRView() {
        qrContainer.layer.shadowOpacity = 0.0
        qrContainer.layer.shadowOffset = CGSize(width: 20, height: 20)
        qrContainer.layer.shadowRadius = 3.0
        qrContainer.layer.shadowColor = Theme.shared.colors.profileQRShadow?.cgColor

        let shadowRect: CGRect = qrContainer.bounds.insetBy(dx: 4, dy: 4)
        qrContainer.layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
        qrContainer.layer.shouldRasterize = true
        qrContainer.layer.rasterizationScale = UIScreen.main.scale
        qrContainer.layer.masksToBounds = false

        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            self?.qrContainer.layer.shadowOpacity = 0.5
        }
    }
}
