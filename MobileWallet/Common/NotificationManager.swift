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
import Combine

private struct TokenRegistrationServerRequest: Encodable {
    let token: String
    let platform: String = "ios"
    let signature: String
    let public_nonce: String
    let sandbox = TariSettings.shared.environment == .debug
}

private struct SendNotificationServerRequest: Encodable {
    let from_pub_key: String
    let signature: String
    let public_nonce: String
}

private struct CancelRemindersServerRequest: Encodable {
    let pub_key: String
    let signature: String
    let public_nonce: String
}

enum PushNotificationServerError: Error {
    case server(_ statusCode: Int, message: String?)
    case invalidSignature
    case responseInvalid
    case pushNotSent
    case missingApiKey
    case unknown
}

final class NotificationManager {
    
    enum NotificationIdentifier: String {
        case standard = "Local Notification"
        case backgroundBackupTask = "background-backup-task"
        case scheduledBackupFailure = "scheduled-backup-failure"
    }

    static let shared = NotificationManager()
    
    private static let hasRegisteredTokenKey = "hasRegisteredPushToken"

    private let notificationCenter = UNUserNotificationCenter.current()
    private let options: UNAuthorizationOptions = [.alert, .sound, .badge]

    private var hasRegisteredToken: Bool { UserDefaults.standard.bool(forKey: NotificationManager.hasRegisteredTokenKey) }
    private var cancelables = Set<AnyCancellable>()
    
    private init() {
        setupWalletStateHandler()
    }
    
    private func setupWalletStateHandler() {
        
        TariLib.shared.walletStatePublisher
            .sink { [weak self] in
                switch $0 {
                case .started:
                    self?.requestAuthorization()
                case .starting, .notReady, .startFailed:
                    break
                }
            }
            .store(in: &cancelables)
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

        notificationCenter.requestAuthorization(options: options) { _, error in
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

    func handleForegroundNotification(_ notification: UNNotification, completionHandler: (UNNotificationPresentationOptions) -> Void) {
        try? TariLib.shared.tariWallet?.syncBaseNode()
        if notification.request.identifier == NotificationIdentifier.scheduledBackupFailure.rawValue {
            completionHandler([.alert, .badge, .sound])
        }
    }

    func scheduleNotification(title: String, body: String, identifier: String = NotificationIdentifier.standard.rawValue, timeInterval: TimeInterval = 1, onCompletion: ((Bool) -> Void)? = nil) {
        let content = UNMutableNotificationContent()

        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        )

        notificationCenter.add(request) { (error) in
            if let error = error {
                TariLogger.error("Scheduling local push notification", error: error)
                onCompletion?(false)
            } else {
                onCompletion?(true)
            }
        }
    }

    /// After syncing with base node we can cancel all prreviosuly scheduled reminder notifications that were going to remind the user to open up the app
    func cancelAllFutureReminderNotifications() {
        ReminderNotifications.shared.shouldScheduleRemindersUpdatedAt = nil

        var identifiers: [String] = []
        ReminderNotifications.recipientReminderNotifications.forEach { identifiers.append($0.identifier) }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func registerDeviceToken(_ deviceToken: Data) {
        let apnsDeviceToken = deviceToken.map {String(format: "%02.2hhx", $0)}.joined()

        TariLogger.verbose("Registering device token with public key")

        do {
            let signature = try signRequestMessage(apnsDeviceToken)

            let requestPayload = try JSONEncoder().encode(
                TokenRegistrationServerRequest(
                    token: apnsDeviceToken,
                    signature: signature.hex,
                    public_nonce: signature.nonce
                )
            )
            pushServerRequest(
                path: "/register/\(signature.publicKey.hex.0)",
                requestPayload: requestPayload,
                onSuccess: {
                    UserDefaults.standard.set(true, forKey: NotificationManager.hasRegisteredTokenKey)
                    TariLogger.info("Registered device token")
                }) { (error) in
                    TariLogger.error("Failed to register device token", error: error)
                }
        } catch {
            TariLogger.error("Failed to register device token. Will attempt again later.", error: error)
        }
    }

    func sendToRecipient(_ toPublicKey: PublicKey, onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) throws {
        let signature = try signRequestMessage(toPublicKey.hex.0)

        let requestPayload = try JSONEncoder().encode(
            SendNotificationServerRequest(
                from_pub_key: signature.publicKey.hex.0,
                signature: signature.hex,
                public_nonce: signature.nonce
            )
        )

        pushServerRequest(path: "/send/\(toPublicKey.hex.0)", requestPayload: requestPayload, onSuccess: onSuccess, onError: onError)
    }

    // TODO remove this is local push notifications work better
    func cancelReminders(onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) throws {
        let signature = try signRequestMessage("cancel-reminders")

        let requestPayload = try JSONEncoder().encode(
            CancelRemindersServerRequest(
                pub_key: signature.publicKey.hex.0,
                signature: signature.hex,
                public_nonce: signature.nonce
            )
        )

        pushServerRequest(path: "/cancel-reminders", requestPayload: requestPayload, onSuccess: onSuccess, onError: onError)
    }

    private func signRequestMessage(_ message: String) throws -> Signature {
        guard let wallet = TariLib.shared.tariWallet else {
            throw WalletErrors.walletNotInitialized
        }

        let (pubKey, pubKeyError) = wallet.publicKey
        guard pubKeyError == nil else {
            throw pubKeyError!
        }

        let (pubKeyHex, hexError) = pubKey!.hex
        guard hexError == nil else {
            throw hexError!
        }

        guard let apiKey = TariSettings.shared.pushServerApiKey else {
            throw PushNotificationServerError.missingApiKey
        }

        // TODO add apiKey when new push server redeployed
        return try wallet.signMessage("\(apiKey)\(pubKeyHex)\(message)")
    }

    private func pushServerRequest(path: String, requestPayload: Data, onSuccess: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        var request = URLRequest(url: URL(string: "\(TariSettings.shared.pushNotificationServer)\(path)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestPayload

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                return onError(error!)
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                return onError(PushNotificationServerError.unknown)
            }

            guard response.statusCode != 403 else {
                return onError(PushNotificationServerError.invalidSignature)
            }

            var responseDict: [String: Any]?
            if let responseString = String(data: data, encoding: .utf8) {
                if let data = responseString.data(using: .utf8) {
                    do {
                        responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        return onError(error)
                    }
                }
            }

            guard (200 ... 299) ~= response.statusCode else {
                var message: String?
                if let res = responseDict {
                    message = res["error"] as? String
                }

                return onError(PushNotificationServerError.server(response.statusCode, message: message))
            }

            // TODO remove the "success" field when server has been updated
            guard responseDict?["success"] as? Bool == true || responseDict?["registered"] as? Bool == true  else {
                return onError(PushNotificationServerError.responseInvalid)
            }

            onSuccess()
        }

        task.resume()
    }
}
