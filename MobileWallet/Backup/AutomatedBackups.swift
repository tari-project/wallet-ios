//  AutomatedBackups.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/07/07
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

class BackgroundBackup: ICloudBackupObserver {
    static let shared = BackgroundBackup()

    lazy var iCloudBackup: ICloudBackup = {
           let backup = ICloudBackup.shared
           backup.addObserver(self)
           return backup
    }()

    private static let pushTaskIdentifier = "background-backup-task"
    private var backgroundID: UIBackgroundTaskIdentifier?
    private var backupInProgress = false

    private init() {}

    func backgroundBackupWallet() {
        guard backupInProgress == false else {
            TariLogger.error("Backup already in progress.")
            return
        }

        backupInProgress = true
        TariLogger.info("Starting iCloud backup in the background")

        //Perform the task on a background queue.
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            // Request the task assertion and save the ID.
            self.backgroundID = UIApplication.shared.beginBackgroundTask(withName: "Finish Backup Task") {
                // Expiration handler.
                //TODO get actual copy and move to language file
                NotificationManager.shared.scheduleNotification(
                    title: "Please open the app",
                    body: "Wallet backup did not complete",
                    identifier: BackgroundBackup.pushTaskIdentifier,
                    timeInterval: 0.5) { (_) in
                        TariLogger.info("User reminded to open the app as a background backup did not complete.")
                        self.endTask()
                    }
            }

            let password = BPKeychainWrapper.loadBackupPasswordFromKeychain()
            do {

                try self.iCloudBackup.createWalletBackup(password: password)
            } catch {
                TariLogger.error("Failed to create wallet backup", error: error)
                self.endTask()
            }
        }
    }

    private func endTask() {
        if let id = backgroundID {
            UIApplication.shared.endBackgroundTask(id)
        }
        self.backgroundID = UIBackgroundTaskIdentifier.invalid
        backupInProgress = false
    }

    @objc func onUploadProgress(percent: Double, completed: Bool, error: Error?) {
        if completed {
            self.endTask()
        }
    }
}
