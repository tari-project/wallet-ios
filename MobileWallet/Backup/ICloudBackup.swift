//  Backup.swift

/*
 Package MobileWallet
 Created by S.Shovkoplyas on 04.06.2020
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
import Reachability
import ZIPFoundation

enum ICloudBackupError: Error {
    case failedToCreateZip
    case noICloudBackupExists
    case unarchiveError
    case invalidPassword
    case dbFileNotFound
    case iCloudContainerNotFound
    case unableCreateBackupFolder
    case keychainPasswordFailure
    case uploadToICloudFailure
    case noInternetConnection
    case unableToDetermineDateOfBackup
    case backupUrlNotValid
}

enum ICloudBackupState {
    case upToDate
    case outOfDate
    case inProgress
    case scheduled

    var rawValue: String {
        switch self {
        case .upToDate: return localized("wallet_backup_state.up_to_date")
        case .outOfDate: return localized("wallet_backup_state.out_to_date")
        case .inProgress: return localized("wallet_backup_state.in_progress")
        case .scheduled: return localized("wallet_backup_state.scheduled")
        }
    }
}

extension ICloudBackupError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .failedToCreateZip:
            return localized("iCloud_backup.error.zip")
        case .noICloudBackupExists:
            return localized("iCloud_backup.error.no_backup_exists")
        case .unarchiveError:
            return localized("iCloud_backup.error.unzip")
        case .invalidPassword:
            return localized("iCloud_backup.error.invalid_password")
        case .dbFileNotFound:
            return localized("iCloud_backup.error.db_not_found")
        case .iCloudContainerNotFound:
            return localized("iCloud_backup.error.container_not_found")
        case .unableCreateBackupFolder:
            return localized("iCloud_backup.error.unable_create_backup_folder")
        case .keychainPasswordFailure:
            return localized("iCloud_backup.error.keychain_password_failure")
        case .uploadToICloudFailure:
            return localized("iCloud_backup.error.upload_to_iCloud_failure")
        case .noInternetConnection:
            return localized("iCloud_backup.error.no_internet_connection")
        case .unableToDetermineDateOfBackup:
            return localized("iCloud_backup.error.unable_determine_backup_date")
        case .backupUrlNotValid:
            return localized("iCloud_backup.error.backup_url_not_valid")
        }
    }

    public var failureReason: String? {
        switch self {
        case .uploadToICloudFailure:
            return localized("iCloud_backup.error.title.iCloud_synch")
        default:
            return localized("iCloud_backup.error.title.create_backup")
        }
    }
}

protocol ICloudBackupObserver: AnyObject {
    func onUploadProgress(percent: Double, started: Bool, completed: Bool)
    func failedToCreateBackup(error: Error)
}

class ICloudBackup: NSObject {

    private var reachability: Reachability?
    private var query = NSMetadataQuery()

    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    private var directory: URL { TariLib.shared.connectedDatabaseDirectory }
    private let fileName = "Tari-Aurora-Backup"
    private var observers = NSPointerArray.weakObjects()

    private(set) var inProgress: Bool = false
    private(set) var progressValue: Double = 0.0
    private var uploadTimer: Timer?

    private let uploadTimeoutSec = 20.0

    private(set) var isLastBackupFailed: Bool {
        get {
            return UserDefaults.Key.isLastBackupFailed.boolValue()
        }
        set {
            UserDefaults.Key.isLastBackupFailed.set(newValue)
        }
    }

    var iCloudBackupsIsOn: Bool {
        get { TariSettings.shared.walletSettings.isCloudBackupEnabled }
        set {
            TariSettings.shared.walletSettings.isCloudBackupEnabled = newValue
            newValue ? BackupScheduler.shared.startObserveEvents() : BackupScheduler.shared.stopObserveEvents()
        }
    }

    var lastBackup: Backup? {
        do {
            return try getLastWalletBackup()
        } catch {
            return nil
        }
    }

    static let shared = ICloudBackup()

    override init() {
        super.init()

        #if targetEnvironment(simulator)
        return
        #endif

        initialiseQuery()
        addNotificationObservers()
        try? startObserveReachability()

        if FileManager.default.ubiquityIdentityToken == nil {
            TariSettings.shared.walletSettings.isCloudBackupEnabled = false
        }
    }

    private func initialiseQuery() {
        query = NSMetadataQuery.init()
        query.operationQueue = .main
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        query.predicate = NSPredicate(
            format: "%K LIKE '\(fileName)*'",
            NSMetadataItemFSNameKey
        )
    }

    func addObserver(_ observer: ICloudBackupObserver) {
        observers.addObject(observer)
    }

    func removeObserver(_ observer: ICloudBackupObserver) {
        observers.remove(observer)
    }

    // returns true if backup of current wallet is exist and is valid
    func isValidBackupExists() -> Bool {
        return lastBackup?.isValid ?? false
    }

    func createWalletBackup(password: String?) throws {
        UserDefaults.Key.backupOperationAborted.set(false)
        do {
            if inProgress { query.stop(); inProgress = false }

            let remoteBackupURL = try remoteBackupURL()

            let fileURL: URL
            if let password = password {
                fileURL = try getZippedAndEncryptedWalletDatabase(password: password)
            } else {
                fileURL = try zipWalletDatabase()
            }

            if !FileManager.default.fileExists(atPath: remoteBackupURL.path) {
                try FileManager.default.createDirectory(
                    at: remoteBackupURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }

            if let previousBackupURL = try FileManager.default.contentsOfDirectory(
                atURL: remoteBackupURL,
                sortedBy: .created
            ).last {
                try FileManager.default.removeItem(at: previousBackupURL)
            }

            try FileManager.default.copyItem(
                at: fileURL,
                to: remoteBackupURL.appendingPathComponent(fileURL.lastPathComponent)
            )
            isLastBackupFailed = false
            inProgress = true
            progressValue = 0.0
            BackupScheduler.shared.removeSchedule()
            notifyObservers(
                percent: 0,
                started: true,
                completed: false,
                error: nil
            )

            syncWithICloud()
        } catch {
            inProgress = false
            isLastBackupFailed = true
            try cleanTempDirectory()
            throw error
        }
    }

    func restoreWallet(password: String?, completion: @escaping (_ error: Error?) -> Void) {
        let dbDirectory = TariLib.shared.connectedDatabaseDirectory
        do {
            try FileManager.default.createDirectory(
                at: dbDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            restoreBackup(password: password, to: dbDirectory) { [weak self] error in
                if error == nil {
                    TariSettings.shared.walletSettings.configurationState = .authorized
                    self?.iCloudBackupsIsOn = true

                    BackupScheduler.shared.startObserveEvents()

                    if password != nil {
                        AppKeychainWrapper.setBackupPasswordToKeychain(password: password!)
                    }
                } else {
                    do {
                        try FileManager.default.removeItem(at: dbDirectory)
                    } catch {
                        completion(error)
                        return
                    }
                }
                completion(error)
            }
        } catch {
            completion(error)
        }
    }

    func removeCurrentWalletBackup() {
        if TariLib.shared.walletPublicKeyHex != nil {
            do {
                try FileManager.default.removeBackup(getLastWalletBackup())
            } catch {
                TariLogger.error("Failed to remove wallet backup", error: error)
            }
        }
    }
}

// MARK: Reachability
extension ICloudBackup {
    private func startObserveReachability() throws {
        reachability = try Reachability()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reachabilityChanged(note:)),
            name: .reachabilityChanged,
            object: reachability
        )
        try reachability?.startNotifier()
    }

    @objc private func reachabilityChanged(note: Notification) {
        syncWithICloud()
    }

    private func stopObserveReachability() {
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(
            self,
            name: .reachabilityChanged,
            object: reachability
        )
    }
}

// MARK: - uploading to iCloud observation

extension ICloudBackup {
    private func addNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSMetadataQueryDidStartGathering,
            object: query,
            queue: query.operationQueue
        ) {
            [weak self] (_) in
            self?.processCloudFiles()
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSMetadataQueryDidUpdate,
            object: query,
            queue: query.operationQueue
        ) {
            [weak self] (_) in
            self?.processCloudFiles()
        }
    }

    private func processCloudFiles() {
        if query.resultCount == 0 { return }
        var fileItem: NSMetadataItem?
        var fileURL: URL?

        for item in query.results {
            guard let item = item as? NSMetadataItem else { continue }
            guard let fileItemURL = item.value(
                    forAttribute: NSMetadataItemURLKey
            ) as? URL else { continue }
            if fileItemURL.lastPathComponent.contains(fileName) {
                fileItem = item
                fileURL = fileItemURL
            }
        }

        guard let url = fileURL  else { return }
        do {
            let fileValues = try url.resourceValues(
                forKeys: [URLResourceKey.ubiquitousItemIsUploadingKey]
            )
            if let fileUploaded = fileItem?.value(forAttribute: NSMetadataUbiquitousItemIsUploadedKey) as? Bool,
               fileUploaded == true,
               fileValues.ubiquitousItemIsUploading == false {
                progressValue = 0.0
                inProgress = false
                notifyObservers(percent: 100, completed: true, error: nil)
                uploadTimer?.invalidate()
                uploadTimer = nil
                try cleanTempDirectory()
                query.disableUpdates()
            } else if let error = fileValues.ubiquitousItemUploadingError {
                progressValue = 0.0
                inProgress = false
                isLastBackupFailed = true
                notifyObservers(percent: 0, completed: false, error: error)
                query.disableUpdates()
            } else {
                if let fileProgress = fileItem?.value(
                    forAttribute: NSMetadataUbiquitousItemPercentUploadedKey
                ) as? Double {
                    progressValue = fileProgress
                    notifyObservers(percent: fileProgress, completed: false, error: nil)
                }
            }
        } catch {
            isLastBackupFailed = true
            inProgress = false
            uploadTimer?.invalidate()
            uploadTimer = nil
            notifyObservers(
                percent: 0,
                completed: false,
                error: ICloudBackupError.noInternetConnection
            )
        }
    }

    private func enableUploadTimeout() {
        var previousUploadValue = 0.0
        uploadTimer = Timer.scheduledTimer(
            withTimeInterval: uploadTimeoutSec,
            repeats: true
        ) {
            [weak self] (timer) in
            guard let self = self, previousUploadValue == self.progressValue else {
                timer.invalidate()
                return
            }
            if previousUploadValue == self.progressValue {
                self.stopSyncWithConnectionError()
                timer.invalidate()
                self.uploadTimer = nil
            }
            if !self.inProgress {
                timer.invalidate()
                self.uploadTimer = nil
            }
            previousUploadValue = self.progressValue
        }
    }

    private func notifyObservers(
        percent: Double,
        started: Bool = false,
        completed: Bool,
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.observers.allObjects.forEach {
                if let object = $0 as? ICloudBackupObserver {
                    object.onUploadProgress(
                        percent: percent,
                        started: started,
                        completed: completed
                    )
                    if error != nil {
                        object.failedToCreateBackup(error: error!)
                        self.showError(error: error!)
                    }
                }
                if completed {
                    self.endBackgroundBackupTask()
                }
            }
        }
    }

    private func showError(error: Error) {
        // check for scheduled backup for decide which notification use,
        // "push" ot "modal view"
        if BackupScheduler.shared.scheduledBackupStarted { return }

        var title = localized("iCloud_backup.error.title.create_backup")
        if let localizedError = error as? LocalizedError,
           localizedError.failureReason != nil {
           title = localizedError.failureReason!
        }
        PopUpPresenter.show(message: MessageModel(title: title, message: error.localizedDescription, type: .error))
    }
}

// MARK: - background backup
extension ICloudBackup {
    func backgroundBackupWallet() {
        if !inProgress && !BackupScheduler.shared.isBackupScheduled {
            return
        }

        TariLogger.info("Starting iCloud backup in the background")

        // Perform the task on a background queue.
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            // Request the task assertion and save the ID.
            self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "Finish Backup Task") {
                // Expiration handler.
                self.scheduleNotification()
            }

            let password = AppKeychainWrapper.loadBackupPasswordFromKeychain()
            do {
                try self.createWalletBackup(password: password)
            } catch {
                TariLogger.error("Failed to create wallet backup", error: error)
                self.endBackgroundBackupTask()
            }
        }
    }

    private func endBackgroundBackupTask() {
        if let id = backgroundTaskIdentifier {
            UIApplication.shared.endBackgroundTask(id)
        }
        self.backgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    }

    func scheduleNotification() {
        let title = localized("backup_local_notification.title")
        let body = localized("backup_local_notification.body")
        NotificationManager.shared.scheduleNotification(
            title: title,
            body: body,
            identifier: NotificationManager.NotificationIdentifier.backgroundBackupTask.rawValue
        ) { (_) in
            TariLogger.info("User reminded to open the app as a background backup did not complete.")
            self.endBackgroundBackupTask()
        }
    }
}

// MARK: - private methods
extension ICloudBackup {

    private func syncWithICloud() {
        checkNetworkConnection {
            [weak self] (connected) in
            guard let self = self else { return }
            if connected {
                self.query.operationQueue?.addOperation {
                    [weak self] in
                    _ = self?.query.start()
                    self?.query.enableUpdates()
                    self?.enableUploadTimeout()
                }
            } else {
                self.stopSyncWithConnectionError()
            }
        }
    }

    private func stopSyncWithConnectionError() {
        if !self.inProgress { return }
        self.query.stop()
        self.inProgress = false
        self.isLastBackupFailed = true
        self.notifyObservers(
            percent: 0,
            completed: false,
            error: ICloudBackupError.noInternetConnection
        )
    }

    private func checkNetworkConnection(completion: @escaping (_ connected: Bool) -> Void) {
        let speedTest = NetworkSpeedProvider()
        speedTest.testSpeed { (_ speed: Float, _ error: Error?) in
            if speed <= 0 || error != nil { completion(false) }

            guard let reachability = self.reachability else {
                completion(false); return
            }
            switch reachability.connection {
            case .wifi, .cellular:
                completion(true)
            case .unavailable, .none:
                completion(false)
            }
        }
    }

    private func restoreBackup(
        password: String?,
        to directory: URL,
        completion: @escaping ((_ error: Error?) -> Void)
    ) {
        downloadBackup {
            [weak self] (backup, error) in
            guard let backup = backup, error == nil else {
                completion(error)
                return
            }
            let zippedBackup: Backup

            if backup.isEncrypted {
                do {
                    guard
                        let password = password,
                        let zippedDecryptedBackup = try self?.decryptBackup(
                            password: password,
                            encryptedBackup: backup
                        )
                    else {
                        completion(ICloudBackupError.unarchiveError)
                        return
                    }
                    zippedBackup = zippedDecryptedBackup
                } catch {
                    completion(error)
                    return
                }
            } else {
                zippedBackup = backup
            }

            do {
                let filePaths = try FileManager.default.contentsOfDirectory(atPath: directory.path)
                for filePath in filePaths {
                    try FileManager.default.removeItem(
                        atPath: directory.appendingPathComponent(filePath).path
                    )
                }

                try FileManager.default.unzipItem(
                    at: zippedBackup.url,
                    to: directory
                )
                completion(nil)
            } catch {
                switch error {
                case Archive.ArchiveError.unreadableArchive: do {
                    completion(ICloudBackupError.invalidPassword)
                    }
                default: completion(error)
                }
            }
        }
    }

    private func downloadBackup(completion: @escaping ((_ backup: Backup?, _ error: Error?) -> Void)) {
        do {
            let backup = try getLastWalletBackup()
            var lastPathComponent = backup.url.lastPathComponent
            let folderPath = backup.folderPath
            // if the last path component contains the “.icloud” extension.
            // If yes the file is not on the device else the file is already downloaded.
            if lastPathComponent.contains(".icloud") {
                checkNetworkConnection { (connected) in
                    if !connected { completion(nil, ICloudBackupError.noInternetConnection) }

                    lastPathComponent.removeFirst()
                    let downloadedFilePath =
                        folderPath
                        + "/"
                        + lastPathComponent.replacingOccurrences(of: ".icloud", with: "")
                    do {
                        try FileManager.default.startDownloadingUbiquitousItem(at: backup.url)
                    } catch {
                        completion(nil, ICloudBackupError.noInternetConnection)
                    }

                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
                        (timer) in
                        if FileManager.default.fileExists(atPath: downloadedFilePath) {
                            timer.invalidate()
                            do {
                                let backup = try Backup(
                                    url: URL(fileURLWithPath: downloadedFilePath)
                                )
                                completion(backup, nil)
                            } catch {
                                completion(nil, error)
                            }
                        }
                    }
                }
            } else {
                completion(backup, nil)
            }
        } catch {
            completion(nil, error)
        }
    }

    private func getLastWalletBackup() throws -> Backup {
        let iCloudFolderURL = try iCloudDirectory().appendingPathComponent(NetworkManager.shared.selectedNetwork.name)
        do {
            // if walletKeyHex != nil we find last backup for current wallet
            if let walletKeyHex = TariLib.shared.walletPublicKeyHex {
                if let lastWalletFolder = try FileManager.default.contentsOfDirectory(
                    atURL: iCloudFolderURL,
                    sortedBy: .created,
                    options: []
                ).last(where: { (url) -> Bool in
                    url.lastPathComponent == walletKeyHex
                }) {
                    if let lastWalletBackup = try FileManager.default.contentsOfDirectory(
                        atURL: lastWalletFolder,
                        sortedBy: .created,
                        options: []
                    ).last {
                        return try Backup(url: lastWalletBackup)
                    }
                }
            } else {
                if let lastWalletFolder = try FileManager.default.contentsOfDirectory(
                    atURL: iCloudFolderURL,
                    sortedBy: .modified,
                    options: []
                ).last {
                    if let lastWalletBackup = try FileManager.default.contentsOfDirectory(
                        atURL: lastWalletFolder,
                        sortedBy: .created,
                        options: []
                    ).last {
                        return try Backup(url: lastWalletBackup)
                    }
                }
            }
        } catch {
            throw ICloudBackupError.noICloudBackupExists
        }
        throw ICloudBackupError.noICloudBackupExists
    }

    private func zipWalletDatabase() throws -> URL {

        defer { try? TariLib.shared.tariWallet?.enableEncryption() }
        try TariLib.shared.tariWallet?.disableEncryption()

        let archiveName = fileName + ".zip"
        let tmpDirectory = try getTempDirectory()
        let archiveURL = tmpDirectory.appendingPathComponent(archiveName)

        if FileManager.default.fileExists(atPath: archiveURL.path) {
            try FileManager.default.removeItem(atPath: archiveURL.path)
        }

        let sqlite3File = TariLib.shared.connectedDatabaseName.appending(".sqlite3")
        let originalFileURL = directory.appendingPathComponent(sqlite3File)
        let dbDirectory = TariSettings.shared.isUnitTesting ? try getTestDataBaseUrl() : originalFileURL

        try FileManager().zipItem(
            at: dbDirectory,
            to: archiveURL,
            compressionMethod: .deflate
        )
        return archiveURL
    }

    private func getZippedAndEncryptedWalletDatabase(password: String) throws -> URL {
        let zipURL = try zipWalletDatabase()
        let data = try Data(contentsOf: zipURL)

        let aes = try AESEncryption(keyString: password)

        let encryptedData = try aes.encrypt(data)
        let fileURL = try getTempDirectory().appendingPathComponent(fileName)
        try encryptedData.write(to: fileURL)

        return fileURL
    }

    private func decryptBackup(password: String, encryptedBackup: Backup) throws -> Backup {
        let data = try Data(contentsOf: encryptedBackup.url)
        let aes = try AESEncryption(keyString: password)

        let decryptedZipUrl = try getTempDirectory().appendingPathComponent(fileName + ".zip")

        let decryptedData = try aes.decrypt(data)
        try decryptedData.write(to: decryptedZipUrl)

        return try Backup(url: decryptedZipUrl)
    }

    private func iCloudDirectory() throws -> URL {
        guard let url = FileManager.default.url(
                forUbiquityContainerIdentifier: TariSettings.shared.iCloudContainerIdentifier
        )?.appendingPathComponent("Tari-Wallet-Backups") else {
            throw ICloudBackupError.iCloudContainerNotFound
        }
        return url
    }

    private func remoteDirectoryPath() throws -> String {
        guard let publicKey = TariLib.shared.walletPublicKeyHex else { throw ICloudBackupError.unableCreateBackupFolder }
        return "\(NetworkManager.shared.selectedNetwork.name)/\(publicKey)"
    }

    private func remoteBackupURL() throws -> URL {
        let mainDirectory = try iCloudDirectory()
        let backupPath = try remoteDirectoryPath()
        return mainDirectory.appendingPathComponent(backupPath)
    }

    private func getTempDirectory() throws -> URL {
        if let tempZipDirectory = FileManager.default.documentDirectory()?.appendingPathComponent("Backups") {
            if !FileManager.default.fileExists(atPath: tempZipDirectory.path) {
                try FileManager.default.createDirectory(
                    at: tempZipDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
            return tempZipDirectory
        } else { throw ICloudBackupError.failedToCreateZip }
    }

    private func cleanTempDirectory() throws {
        let directory = try getTempDirectory()
        try FileManager.default.removeItem(at: directory)
    }
}

// MARK: Tests
extension ICloudBackup {
    func getTestDataBaseUrl() throws -> URL {
        let dbURL = URL(
            fileURLWithPath: TariSettings.testStoragePath
        ).appendingPathComponent("test_db.sqlite3")
        return dbURL
    }
}
