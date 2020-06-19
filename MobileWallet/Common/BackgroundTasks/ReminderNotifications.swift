//  ReminderNotifications.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/05/27
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

struct ScheduledReminder {
    let identifier: String
    let title: String
    let body: String
    let deliverAfter: TimeInterval
}

/// Local push notifications scheduled to remind users to open up the app to accept their tari
class ReminderNotifications {
    static let shared = ReminderNotifications()
    static private let dateUserDefaultsKey = "should-schedule-reminders-updated-at"

    static let titleString = String(
        format: NSLocalizedString(
            "You've been sent %@!",
            comment: "Local reminder notifications"
        ),
        TariSettings.shared.network.currencyDisplayTicker
    )

    static let recipientReminderNotifications: [ScheduledReminder] = [
        ScheduledReminder(
            identifier: "scheduled-reminders-recipient-1",
            title: ReminderNotifications.titleString,
            body: NSLocalizedString("Open Tari Aurora", comment: "Local reminder notifications"),
            deliverAfter: 60 * 60 * 24
        ),
        ScheduledReminder(
            identifier: "scheduled-reminders-recipient-2",
            title: ReminderNotifications.titleString,
            body: String(
                format: NSLocalizedString(
                    "Someone sent you %@! Open Tari Aurora to receive it now or it will be returned to the sender.",
                    comment: "Local reminder notifications"
                ),
                TariSettings.shared.network.currencyDisplayTicker
            ),
            deliverAfter: 60 * 60 * 48
        )
    ]

    let userDefaults = UserDefaults(suiteName: TariSettings.shared.groupIndentifier)!

    var shouldScheduleRemindersUpdatedAt: Date? {
        get {
            return userDefaults.object(forKey: ReminderNotifications.dateUserDefaultsKey) as? Date
        }
        set {
            if let newDate = newValue {
                userDefaults.set(newDate, forKey: ReminderNotifications.dateUserDefaultsKey)
            } else {
                userDefaults.removeObject(forKey: ReminderNotifications.dateUserDefaultsKey)
            }

            userDefaults.synchronize()
        }
    }

    private init() {}

    func setShouldScheduleReminder() {
        shouldScheduleRemindersUpdatedAt = Date()
    }
}
