//  ScheduleReminderNotificationsOperation.swift

/*
    Package MobileWallet
    Created by Jason van den Berg on 2020/03/11
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

class ScheduleReminderNotificationsOperation: Operation {
    var completionHandler: ((Bool) -> Void)?

    override func main() {
        if isCancelled {
            return
        }

        //TODO investigate why this passes occasionally when it shouldn't
        guard ReminderNotifications.shared.shouldScheduleReminders else {
            onComplete(true)
            return
        }

        //Any feature background logic here
        NotificationManager.shared.cancelAllFutureReminderNotifications()

        var numberOfSetNotifications = 0
        ReminderNotifications.recipientReminderNotifications.forEach { (reminderDetails) in
            NotificationManager.shared.scheduleNotification(
                title: reminderDetails.title,
                body: reminderDetails.body,
                identifier: reminderDetails.identifier,
                timeInterval: reminderDetails.deliverAfter) { [weak self] (_) in
                    numberOfSetNotifications = numberOfSetNotifications + 1
                    //Know for certain all notifications have been scheduled
                    if numberOfSetNotifications >= ReminderNotifications.recipientReminderNotifications.count {
                        self?.onComplete(true)
                    }
                }
        }
    }

    private func onComplete(_ success: Bool) {
        if let done = self.completionHandler {
            done(success)
        }
    }
}
