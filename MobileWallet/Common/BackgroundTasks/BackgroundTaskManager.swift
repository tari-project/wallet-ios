//  BackgroundTaskManager.swift

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
import BackgroundTasks

struct BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    static let appBackgroundTaskScheduleReminderNotifications = "com.tari.wallet.scheduleReminderNotifications"
    // For testing using the debugger, pause, paste below command in and unpause
    // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.tari.wallet.scheduleReminderNotifications"]

    private init() {}

    func registerScheduleReminderNotificationsTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskManager.appBackgroundTaskScheduleReminderNotifications,
            using: DispatchQueue.global()
        ) { task in
            if let bgTask = task as? BGAppRefreshTask {
                self.handleScheduleRemindersTask(task: bgTask)
            }
        }

        scheduleBackgroundCheckForReminderNotifications()
    }

    func scheduleBackgroundCheckForReminderNotifications() {
        let taskRequest = BGAppRefreshTaskRequest(identifier: BackgroundTaskManager.appBackgroundTaskScheduleReminderNotifications)
        taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 15) // 15min

        do {
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            Logger.log(message: "Scheduling task to schedule reminder notifications: \(error.localizedDescription)", domain: .general, level: .error)
        }
    }

    func handleScheduleRemindersTask(task: BGAppRefreshTask) {
        scheduleBackgroundCheckForReminderNotifications()

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let scheduleRemindersOperation = ScheduleReminderNotificationsOperation()
        scheduleRemindersOperation.completionHandler = { success in
            task.setTaskCompleted(success: success)
        }

        queue.addOperation(scheduleRemindersOperation)

        task.expirationHandler = {
            queue.cancelAllOperations()
            task.setTaskCompleted(success: false)
        }

        let lastOperation = queue.operations.last
        lastOperation?.completionBlock = {
            let isCancelled = lastOperation?.isCancelled ?? false
            task.setTaskCompleted(success: !isCancelled)
        }
    }
}
