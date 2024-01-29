//  LocalNotificationsManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 23/05/2023
	Using Swift 5.0
	Running on macOS 13.0

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

import UserNotifications

final class LocalNotificationsManager: NSObject {

    private enum Category: String {
        case contactReceived
        case contactsReceived
    }

    private enum Action: String {
        case contactReceivedConfirm
        case contactReceivedReject
    }

    private enum UserInfo: String {
        case rawDeeplink
    }

    // MARK: - Properties

    static let shared = LocalNotificationsManager()

    // MARK: - Initialisers

    private override init() {}

    // MARK: - Setups

    func configure() {
        setupCallbacks()
        setupCategories()
    }

    private func setupCallbacks() {
        UNUserNotificationCenter.current().delegate = self
    }

    private func setupCategories() {
        UNUserNotificationCenter.current().setNotificationCategories([
            makeContactReceivedCategory(),
            makeContactsReceivedCategory()
        ])
    }

    private func makeContactReceivedCategory() -> UNNotificationCategory {

        let confirmAction = UNNotificationAction(identifier: Action.contactReceivedConfirm.rawValue, title: localized("contacts_received.popup.buttons.confirm.singular"))
        let rejectAction = UNNotificationAction(identifier: Action.contactReceivedReject.rawValue, title: localized("contacts_received.popup.buttons.reject"))

        return UNNotificationCategory(identifier: Category.contactReceived.rawValue, actions: [confirmAction, rejectAction], intentIdentifiers: [])
    }

    private func makeContactsReceivedCategory() -> UNNotificationCategory {

        let confirmAction = UNNotificationAction(identifier: Action.contactReceivedConfirm.rawValue, title: localized("contacts_received.popup.buttons.confirm.plural"))
        let rejectAction = UNNotificationAction(identifier: Action.contactReceivedReject.rawValue, title: localized("contacts_received.popup.buttons.reject"))

        return UNNotificationCategory(identifier: Category.contactsReceived.rawValue, actions: [confirmAction, rejectAction], intentIdentifiers: [])
    }

    // MARK: - Actions

    func showContactsReceivedNotification(rawEncodedDeeplink: String, isSingleContact: Bool) {

        var bodyComponents = [localized("contacts_received.popup.message.part.1")]

        if isSingleContact {
            bodyComponents += [localized("contacts_received.popup.message.part.2.singular.bold"), localized("contacts_received.popup.message.part.3.singular")]
        } else {
            bodyComponents += [localized("contacts_received.popup.message.part.2.plural.bold"), localized("contacts_received.popup.message.part.3.plural")]
        }

        let content = UNMutableNotificationContent()
        content.title = isSingleContact ? localized("contacts_received.popup.title.singular") : localized("contacts_received.popup.title.plural")
        content.body = bodyComponents.joined(separator: " ")
        content.categoryIdentifier = isSingleContact ? Category.contactReceived.rawValue : Category.contactsReceived.rawValue
        content.sound = .default
        content.userInfo = [UserInfo.rawDeeplink.rawValue: rawEncodedDeeplink]

        show(content: content)
    }

    private func show(content: UNMutableNotificationContent) {

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func handleOpenNotification(userInfo: [AnyHashable: Any]) {
        guard let rawDeeplink = userInfo[UserInfo.rawDeeplink.rawValue] as? String else { return }
        try? DeeplinkHandler.handle(rawDeeplink: rawDeeplink, showDefaultDialogIfNeeded: true)
    }
}

extension LocalNotificationsManager: UNUserNotificationCenterDelegate {

    @MainActor func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NotificationManager.shared.handleForegroundNotification(notification, completionHandler: completionHandler)
    }

    @MainActor func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {

        Logger.log(message: "Received local notification: \(response.notification.request.content.categoryIdentifier) | action: \(response.actionIdentifier)", domain: .localNotification, level: .info)

        let userInfo = response.notification.request.content.userInfo

        guard let actionType = Action(rawValue: response.actionIdentifier) else {
            handleOpenNotification(userInfo: userInfo)
            return
        }

        switch actionType {
        case .contactReceivedConfirm:
            handleOpenNotification(userInfo: userInfo)
        case .contactReceivedReject:
            break
        }
    }
}
