//  NotificationManager.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/03/13
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
import UserNotifications

private struct TokenRegistrationServerRequest: Codable {
    let token: String
    let platform: String = "ios"
    let signature: String
    let public_nonce: String
}

private struct SendNotificationServerRequest: Codable {
    let from_pub_key: String
    let signature: String
    let public_nonce: String
}

enum TokenServerError: Error {
    case server(_ statusCode: Int, message: String?)
    case invalidSignature
    case responseInvalid
    case pushNotSent
    case unknown
}

class NotificationManager {
    static let shared = NotificationManager()

    let notificationCenter = UNUserNotificationCenter.current()
    private let options: UNAuthorizationOptions = [.alert, .sound, .badge]
    private static let HAS_REGISTERED_TOKEN_STORAGE_KEY = "hasRegisteredPushToken"
    private static var isRegisterRequestInProgress = false
    private static var isSendRequestInProgress = false

    var hasRegisteredToken: Bool {
        get {
            return UserDefaults.standard.bool(forKey: NotificationManager.HAS_REGISTERED_TOKEN_STORAGE_KEY)
        }
    }

    func requestAuthorization(_ completionHandler: ((Bool) -> Void)? = nil) {
        if ProcessInfo.processInfo.arguments.contains("ui-test-mode") {
            completionHandler?(true)
            return
        }

        guard !hasRegisteredToken else {
            TariLogger.verbose("Already registered for push notifications")
            completionHandler?(true)
            return
        }

        notificationCenter.requestAuthorization(options: options) {
            (_, error) in
            guard error == nil else {
                TariLogger.error("NotificationManager request authorization", error: error)

                completionHandler?(false)
                return
            }

            self.registerWithAPNS(completionHandler)
        }
    }

    private func registerWithAPNS(_ completionHandler: ((Bool) -> Void)? = nil) {
        TariLogger.verbose("Checking notification settings")
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                completionHandler?(true)

                TariLogger.info("Notifications authorized")

                DispatchQueue.main.async {
                    TariLogger.info("Registering for remote notifications with Apple")
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                TariLogger.warn("Notifications not authorized")
                completionHandler?(false)
            }
        }
    }

    //TODO remove time interval, probably not needed
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()

        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        let identifier = "Local Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { (error) in
            if let error = error {
                TariLogger.error("Scheduling local push notification", error: error)
            }
        }
    }

    func registerDeviceToken(_ deviceToken: Data) {
        //Avoid duplicate requests
        guard NotificationManager.isRegisterRequestInProgress == false else {
            TariLogger.warn("Server request already in progress")
            return
        }

        let apnsDeviceToken = deviceToken.map {String(format: "%02.2hhx", $0)}.joined()

        TariLogger.verbose("Registering device token with public key")

        guard let wallet = TariLib.shared.tariWallet else {
            return TariLogger.error("Failed to get wallet", error: WalletErrors.walletNotInitialized)
        }

        let (pubKey, pubKeyError) = wallet.publicKey
        guard pubKeyError == nil else {
            return TariLogger.error("Failed to get wallet pub key", error: pubKeyError)
        }

        let (pubKeyHex, hexError) = pubKey!.hex
        guard hexError == nil else {
            return TariLogger.error("Failed to get wallet hex pub key", error: hexError)
        }

        guard let signature = try? wallet.signMessage("\(pubKeyHex)\(apnsDeviceToken)") else {
            return TariLogger.error("Failed to sign message")
        }

        let url = URL(string: "\(TariSettings.shared.pushNotificationServer)/register/\(pubKeyHex)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(
                TokenRegistrationServerRequest(
                    token: apnsDeviceToken,
                    signature: signature.hex,
                    public_nonce: signature.nonce
                )
            )
        } catch {
            return TariLogger.error("Failed to JSON encode http body", error: error)
        }

        let onRequestError = {(requestError: Error) -> Void in
            NotificationManager.isRegisterRequestInProgress = false
            return TariLogger.error("Push notification register request failed", error: requestError)
        }

        NotificationManager.isRegisterRequestInProgress = true

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                onRequestError(error!)
                return
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                onRequestError(TokenServerError.unknown)
                return
            }

            guard response.statusCode != 403 else {
                onRequestError(TokenServerError.invalidSignature)
                return
            }

            var responseDict: [String: Any]?
            if let responseString = String(data: data, encoding: .utf8) {
                if let data = responseString.data(using: .utf8) {
                    do {
                        responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        onRequestError(error)
                        return
                    }
                }
            }

            guard (200 ... 299) ~= response.statusCode else {
                var message: String?
                if let res = responseDict {
                    message = res["error"] as? String
                }

                onRequestError(TokenServerError.server(response.statusCode, message: message))
                return
            }

            guard let registered = responseDict?["registered"] as? Bool else {
                onRequestError(TokenServerError.responseInvalid)
                return
            }

            TariLogger.info("Device token reigistered with public key")
            UserDefaults.standard.set(true, forKey: NotificationManager.HAS_REGISTERED_TOKEN_STORAGE_KEY)

            NotificationManager.isRegisterRequestInProgress = false
        }

        task.resume()
    }

    func sendToRecipient(_ toPublicKey: PublicKey, onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) throws {
        guard let wallet = TariLib.shared.tariWallet else {
            return TariLogger.error("Failed to get wallet", error: WalletErrors.walletNotInitialized)
        }

        let (pubKey, pubKeyError) = wallet.publicKey
        guard pubKeyError == nil else {
            return TariLogger.error("Failed to get wallet pub key", error: pubKeyError)
        }

        let (fromPubKeyHex, hexError) = pubKey!.hex
        guard hexError == nil else {
            return TariLogger.error("Failed to get wallet hex pub key", error: hexError)
        }

        let (toPubKeyHex, toHexError) = toPublicKey.hex
        guard toHexError == nil else {
            return TariLogger.error("Failed to get wallet to hex pub key", error: hexError)
        }

        guard let signature = try? wallet.signMessage("\(fromPubKeyHex)\(toPubKeyHex)") else {
            return TariLogger.error("Failed to sign message")
        }

        let url = URL(string: "\(TariSettings.shared.pushNotificationServer)/send/\(toPubKeyHex)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            SendNotificationServerRequest(
                from_pub_key: fromPubKeyHex,
                signature: signature.hex,
                public_nonce: signature.nonce
            )
        )

        let onRequestError = {(error: Error) in
            onError(error)
            NotificationManager.isSendRequestInProgress = false
        }

        NotificationManager.isSendRequestInProgress = true

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                onRequestError(error!)
                return
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                onRequestError(TokenServerError.unknown)
                return
            }

            guard response.statusCode != 403 else {
                onRequestError(TokenServerError.invalidSignature)
                return
            }

            var responseDict: [String: Any]?
            if let responseString = String(data: data, encoding: .utf8) {
                if let data = responseString.data(using: .utf8) {
                    do {
                        responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        onRequestError(error)
                        return
                    }
                }
            }

            guard (200 ... 299) ~= response.statusCode else {
                var message: String?
                if let res = responseDict {
                    message = res["error"] as? String
                }

                onRequestError(TokenServerError.server(response.statusCode, message: message))
                return
            }

            guard let sent = responseDict?["sent"] as? Bool else {
                onRequestError(TokenServerError.responseInvalid)
                return
            }

            if sent {
                onSuccess()
                NotificationManager.isSendRequestInProgress = false
            } else {
                onRequestError(TokenServerError.pushNotSent)
            }
        }

        task.resume()
    }
}
