//  BackupWalletSettingsModel.swift

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

import Combine

final class BackupWalletSettingsModel {

    enum BackupState {
        case off
        case upToDate
        case backupInProgress(progress: Double)
        case backupFailed
    }

    // MARK: - View Model

    @Published private(set) var isSeedWordListVerified: Bool = false
    @Published private(set) var iCloudBackupState: BackupState = .off
    @Published private(set) var iCloudLastBackupTime: String?
    @Published private(set) var dropboxBackupState: BackupState = .off
    @Published private(set) var dropboxLastBackupTime: String?
    @Published private(set) var isBackupSecuredByPassword: Bool = false
    @Published private(set) var isBackupOutOfSync: Bool = false

    // MARK: - Properties

    private let timestampFormatter = DateFormatter.backupTimestamp
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        BackupManager.shared.$syncState
            .map { $0 == .outOfSync }
            .assignPublisher(to: \.isBackupOutOfSync, on: self)
            .store(in: &cancellables)

        BackupManager.shared.backupService(.iCloud).backupStatus
            .map {
                switch $0 {
                case .disabled:
                    return .off
                case .enabled:
                    return .upToDate
                case let .inProgress(progress):
                    return .backupInProgress(progress: progress * 100.0)
                case .failed:
                    return .backupFailed
                }
            }
            .removeDuplicates()
            .assignPublisher(to: \.iCloudBackupState, on: self)
            .store(in: &cancellables)

        BackupManager.shared.backupService(.dropbox).backupStatus
            .map {
                switch $0 {
                case .disabled:
                    return .off
                case .enabled:
                    return .upToDate
                case let .inProgress(progress):
                    return .backupInProgress(progress: progress * 100.0)
                case .failed:
                    return .backupFailed
                }
            }
            .removeDuplicates()
            .assignPublisher(to: \.dropboxBackupState, on: self)
            .store(in: &cancellables)

        BackupManager.shared.backupService(.iCloud).lastBackupTimestamp
            .map { [weak self] in self?.lastBackupText(date: $0) }
            .assignPublisher(to: \.iCloudLastBackupTime, on: self)
            .store(in: &cancellables)

        BackupManager.shared.backupService(.dropbox).lastBackupTimestamp
            .compactMap { [weak self] in self?.lastBackupText(date: $0) }
            .assignPublisher(to: \.dropboxLastBackupTime, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func refreshData() {
        isBackupSecuredByPassword = BackupManager.shared.password != nil
        isSeedWordListVerified = TariSettings.shared.walletSettings.hasVerifiedSeedPhrase
    }

    func update(isCloudBackupOn: Bool) {
        BackupManager.shared.backupService(.iCloud).isOn = isCloudBackupOn
        guard !isCloudBackupOn else { return }
        try? BackupManager.shared.removeICloudRemoteBackup()
    }

    func update(isDropboxBackupOn: Bool) {
        BackupManager.shared.backupService(.dropbox).isOn = isDropboxBackupOn
    }

    func backupIfNeeded() {
        BackupManager.shared.backupNow(onlyIfOutdated: true)
    }

    // MARK: - Helpers

    private func lastBackupText(date: Date?) -> String? {
        guard let date else { return nil }
        let formattedDate = timestampFormatter.string(from: date)
        return localized("settings.last_successful_backup.with_param", arguments: formattedDate)
    }
}

extension BackupWalletSettingsModel.BackupState: Equatable {

    var isOn: Bool {
        switch self {
        case .off:
            return false
        default:
            return true
        }
    }
}
