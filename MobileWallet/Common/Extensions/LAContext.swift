//  LAContext.swift

/*
	Package MobileWallet
	Created by Gabriel Lupu on 08/02/2020
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
import LocalAuthentication

extension LAContext {
    enum BiometricType: String {
        case none
        case touchID
        case faceID
        case pin
    }

    enum AuthenticateUserReason {
        case logIn
        case userVerification

        var rawValue: String {
            switch self {
            case .logIn: return localized("authentication.reason.login")
            case .userVerification: return localized("authentication.reason.user_verification")
            }
        }
    }

    var biometricType: BiometricType {
        if  self.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            if  self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                if biometryType == .faceID {
                    return .faceID
                }
                if biometryType == .touchID {
                    return .touchID
                }
            }
            return .pin
        } else {
            return .none
        }
    }

    func authenticateUser(reason: AuthenticateUserReason = .logIn, showFailedDialog: Bool = true, onSuccess: @escaping () -> Void) {
        #if targetEnvironment(simulator)
        //Skip auth on simulator, quicker for development
        onSuccess()
        return
        #endif

        switch biometricType {
        case .faceID, .touchID, .pin:
            let policy: LAPolicy = .deviceOwnerAuthentication //it is not clear why but it works like that. If you specify with biometrics for some reason (system error, can't handle that) the window for entering the password code is not called
            let localizedReason = reason.rawValue
            evaluatePolicy(policy, localizedReason: localizedReason) {
                [weak self] success, error in

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if success {
                        onSuccess()
                    } else {
                        if !showFailedDialog { return }
                        let localizedReason = error?.localizedDescription ?? localized("authentication.fail.description")
                        TariLogger.error("Biometrics auth failed", error: error)
                        self.authenticationFailedAlertOptions(reason: localizedReason, onSuccess: onSuccess)
                    }
                }
            }
        case .none:
            let alert = UIAlertController(title: localized("authentication.error.title"),
                                          message: localized("authentication.error.description"),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: localized("authentication.try_again"),
                                          style: .cancel,
                                          handler: { [weak self] _ in
                                            self?.authenticateUser(onSuccess: onSuccess)
            }))

            alert.addAction(UIAlertAction(title: localized("authentication.proceed"), style: .default, handler: { _ in
                onSuccess()
            }))

            if let topController = UIApplication.shared.topController() {
                topController.present(alert, animated: true, completion: nil)
            }
        }
    }

    private func authenticationFailedAlertOptions(reason: String, onSuccess: @escaping () -> Void) {
        let alert = UIAlertController(title: localized("authentication.fail.title"), message: reason, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localized("authentication.try_again"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.authenticateUser(onSuccess: onSuccess)
        }))

        alert.addAction(UIAlertAction(title: localized("authentication.action.open_settings"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            if self.openAppSettings() {
                self.authenticationFailedAlertOptions(reason: reason, onSuccess: onSuccess)
            }
        }))

        if let topController = UIApplication.shared.topController() {
            topController.present(alert, animated: true, completion: nil)
        }
    }

    private func openAppSettings() -> Bool {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings)
            return true
        }
        return false
    }
}
