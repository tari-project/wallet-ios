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

    private let localAuthenticationContext = LAContext()

    override func viewDidLoad() {
        super.viewDidLoad()

        setVersion()
        checkAuthEnabled()
        loadAnimation()

        //Determine if app needs to navigate home or to onboarding
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //startAnimation()
    }

    private func setVersion() {
        versionLabel.font = Theme.shared.fonts.splashTestnetFooterLabel
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let labelText = NSLocalizedString("Testnet", comment: "Bottom version label for splash screen")
            versionLabel.text = "\(labelText) V\(version)".uppercased()
        }
    }

    private func checkAuthEnabled() {

        //localAuthenticationContext.localizedCancelTitle = "Enter Username/Password"

        let authPolicy: LAPolicy = .deviceOwnerAuthentication

        var error: NSError?
        if localAuthenticationContext.canEvaluatePolicy(authPolicy, error: &error) {
                let reason = "Log in to your account"
                self.localAuthenticationContext.evaluatePolicy(authPolicy, localizedReason: reason ) { success, error in
                    if success {
                        // Move to the main thread because a animation needs to start in the UI.

                        DispatchQueue.main.async {
                            self.startAnimation()
                        }
                    } else {
                        print("Failed to auth")
                        print(error?.localizedDescription ?? "Failed to authenticate")

                        // Fall back to a asking for username and password.
                        // ...
                    }
                }
        } else {
            print("No auth policy")
            print(error)
            biometricsNeedsEnabling()
        }
    }

    /*
     1.
     - User doesn't accept using Face ID, they're always presented with their device pin/passcode until they go to settings and enable Face ID
     
     
 
    */

    private func biometricsNeedsEnabling() {
        let alert = UIAlertController(title: "Auth failed", message: "Please enable Face ID for the Tari app", preferredStyle: .alert)
        //alert.addAction(UIAlertAction(title: "Enable now", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style {
            case .default:
                print("default")
            case .cancel:
                print("cancel")
            @unknown default:
                print("Unknown")
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }

    private func loadAnimation() {
        let animation = Animation.named("SplashAnimation")
        animationContainer.animation = animation
    }

    private func startAnimation() {
        #if targetEnvironment(simulator)
          //animationContainer.animationSpeed = 5
        #endif

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
