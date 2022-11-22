//  BackupManager.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 20/10/2022
	Using Swift 5.0
	Running on macOS 12.6

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
import Combine

final class BackupManager {
    
    enum BackupSyncState {
        case disabled
        case outOfSync
        case inProgress(progress: Double)
        case synced
    }
    
    enum Service {
        case iCloud
        case dropbox
    }
    
    // MARK: - Properties
    
    static let shared = BackupManager()
    
    var dropboxPresentationController: UIViewController? {
        get { dropboxBackupService.presentingController }
        set { dropboxBackupService.presentingController = newValue }
    }
    
    var isAnyServiceOn: Bool { allServices.first { $0.isOn } != nil }
    var isAnyServiceSynced: Bool { allServices.compactMap { $0.lastBackupTimestamp }.isEmpty == false }
    
    @Published var password: String? = AppKeychainWrapper.backupPassword
    @Published private(set) var syncState: BackupSyncState = .outOfSync
    
    private let backupSchedulerSubject = PassthroughSubject<Void, Never>()
    private let iCloudBackupService = ICloudBackupService()
    private let dropboxBackupService = DropboxBackupService()
    
    private var scheduledBackupTimer: Timer?
    private var allServices: [BackupServicable] { [iCloudBackupService, dropboxBackupService] }
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setups
    
    func configure() {
        setupServices()
        setupCallbacks()
    }
    
    private func setupServices() {
        dropboxBackupService.setupConfiguration()
    }
    
    private func setupCallbacks() {
        
        Publishers.Merge(Tari.shared.walletBalance.$balance.dropFirst().onChangePublisher(), Tari.shared.transactions.onUpdate.dropFirst())
            .throttle(for: 60.0, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in self?.performBackup(forced: true) }
            .store(in: &cancellables)
        
        backupSchedulerSubject
            .sink { [weak self] _ in self?.performBackup(forced: false) }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(iCloudBackupService.backupStatus, dropboxBackupService.backupStatus)
            .compactMap { [weak self] in self?.handle(iCloudBackupStatus: $0, dropboxBackupStatus: $1) }
            .assignPublisher(to: \.syncState, on: self)
            .store(in: &cancellables)
        
        $syncState
            .sink { [weak self] in self?.handle(syncState: $0) }
            .store(in: &cancellables)
        
        allServices.forEach { [weak self] in
            guard let self else { return }
            $0.backupStatus
                .compactMap {
                    guard case let .failed(error) = $0 else { return nil }
                    return error
                }
                .receive(on: DispatchQueue.main)
                .sink { self.show(error: $0) }
                .store(in: &self.cancellables)
        }
        
        $password
            .removeDuplicates()
            .sink { [weak self] password in
                AppKeychainWrapper.backupPassword = password
                self?.allServices.forEach { $0.password = password }
            }
            .store(in: &cancellables)
    }
    
    private func show(error: Error) {
        
        let message: String
        
        switch error {
        case let error as DropboxBackupError:
            guard let errorMessage = error.message else { return }
            message = errorMessage
        case let error as ICloudBackupService.ICloudBackupError:
            message = error.message
        default:
            return
        }
        
        guard UIApplication.shared.applicationState == .background else {
            let messageModel = MessageModel(title: localized("iCloud_backup.error.title.create_backup"), message: message, type: .error)
            PopUpPresenter.show(message: messageModel)
            return
        }
        
        NotificationManager.shared.scheduleNotification(
            title: localized("backup_local_notification.title"),
            body: message,
            identifier: NotificationManager.NotificationIdentifier.backgroundBackupTask.rawValue
        )
    }
    
    // MARK: - Dropbox Setups
    
    func handle(url: URL) {
        dropboxBackupService.handle(url: url)
    }
    
    // MARK: - Actions
    
    func removeICloudRemoteBackup() throws {
        try iCloudBackupService.removeRemoteBackup()
    }
    
    func backupNow(onlyIfOutdated: Bool) {
        performBackup(forced: !onlyIfOutdated)
    }
    
    func disableBackup() {
        allServices.forEach { $0.isOn = false }
    }
    
    func onTerminateAppAction() {
        guard syncState.inProgress else { return }
        
        NotificationManager.shared.scheduleNotification(
            title: localized("backup_local_notification.title"),
            body: localized("backup_local_notification.body"),
            identifier: NotificationManager.NotificationIdentifier.backgroundBackupTask.rawValue
        )
    }
    
    private func performBackup(forced: Bool) {
        allServices.forEach { $0.performBackup(forced: forced) }
    }
    
    // MARK: - Handlers
    
    private func handle(iCloudBackupStatus: BackupStatus, dropboxBackupStatus: BackupStatus) -> BackupSyncState {
        
        switch (iCloudBackupStatus, dropboxBackupStatus) {
        case (.failed, _), (_, .failed):
            return .outOfSync
        case let (.inProgress(iCloudProgress), .inProgress(dropboxProgress)):
            let progress = min(iCloudProgress, dropboxProgress)
            return .inProgress(progress: progress)
        case let (.inProgress(progress), _), let (_, .inProgress(progress)):
            return .inProgress(progress: progress)
        case (.enabled, _), (_, .enabled):
            return .synced
        case (.disabled, .disabled):
            password = nil
            return .disabled
        }
    }
    
    private func handle(syncState: BackupSyncState) {
        switch syncState {
        case .outOfSync:
            scheduleBackup()
        case .synced, .disabled:
            cancelScheduledBackup()
        default:
            break
        }
    }
    
    // MARK: - Helpers
    
    func backupService(_ service: Service) -> BackupServicable {
        switch service {
        case .iCloud:
            return iCloudBackupService
        case .dropbox:
            return dropboxBackupService
        }
    }
    
    // MARK: - Backup Schedule
    
    private func scheduleBackup() {
        scheduledBackupTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            self?.backupSchedulerSubject.send(())
        }
    }
    
    private func cancelScheduledBackup() {
        scheduledBackupTimer?.invalidate()
        scheduledBackupTimer = nil
    }
}

extension BackupManager.BackupSyncState: Equatable {
    
    var inProgress: Bool {
        switch self {
        case .inProgress:
            return true
        default:
            return false
        }
    }
}
