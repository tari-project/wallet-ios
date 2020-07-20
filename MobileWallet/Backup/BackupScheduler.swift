//  BackupScheduler.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 07.07.2020
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

class BackupScheduler: NSObject {
    private let autoBackupTimeInterval: TimeInterval = 60.0 // 1 min

    private(set) var isBackupScheduled: Bool {
        get {
            timer.isValid
        }
        set {
            if newValue {
                timer = Timer.scheduledTimer(withTimeInterval: autoBackupTimeInterval, repeats: false, block: { [weak self] (timer) in
                    timer.invalidate()
                    self?.createWalletBackup()
                })
            } else {
                timer.invalidate()
            }
        }
    }

    static let shared = BackupScheduler()

    private var timer = Timer()

    func startObserveEvents() {
        TariEventBus.onMainThread(self, eventType: .requiresBackup) { [weak self] (_) in
            self?.scheduleBackup()
        }
    }

    func stopObserveEvents() {
        timer.invalidate()
        TariEventBus.unregister(self)
    }

    func scheduleBackup(immediately: Bool = false) {
        if immediately {
            createWalletBackup()
        } else {
            if !isBackupScheduled {
                isBackupScheduled = true
            }
        }
    }

    func removeSchedule() {
        isBackupScheduled = false
    }

    private func createWalletBackup() {
        TariLib.shared.waitIfWalletIsRestarting { (_) in
            do {
                let password = BPKeychainWrapper.loadBackupPasswordFromKeychain()
                try ICloudBackup.shared.createWalletBackup(password: password)
            } catch {
                var title = NSLocalizedString("iCloud_backup.error.title.create_backup", comment: "iCloudBackup error")

                if let localizedError = error as? LocalizedError, localizedError.failureReason != nil {
                   title = localizedError.failureReason!
                }
                UserFeedback.shared.error(title: title, description: "", error: error)
            }
        }
    }
}
