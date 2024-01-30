//  DropboxBackupManager.swift

/*
    Package MobileWallet
    Created by Adrian Truszczynski on 14/04/2022
    Using Swift 5.0
    Running on macOS 12.3

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
import SwiftyDropbox

enum DropboxBackupError: Error {
    case unableToCreateTempFolder
    case uploadFailed
    case downloadFailed
    case deleteFailed
    case backupPasswordRequired
    case authenticationCancelledByUser
    case authenticationFailed
    case noBackupToRestore
    case unknown
}

final class DropboxBackupService {

    private enum DataTask {
        case upload
        case download
    }

    private enum BackupType {
        case encrypted
        case unencrypted
    }

    private enum InternalError: Error {
        case noClient
        case unableToAuthenticateUser
        case folderExist
    }

    // MARK: - Constants

    private let maxSmallFileSize: UInt64 = 12 * 1024 * 1024
    private let remoteFolderPath = "/backup"
    private let localWorkingDirectoryName = "Dropbox"

    // MARK: - Properties

    @Published private var syncDate: Date?
    @Published private var syncStatus: BackupStatus = .disabled

    weak var presentingController: UIViewController?

    private var backupPassword: String?
    private var dataTask: DataTask?
    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    private var restoreCompletionSubject: PassthroughSubject<Void, Error>?
    private var cancellables = Set<AnyCancellable>()

    private var dropboxClient: DropboxClient {
        get throws {
            guard let client = DropboxClientsManager.authorizedClient else { throw InternalError.noClient }
            return client
        }
    }

    // MARK: - Initialisers

    init() {
        updateDropboxState()
        setupCallbacks()
    }

    private func updateDropboxState() {
        switch TariSettings.shared.walletSettings.dropboxBackupStatus {
        case let .enabled(syncDate):
            syncStatus = .enabled
            self.syncDate = syncDate
        case .disabled:
            syncStatus = .disabled
            syncDate = nil
        }
    }

    // MARK: - Setups

    func setupConfiguration() {
        guard let apiKey = TariSettings.shared.dropboxApiKey else { return }
        DropboxClientsManager.setupWithAppKey(apiKey)
    }

    private func setupCallbacks() {

        $syncDate
            .compactMap { $0 }
            .sink {
                guard case .enabled = TariSettings.shared.walletSettings.dropboxBackupStatus else { return }
                TariSettings.shared.walletSettings.dropboxBackupStatus = .enabled(syncDate: $0)
            }
            .store(in: &cancellables)

        $syncStatus
            .dropFirst()
            .map { $0 != .disabled }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                switch TariSettings.shared.walletSettings.dropboxBackupStatus {
                case .disabled where isEnabled:
                    TariSettings.shared.walletSettings.dropboxBackupStatus = .enabled
                    self?.syncDate = nil
                case .enabled where !isEnabled:
                    TariSettings.shared.walletSettings.dropboxBackupStatus = .disabled
                    self?.syncDate = nil
                default:
                    break
                }

            }
            .store(in: &cancellables)
    }

    // MARK: - Integration

    func handle(url: URL) {

        DropboxClientsManager.handleRedirectURL(url) { [weak self] result in
            guard let dataTask = self?.dataTask, let result = result else { return }

            switch result {
            case .success:
                switch dataTask {
                case .upload:
                    self?.createBackup()
                case .download:
                    self?.downloadBackup(password: nil)
                }
            case .error:
                self?.handle(loginError: .authenticationFailed, task: dataTask)
            case .cancel:
                self?.handle(loginError: .authenticationCancelledByUser, task: dataTask)
            }

            self?.dataTask = nil
        }
    }

    private func handle(loginError: DropboxBackupError, task: DataTask) {

        switch task {
        case .download:
            restoreCompletionSubject?.send(completion: .failure(loginError))
        case .upload:
            syncStatus = .failed(error: loginError)
        }

        syncStatus = .disabled
    }

    // MARK: - Actions

    func turnOn() {
        guard syncStatus == .disabled else { return }
        syncStatus = .enabled
        createBackup()
    }

    func turnOff() {
        syncStatus = .disabled
        logOut()
    }

    func createBackup(password: String?) {

        guard syncStatus != .disabled else { return }

        startBackgroundTask()

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try dropboxClient
                try await uploadFile(password: password)
                self.syncDate = Date()
                self.syncStatus = .enabled
            } catch InternalError.noClient, InternalError.unableToAuthenticateUser {
                self.signIn(task: .upload)
            } catch let error as DropboxBackupError {
                self.syncStatus = .failed(error: error)
            } catch {
                self.syncStatus = .failed(error: DropboxBackupError.unknown)
            }

            self.endBackgroundTask()
        }
    }

    private func downloadBackup(password: String?) {

        Task {
            do {
                _ = try dropboxClient

                guard let backupType = try await checkMetadata() else {
                    throw DropboxBackupError.noBackupToRestore
                }

                if backupType == .encrypted, password == nil {
                    throw DropboxBackupError.backupPasswordRequired
                }

                let backupURL = try await downloadFile(backupType: backupType)
                try await BackupFilesManager.recover(backup: backupURL, password: password)
                syncStatus = .enabled
                restoreCompletionSubject?.send(())
                restoreCompletionSubject?.send(completion: .finished)
            } catch InternalError.noClient, InternalError.unableToAuthenticateUser {
                signIn(task: .download)
            } catch {
                syncStatus = .disabled
                restoreCompletionSubject?.send(completion: .failure(error))
            }

            try BackupFilesManager.removeWorkingDirectory(workingDirectoryName: localWorkingDirectoryName)
        }
    }

    func logOut() {
        DropboxClientsManager.unlinkClients()
        syncStatus = .disabled
    }

    private func createBackup() {
        createBackup(password: backupPassword)
    }

    // MARK: - Account

    private func signIn(task: DataTask) {

        guard let presentingController = presentingController else { return }
        dataTask = task

        DispatchQueue.main.async {
            DropboxClientsManager.authorizeFromControllerV2(
                UIApplication.shared,
                controller: presentingController,
                loadingStatusDelegate: nil,
                openURL: { UIApplication.shared.open($0, options: [:], completionHandler: nil) },
                scopeRequest: ScopeRequest(scopeType: .user, scopes: ["files.content.read", "files.content.write"], includeGrantedScopes: false)
            )
        }
    }

    // MARK: - Folders

    private func createFolderIfNeeded() async throws {
        do {
            try await createFolder()
        } catch let error as InternalError {
            guard error == .folderExist else { throw DropboxBackupError.unknown }
        } catch {
            throw error
        }
    }

    private func createFolder() async throws {

        let client = try dropboxClient

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else { return }

            client.files.createFolderV2(path: self.remoteFolderPath).response(queue: nil) { _, error in

                guard let error = error else {
                    continuation.resume(with: .success(()))
                    return
                }

                let dropboxError = self.map(createFoldersError: error)

                continuation.resume(with: .failure(dropboxError))
            }
        }
    }

    // MARK: - Upload

    private func uploadFile(password: String?) async throws {

        syncStatus = .inProgress(progress: 0.0)

        try await createFolderIfNeeded()
        try BackupFilesManager.removeWorkingDirectory(workingDirectoryName: localWorkingDirectoryName)
        let backupURL = try await BackupFilesManager.prepareBackup(workingDirectoryName: localWorkingDirectoryName, password: password)
        try await upload(fileURL: backupURL)
        try BackupFilesManager.removeWorkingDirectory(workingDirectoryName: localWorkingDirectoryName)
    }

    private func upload(fileURL: URL) async throws {

        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)

        guard let fileSize = fileAttributes[FileAttributeKey.size] as? UInt64, fileSize <= maxSmallFileSize else {
            try await uploadLargeFile(fileURL: fileURL)
            return
        }

        try await uploadSmallFile(fileURL: fileURL)
    }

    private func uploadSmallFile(fileURL: URL) async throws {

        let client = try dropboxClient

        return try await withCheckedThrowingContinuation { [weak self] continuation in

            guard let self = self else { return }
            let remoteFilePath = makeRemoteFilePath(fileName: fileURL.lastPathComponent)

            client.files.upload(path: remoteFilePath, mode: .overwrite, input: fileURL)
                .progress {
                    self.syncStatus = .inProgress(progress: $0.fractionCompleted)
                }
                .response { _, error in

                    guard error != nil else {
                        continuation.resume(with: .success(()))
                        return
                    }

                    continuation.resume(with: .failure(DropboxBackupError.uploadFailed))
                }
        }
    }

    private func uploadLargeFile(fileURL: URL) async throws {

        let client = try dropboxClient

        return try await withCheckedThrowingContinuation { [weak self] continuation in

            guard let self = self else { return }
            let remoteFilePath = makeRemoteFilePath(fileName: fileURL.lastPathComponent)

            var completedProgress: Double = 0.0
            var currentPartProgress: Double = 0.0

            let info = [fileURL: Files.CommitInfo(path: remoteFilePath, mode: .overwrite)]

            client.files.batchUploadFiles(fileUrlsToCommitInfo: info, queue: nil, progressBlock: { [weak self] progress in

                let progressValue = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)

                if progressValue < currentPartProgress {
                    completedProgress += currentPartProgress
                    currentPartProgress = 0.0
                } else {
                    currentPartProgress = progressValue
                }

                let totalProgress = completedProgress + currentPartProgress
                self?.syncStatus = .inProgress(progress: totalProgress)

            }, responseBlock: { _, error, _ in

                guard error != nil else {
                    continuation.resume(with: .success(()))
                    return
                }

                continuation.resume(with: .failure(DropboxBackupError.uploadFailed))
            })
        }
    }

    // MARK: - Download

    private func checkMetadata() async throws -> BackupType? {

        let client = try dropboxClient

        return try await withCheckedThrowingContinuation { [weak self] continuation in

            guard let self else { return }

            let group = DispatchGroup()

            var encryptedFileTimestamp: Date?
            var encryptedFileError: CallError<Files.GetMetadataError>?
            var unencryptedFileTimestamp: Date?
            var unencryptedFileError: CallError<Files.GetMetadataError>?

            group.enter()
            client.files
                .getMetadata(path: makeRemoteFilePath(fileName: BackupFilesManager.encryptedFileName))
                .response { metadata, error in
                    encryptedFileTimestamp = (metadata as? Files.FileMetadata)?.serverModified
                    encryptedFileError = error
                    group.leave()
            }

            group.enter()
            client.files
                .getMetadata(path: makeRemoteFilePath(fileName: BackupFilesManager.unencryptedFileName))
                .response { metadata, error in
                    unencryptedFileTimestamp = (metadata as? Files.FileMetadata)?.serverModified
                    unencryptedFileError = error
                    group.leave()
            }

            group.notify(queue: .main) { [weak self] in

                let error = [encryptedFileError, unencryptedFileError]
                    .compactMap { $0 }
                    .compactMap { self?.map(metadataError: $0) }
                    .first

                if let error = error {
                    continuation.resume(with: .failure(error))
                    return
                }

                switch (encryptedFileTimestamp, unencryptedFileTimestamp) {
                case (nil, nil):
                    continuation.resume(with: .success(nil))
                case (nil, _):
                    continuation.resume(with: .success(.unencrypted))
                case (_, nil):
                    continuation.resume(with: .success(.encrypted))
                default:
                    guard let encryptedFileTimestamp = encryptedFileTimestamp, let unencryptedFileTimestamp = unencryptedFileTimestamp else { return }
                    guard encryptedFileTimestamp.timeIntervalSince1970 > unencryptedFileTimestamp.timeIntervalSince1970 else {
                        continuation.resume(with: .success(.unencrypted))
                        return
                    }
                    continuation.resume(with: .success(.encrypted))
                }

            }
        }
    }

    private func downloadFile(backupType: BackupType) async throws -> URL {

        let client = try dropboxClient
        let remoteFilePath = makeRemoteFilePath(backupType: backupType)

        return try await withCheckedThrowingContinuation { [weak self] continuation in

            guard let self = self else { return }
            let temporaryBackupURL: URL

            do {
                temporaryBackupURL = try self.makeTemporaryBackupURL(backupType: backupType)
            } catch {
                continuation.resume(with: .failure(DropboxBackupError.unableToCreateTempFolder))
                return
            }

            client.files
                .download(path: remoteFilePath, overwrite: true) { _, _ in temporaryBackupURL }
                .response { _, error in
                    guard error != nil else {
                        continuation.resume(with: .success(temporaryBackupURL))
                        return
                    }

                    continuation.resume(with: .failure(DropboxBackupError.downloadFailed))
                }
        }
    }

    // MARK: - Helpers

    private func makeRemoteFilePath(fileName: String) -> String { "\(remoteFolderPath)/\(fileName)" }
    private func makeRemoteFilePath(backupType: BackupType) -> String { "\(remoteFolderPath)/\(makeFilename(backupType: backupType))" }

    private func makeTemporaryBackupURL(backupType: BackupType) throws -> URL {
        try BackupFilesManager.removeWorkingDirectory(workingDirectoryName: localWorkingDirectoryName)
        let workingDirectory = try BackupFilesManager.prepareWorkingDirectory(name: localWorkingDirectoryName)
        let filename = makeFilename(backupType: backupType)
        return workingDirectory.appendingPathComponent(filename)
    }

    private func makeFilename(backupType: BackupType) -> String {
        switch backupType {
        case .encrypted:
            return BackupFilesManager.encryptedFileName
        case .unencrypted:
            return BackupFilesManager.unencryptedFileName
        }
    }

    private func startBackgroundTask() {
        Tari.shared.isDisconnectionDisabled = true
        backgroundTaskID = UIApplication.shared.beginBackgroundTask()
    }

    private func endBackgroundTask() {
        guard let backgroundTaskID = backgroundTaskID else { return }
        Tari.shared.isDisconnectionDisabled = false
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        self.backgroundTaskID = nil
    }

    // MARK: - Error Mappers

    private func map(createFoldersError: CallError<Files.CreateFolderError>) -> Error {

        switch createFoldersError {

        case let .routeError(error, _, _, _):
            switch error.unboxed {
            case .path:
                return InternalError.folderExist
            }
        case .authError:
            return InternalError.unableToAuthenticateUser
        default:
            return DropboxBackupError.unknown
        }
    }

    private func map(metadataError: CallError<Files.GetMetadataError>) -> DropboxBackupError? {
        guard case let .routeError(error, _, _, _) = metadataError, case let .path(lookUpError) = error.unboxed, case .notFound = lookUpError else {
            return .downloadFailed
        }
        return nil
    }
}

extension DropboxBackupService: BackupServicable {

    var password: String? {
        get { backupPassword }
        set { backupPassword = newValue }
    }

    var isOn: Bool {
        get { syncStatus != .disabled }
        set { newValue ? turnOn() : turnOff() }
    }

    var backupStatus: AnyPublisher<BackupStatus, Never> {
        $syncStatus.eraseToAnyPublisher()
    }

    var lastBackupTimestamp: AnyPublisher<Date?, Never> {
        $syncDate.eraseToAnyPublisher()
    }

    func performBackup(forced: Bool) {
        guard isOn else { return }
        guard forced || syncStatus.isFailed else { return }
        createBackup(password: backupPassword)
    }

    func restoreBackup(password: String?) -> AnyPublisher<Void, Error> {

        defer { downloadBackup(password: password) }

        let subject = PassthroughSubject<Void, Error>()

        restoreCompletionSubject = subject

        return subject
            .mapError {
                guard let dropboxError = $0 as? DropboxBackupError, dropboxError == .backupPasswordRequired else { return $0 }
                return BackupError.passwordRequired
            }
            .eraseToAnyPublisher()
    }
}
