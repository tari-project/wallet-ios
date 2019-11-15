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

class SplashViewController: UIViewController {
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var animationContainer: AnimationView!
    @IBOutlet weak var createWalletButton: ActionButton!

    private let wallet = TariLib.wallet

    private let localAuthenticationContext = LAContext()

    override func viewDidLoad() {
        super.viewDidLoad()

        createWalletButton.isHidden = true
        setupView()
        loadAnimation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkExistingWallet()
    }

    private func setupView() {
        createWalletButton.setTitle(NSLocalizedString("Create Wallet", comment: "Main action button on the onboarding screen"), for: .normal)

        versionLabel.font = Theme.shared.fonts.splashTestnetFooterLabel
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let labelText = NSLocalizedString("Testnet", comment: "Bottom version label for splash screen")
            versionLabel.text = "\(labelText) V\(version)".uppercased()
        }
    }

    private func checkExistingWallet() {
        if wallet.walletExists {
            authenticateUser()
        } else {
            createWalletButton.isHidden = false
        }
    }

    @IBAction func createWallet(_ sender: Any) {
        wallet.createNewWallet()
        checkExistingWallet()
    }

    private func authenticateUser() {
        let authPolicy: LAPolicy = .deviceOwnerAuthentication

        var error: NSError?
        if localAuthenticationContext.canEvaluatePolicy(authPolicy, error: &error) {
                let reason = "Log in to your account"
                self.localAuthenticationContext.evaluatePolicy(authPolicy, localizedReason: reason ) { success, error in
                    if success {
                        DispatchQueue.main.async {
                            self.startAnimation()
                        }
                    } else {
                        let reason = error?.localizedDescription ?? NSLocalizedString("Failed to authenticate", comment: "Failed Face ID alert")
                        print(reason)
                        DispatchQueue.main.async {
                            self.authenticationFailedAlertOptions(reason: reason)
                        }
                    }
                }
        } else {
            let reason = error?.localizedDescription ?? NSLocalizedString("No available biometrics available", comment: "Failed Face ID alert")
            print(reason)
            DispatchQueue.main.async {
                self.authenticationFailedAlertOptions(reason: reason)
            }
        }
    }

    private func authenticationFailedAlertOptions(reason: String) {
        let alert = UIAlertController(title: "Authentication failed", message: reason, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try again", style: .default, handler: { _ in
            self.authenticateUser()
        }))

        alert.addAction(UIAlertAction(title: "Open settings", style: .default, handler: { _ in
            self.openAppSettings()
        }))

        self.present(alert, animated: true, completion: nil)
    }

    private func openAppSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings)
        }
    }

    private func loadAnimation() {
        let animation = Animation.named("SplashAnimation")
        animationContainer.animation = animation
    }

    private func startAnimation() {
        #if targetEnvironment(simulator)
          animationContainer.animationSpeed = 5
        #endif

        createWalletButton.animateOut()

        animationContainer.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { (_) in
                self.navigateToHome()
            }
        )
    }

    private func navigateToHome() {
        performSegue(withIdentifier: "SplashToHome", sender: nil)
    }
}
