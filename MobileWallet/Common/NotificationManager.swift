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

import Firebase
import FirebaseMessaging
private struct TokenRegistrationServerRequest: Encodable {
    let token: String
    let platform: String = "ios"
    let appId: String?
    let signature: String
    let public_nonce: String
    let sandbox = false
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

final class NotificationManager: NSObject {

    enum NotificationIdentifier: String {
        case standard = "Local Notification"
        case backgroundBackupTask = "background-backup-task"
        case scheduledBackupFailure = "scheduled-backup-failure"
    }

    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let options: UNAuthorizationOptions = [.alert, .sound, .badge]

    private var cancellables = Set<AnyCancellable>()

    private let defaults = UserDefaults.standard
    private let appIdKey = "APP_ID"

    var appId: String? {
        get {
            return defaults.string(forKey: appIdKey)
        }
        set {
            defaults.set(newValue, forKey: appIdKey)
        }
    }

    private override init() {
        super.init()
    }

    func setupWalletStateHandler() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .filter { _ in Tari.shared.wallet(.main).isWalletDBExist }
            .sink { [weak self] _ in self?.requestAuthorization() }
            .store(in: &cancellables)
    }

    func shouldPromptForNotifications(completionHandler: @escaping (( Bool) -> Void)) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completionHandler(settings.authorizationStatus == .notDetermined)
        }
    }

    func registerPushToken(completionHandler: @escaping ((Bool) -> Void)) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
                completionHandler(false)
            } else if let token = token {
                self.registerDeviceToken(token)
                completionHandler(true)
            }
        }
    }

    func requestAuthorization(_ completionHandler: ((Bool) -> Void)? = nil) {
        if ProcessInfo.processInfo.arguments.contains("ui-test-mode") {
            completionHandler?(true)
            return
        }

        notificationCenter.requestAuthorization(options: options) { [weak self] _, error in
            guard let error else {
                self?.registerWithAPNS(completionHandler)
                return
            }
            Logger.log(message: "NotificationManager request authorization: \(error.localizedDescription)", domain: .general, level: .error)
            completionHandler?(false)
        }
    }

    private func registerWithAPNS(_ completionHandler: ((Bool) -> Void)? = nil) {
        Logger.log(message: "Checking notification settings", domain: .general, level: .info)
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                completionHandler?(true)
                Logger.log(message: "Notifications authorized", domain: .general, level: .info)
                DispatchQueue.main.async {
                    Logger.log(message: "Registering for remote notifications with Apple", domain: .general, level: .info)
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                Logger.log(message: "Notifications not authorized", domain: .general, level: .warning)
                completionHandler?(false)
            }
        }
    }

    func handleForegroundNotification(_ notification: UNNotification, completionHandler: (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .badge, .sound])
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
                Logger.log(message: "Scheduling local push notification: \(error)", domain: .general, level: .error)
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

    func registerAPNSToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func registerDeviceToken(_ fcmDeviceToken: String) {
        Logger.log(message: "Registering device token with public key", domain: .general, level: .verbose)

        do {
            let messageData = try sign(message: fcmDeviceToken)

            let applicationId = appId
//            let applicationId = "test"
            let requestPayload = try JSONEncoder().encode(
                TokenRegistrationServerRequest(
                    token: fcmDeviceToken,
                    appId: applicationId,
                    signature: messageData.metadata.hex,
                    public_nonce: messageData.metadata.nonce
                )
            )
            pushServerRequest(
                path: "/register/\(messageData.hex)",
                requestPayload: requestPayload,
                onSuccess: {
                    Logger.log(message: "Registered device token", domain: .general, level: .info)
                }) { (error) in
                    Logger.log(message: "Failed to register device token: \(error.localizedDescription)", domain: .general, level: .error)
                }
        } catch {
            Logger.log(message: "Failed to register device token. Will attempt again later: \(error.localizedDescription)", domain: .general, level: .error)
        }
    }

    func sendToRecipient(publicKey: String, onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) throws {
        let messageData = try sign(message: publicKey)

        let requestPayload = try JSONEncoder().encode(
            SendNotificationServerRequest(
                from_pub_key: messageData.hex,
                signature: messageData.metadata.hex,
                public_nonce: messageData.metadata.nonce
            )
        )

        pushServerRequest(path: "/send/\(publicKey)", requestPayload: requestPayload, onSuccess: onSuccess, onError: onError)
    }

    // TODO remove this is local push notifications work better
    func cancelReminders(onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) throws {
        let messageData = try sign(message: "cancel-reminders")
        let requestPayload = try JSONEncoder().encode(
            CancelRemindersServerRequest(
                pub_key: messageData.hex,
                signature: messageData.metadata.hex,
                public_nonce: messageData.metadata.nonce
            )
        )

        pushServerRequest(path: "/cancel-reminders", requestPayload: requestPayload, onSuccess: onSuccess, onError: onError)
    }

    private func sign(message: String) throws -> (hex: String, metadata: MessageMetadata) {
        let hex = try Tari.shared.wallet(.main).address.spendKey.byteVector.hex
        guard let apiKey = TariSettings.shared.pushServerApiKey else { throw PushNotificationServerError.missingApiKey }
        let metadata = try Tari.shared.wallet(.main).messageSign.sign(message: "\(apiKey)\(hex)\(message)")
        return (hex: hex, metadata: metadata)
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
            let responseString = data.string

            if let data = responseString.data(using: .utf8) {
                do {
                    responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                } catch {
                    return onError(error)
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

extension NotificationManager: MessagingDelegate {
    // Called whenever the FCM registration token is updated.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
                return
        }

        registerDeviceToken(token)
        print("Firebase registration token: \(token)")
        // Optionally, send the token to your application server.
    }
}
