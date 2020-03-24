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

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    let notificationCenter = UNUserNotificationCenter.current()
    private let options: UNAuthorizationOptions = [.alert, .sound, .badge]

    func requestAuthorization(_ completionHandler: @escaping (Bool) -> Void) {
        if ProcessInfo.processInfo.arguments.contains("ui-test-mode") {
            completionHandler(true)
            return
        }

        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            guard error == nil else {
                TariLogger.error("NotificationManager request authorization", error: error)
                completionHandler(false)
                return
            }

            completionHandler(didAllow)
        }
    }

    func checkAuthorization(_ completionHandler: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                completionHandler(true)
            } else {
                completionHandler(false)
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
}
