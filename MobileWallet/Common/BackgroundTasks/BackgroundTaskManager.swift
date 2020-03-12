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

    static let APP_BACKGROUND_SYNC_IDENTIFIER = "com.tari.ios.wallet.sync"
    //For testing using the debugger, pause, paste below command in and unpause
    //e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.tari.ios.wallet.sync"]

    func registerNodeSyncTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskManager.APP_BACKGROUND_SYNC_IDENTIFIER,
            using: nil
        ) { task in
            if let bgTask = task as? BGAppRefreshTask {
                self.handleAppRefresh(task: bgTask)
            }
        }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let appRefreshOperation = NodeSyncOperation()
        appRefreshOperation.completionHandler = { success in
            task.setTaskCompleted(success: success)
        }

        queue.addOperation(appRefreshOperation)

        task.expirationHandler = {
            queue.cancelAllOperations()
            task.setTaskCompleted(success: false)
        }

        let lastOperation = queue.operations.last
        lastOperation?.completionBlock = {
            task.setTaskCompleted(success: !(lastOperation?.isCancelled ?? false))
        }
    }

    func scheduleAppRefresh() {
        let taskRequest = BGAppRefreshTaskRequest(identifier: BackgroundTaskManager.APP_BACKGROUND_SYNC_IDENTIFIER)
        taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60) //Seconds

        do {
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            print("Scheduling error:")
            print(error)
        }
    }
}
