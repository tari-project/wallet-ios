//  TariKeychainWrapper.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 06.07.2020
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

import Foundation
import SwiftKeychainWrapper

class TariKeychainWrapper {

    static let shared = TariKeychainWrapper()

    private let commsPrivateKeyHexStringKey = "privateKey"
    private let base64EncodedTorIdentityKey = "Base64EncodedTorIdentityKey"
    private let backupPasswordKey = "BackupPasswordKey"
    private let yatAlternateIdKey = "YatAlternateIdKey"
    private let yatPasswordKey = "YatPasswordKey"
    private let yatAccessTokenKey = "YatAccessTokenKey"
    private let yatRefreshTokenKey = "YatRefreshTokenKey"

    private let keychainWrapper: KeychainWrapper

    init() {
        keychainWrapper = KeychainWrapper(
            serviceName: "tari",
            accessGroup: "\(TariSettings.shared.appleTeamID ?? "").com.tari.wallet.keychain"
        )
    }

    func clear() {
        commsPrivateKeyHexString = nil
        base64EncodedTorIdentity = nil
        backupPassword = nil
        yatAlternateId = nil
        yatPassword = nil
        yatCredentials = nil
    }

    var commsPrivateKeyHexString: String? {
        get {
            return keychainWrapper.string(forKey: commsPrivateKeyHexStringKey)
        }
        set {
            if let identity = newValue {
                keychainWrapper.set(identity, forKey: commsPrivateKeyHexStringKey)
            } else {
                keychainWrapper.removeObject(forKey: commsPrivateKeyHexStringKey)
            }
        }
    }

    var base64EncodedTorIdentity: String? {
        get {
            return keychainWrapper.string(forKey: base64EncodedTorIdentityKey)
        }
        set {
            if let identity = newValue {
                keychainWrapper.set(identity, forKey: base64EncodedTorIdentityKey)
            } else {
                keychainWrapper.removeObject(forKey: base64EncodedTorIdentityKey)
            }
        }
    }

    var backupPassword: String? {
        get {
            return keychainWrapper.string(forKey: backupPasswordKey)
        }
        set {
            if let password = newValue {
                keychainWrapper.set(password, forKey: backupPasswordKey)
            } else {
                keychainWrapper.removeObject(forKey: backupPasswordKey)
            }
        }
    }

    var yatAlternateId: String? {
        get {
            return keychainWrapper.string(forKey: yatAlternateIdKey)
        }
        set {
            if let alternateId = newValue {
                keychainWrapper.set(alternateId, forKey: yatAlternateIdKey)
            } else {
                keychainWrapper.removeObject(forKey: yatAlternateIdKey)
            }

        }
    }

    var yatPassword: String? {
        get {
            return keychainWrapper.string(forKey: yatPasswordKey)
        }
        set {
            if let password = newValue {
                keychainWrapper.set(password, forKey: yatPasswordKey)
            } else {
                keychainWrapper.removeObject(forKey: yatPasswordKey)
            }
        }
    }

    var yatCredentials: YatCredentials? {
        get {
            if let accessToken = keychainWrapper.string(forKey: yatAccessTokenKey),
                let refreshToken = keychainWrapper.string(forKey: yatRefreshTokenKey) {
                return YatCredentials(accessToken: accessToken, refreshToken: refreshToken)
            }
            return nil
        }
        set {
            if let credentials = newValue {
                keychainWrapper.set(credentials.accessToken, forKey: yatAccessTokenKey)
                keychainWrapper.set(credentials.refreshToken, forKey: yatRefreshTokenKey)
            } else {
                keychainWrapper.removeObject(forKey: yatAccessTokenKey)
            }
        }
    }

}
