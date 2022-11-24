//  ICloudBackupManager.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 24/10/2022
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

final class ICloudBackupService {
    
    enum ICloudBackupError: Error {
        case noUbiquityContainer
        case unableToCreateBackup(error: Error)
        case unableToCreateFolderStructure(error: Error)
        case unableToDeleteFile(error: Error)
        case unableToCopyFile(error: Error)
        case unableToDownloadBackup(error: Error)
        case unableToSaveBackup(error: Error)
    }
    
    // MARK: - Properties
    
    private let remoteDirectoryName = "Tari-Wallet-Backups"
    
    private let backupUploadService = ICloudDocsUploadService(filenamePrefix: BackupFilesManager.encryptedFileName)
    private let backupDownloadService = ICloudDocsDownloadService(filenamePrefix: BackupFilesManager.encryptedFileName)
    
    @Published private var backupStatusValue: BackupStatus = .disabled
    @Published private var syncDate: Date?
    
    private var backupPassword: String?
    private var cancellables = Set<AnyCancellable>()
    
    private var ubiquityContainerURL: URL {
        get throws {
            guard let url = FileManager.default.url(forUbiquityContainerIdentifier: TariSettings.shared.iCloudContainerIdentifier)?.appendingPathComponent(remoteDirectoryName) else {
                throw ICloudBackupError.noUbiquityContainer
            }
            return url
        }
    }
    
    // MARK: - Initalisers
    
    init() {
        setupInitialData()
        setupCallbacks()
    }
    
    // MARK: - Setups
    
    private func setupInitialData() {
        
        switch TariSettings.shared.walletSettings.iCloudDocsBackupStatus {
        case .disabled:
            updateBackupStatus(isOn: false, syncDate: nil)
        case let .enabled(syncDate):
            updateBackupStatus(isOn: true, syncDate: syncDate)
        }
    }
    
    private func setupCallbacks() {
        
        backupUploadService.$status
            .sink { [weak self] in self?.handle(uploadStatus: $0) }
            .store(in: &cancellables)
        
        $backupStatusValue
            .sink { [weak self] in self?.handle(backupStatus: $0) }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func removeRemoteBackup() throws {
        let remoteDirectoryURL = try ubiquityContainerURL
        try remove(fileURL: remoteDirectoryURL)
    }
    
    private func updateBackupStatus(isOn: Bool, syncDate: Date?) {
        backupStatusValue = isOn ? .enabled : .disabled
        self.syncDate = syncDate
    }
    
    private func uploadBackup(password: String?) async throws {
        
        backupStatusValue = .inProgress(progress: 0.0)
        
        let remoteDirectoryURL = try ubiquityContainerURL
        let remoteFileName = password != nil ? BackupFilesManager.encryptedFileName : BackupFilesManager.unencryptedFileName
        let remoteFileURL = remoteDirectoryURL.appendingPathComponent(remoteFileName)
        let localFileURL = try await prepareBackup(password: password)
        try remove(fileURL: remoteDirectoryURL)
        try createFolderStructure(url: remoteDirectoryURL)
        try copy(from: localFileURL, to: remoteFileURL)
        try remove(fileURL: localFileURL)
        backupUploadService.uploadBackup()
    }
    
    private func downloadBackup(password: String?) async throws {
        
        let remoteDirectoryURL = try ubiquityContainerURL
        
        let remoteFileName = password != nil ? BackupFilesManager.encryptedFileName : BackupFilesManager.unencryptedFileName
        let remoteFileURL = remoteDirectoryURL.appendingPathComponent(remoteFileName)
        
        try await downloadRemoteBackup()
        try await store(backupURL: remoteFileURL, password: password)
    }
    
    private func prepareBackup(password: String?) async throws -> URL {
        do {
            return try await BackupFilesManager.prepareBackup(workingDirectoryName: "iCloud", password: password)
        } catch {
            throw ICloudBackupError.unableToCreateBackup(error: error)
        }
    }
    
    private func createFolderStructure(url: URL) throws {
        
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw ICloudBackupError.unableToCreateFolderStructure(error: error)
        }
    }
    
    private func remove(fileURL: URL) throws {
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            throw ICloudBackupError.unableToDeleteFile(error: error)
        }
    }
    
    private func copy(from fromURL: URL, to toURL: URL) throws {
        do {
            try FileManager.default.copyItem(at: fromURL, to: toURL)
        } catch {
            throw ICloudBackupError.unableToCopyFile(error: error)
        }
    }
    
    private func store(backupURL: URL, password: String?) async throws {
        do {
            try await BackupFilesManager.store(backup: backupURL, password: password)
        } catch {
            throw ICloudBackupError.unableToSaveBackup(error: error)
        }
    }
    
    private func downloadRemoteBackup() async throws {
        do {
            try await backupDownloadService.downloadBackup()
        } catch {
            throw ICloudBackupError.unableToDownloadBackup(error: error)
        }
    }
    
    private func checkIsPasswordRequired(password: String?) async throws {
        let remoteDirectoryURL = try ubiquityContainerURL
        
        let backupURL = try FileManager.default.contentsOfDirectory(atURL: remoteDirectoryURL, sortedBy: .modified)
            .filter { $0.lastPathComponent == BackupFilesManager.encryptedFileName || $0.lastPathComponent == BackupFilesManager.unencryptedFileName }
            .last
        
        guard let backupURL else { throw BackupError.noRemoteBackup }
        guard backupURL.lastPathComponent == BackupFilesManager.encryptedFileName, password == nil else { return }
        throw BackupError.passwordRequired
    }
    
    // MARK: - Handlers
    
    private func handle(backupStatus: BackupStatus) {
        switch backupStatus {
        case .disabled:
            syncDate = nil
            TariSettings.shared.walletSettings.iCloudDocsBackupStatus = .disabled
        case .enabled:
            TariSettings.shared.walletSettings.iCloudDocsBackupStatus = .enabled(syncDate: syncDate)
        case .inProgress, .failed:
            break
        }
    }
    
    private func handle(uploadStatus: ICloudDocsUploadService.Status) {
        switch uploadStatus {
        case let .inProgress(progress):
            backupStatusValue = .inProgress(progress: progress)
        case .finished:
            backupStatusValue = .enabled
            syncDate = Date()
            TariSettings.shared.walletSettings.iCloudDocsBackupStatus = .enabled(syncDate: syncDate)
        case .idle:
            break
        }
    }
}

extension ICloudBackupService: BackupServicable {

    var password: String? {
        get { backupPassword }
        set { backupPassword = newValue }
    }
    
    var isOn: Bool {
        get { backupStatusValue != .disabled }
        set {
            guard isOn != newValue else { return }
            updateBackupStatus(isOn: newValue, syncDate: nil)
            guard newValue else { return }
            performBackup(forced: true)
        }
    }
    
    var backupStatus: AnyPublisher<BackupStatus, Never> { $backupStatusValue.eraseToAnyPublisher() }
    var lastBackupTimestamp: AnyPublisher<Date?, Never> { $syncDate.eraseToAnyPublisher() }
    
    func performBackup(forced: Bool) {
        
        guard !AppValues.isSimulator, isOn else { return }
        guard forced || backupStatusValue.isFailed else { return }
        
        Task {
            do {
                try await uploadBackup(password: backupPassword)
            } catch {
                backupStatusValue = .failed(error: error)
            }
        }
    }
    
    func restoreBackup(password: String?) -> AnyPublisher<Void, Error> {
        
        let subject = PassthroughSubject<Void, Error>()
        
        defer {
            Task {
                do {
                    let remoteDirectoryURL = try ubiquityContainerURL
                    try createFolderStructure(url: remoteDirectoryURL)
                    try await checkIsPasswordRequired(password: password)
                    try await downloadBackup(password:password)
                    subject.send(())
                    subject.send(completion: .finished)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
}
