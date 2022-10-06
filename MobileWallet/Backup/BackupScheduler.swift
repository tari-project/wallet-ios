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

import Combine

class BackupScheduler: NSObject {
    private let autoBackupTimeInterval: TimeInterval = 60.0 // 1 min

    @objc dynamic private(set) var isBackupScheduled: Bool {
        get {
            timer.isValid
        }
        set {
            if newValue {
                timer = Timer.scheduledTimer(
                    withTimeInterval: autoBackupTimeInterval,
                    repeats: false
                ) {
                    [weak self] (timer) in
                    timer.invalidate()
                    self?.createWalletBackup()
                }
            } else {
                timer.invalidate()
            }
        }
    }

    static let shared = BackupScheduler()
    private var timer = Timer()
    private(set) var scheduledBackupStarted: Bool = false
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        ICloudBackup.shared.addObserver(self)
    }

    func startObserveEvents() {
        
        cancellables.forEach { $0.cancel() }
        
        Tari.shared.transactions.onUpdate
            .sink { [weak self] in self?.scheduleBackup() }
            .store(in: &cancellables)
    }

    func stopObserveEvents() {
        timer.invalidate()
        cancellables.forEach { $0.cancel() }
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
        scheduledBackupStarted = true
        do {
            let password = AppKeychainWrapper.loadBackupPasswordFromKeychain()
            try ICloudBackup.shared.createWalletBackup(password: password)
        } catch {
            self.failedToCreateBackup(error: error)
        }
    }

}

extension BackupScheduler: ICloudBackupObserver {

    @objc func onUploadProgress(percent: Double, started: Bool, completed: Bool) {
        if completed {
            scheduledBackupStarted = false
        }
    }

    func failedToCreateBackup(error: Error) {
        if !scheduledBackupStarted { return }
        var title = localized("iCloud_backup.error.title.create_backup")
        if let localizedError = error as? LocalizedError, localizedError.failureReason != nil {
            title = localizedError.failureReason!
        }

        NotificationManager.shared.scheduleNotification(
            title: title,
            body: error.localizedDescription,
            identifier: NotificationManager.NotificationIdentifier.scheduledBackupFailure.rawValue
        ) {
            (_) in
            TariLogger.info("Scheduled backup has failed.")
            self.scheduledBackupStarted = false
        }
    }
}
