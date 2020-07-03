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

enum ICloudBackupWalletError: Error {
    case failedToCreateZip
    case noICloudBackupExists
    case unarchiveError
    case dbFileNotFound
    case iCloudContainerNotFound
    case unableCreateBackupFolder
    case keychainPasswordFailture
    case uploadToICloudFailture
    case noInternetConnection
}

enum ICloudBackupState {
    case upToDate
    case outOfDate
    case inProgress

    var rawValue: String {
        switch self {
        case .upToDate: return NSLocalizedString("wallet_backup_state.up_to_date", comment: "Wallet backup state")
        case .outOfDate: return NSLocalizedString("wallet_backup_state.out_to_date", comment: "Wallet backup state")
        case .inProgress: return NSLocalizedString("wallet_backup_state.in_progress", comment: "Wallet backup state")
        }
    }
}

extension ICloudBackupWalletError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .failedToCreateZip:
            return NSLocalizedString("iCloud_backup.error.zip", comment: "iCloudBackup error")
        case .noICloudBackupExists:
            return NSLocalizedString("iCloud_backup.error.no_backup_exists", comment: "iCloudBackup error")
        case .unarchiveError:
            return NSLocalizedString("iCloud_backup.error.unzip", comment: "iCloudBackup error")
        case .dbFileNotFound:
            return NSLocalizedString("iCloud_backup.error.db_not_found", comment: "iCloudBackup error")
        case .iCloudContainerNotFound:
            return NSLocalizedString("iCloud_backup.error.container_not_found", comment: "iCloudBackup error")
        case .unableCreateBackupFolder:
            return NSLocalizedString("iCloud_backup.error.unable_create_backup_folder", comment: "iCloudBackup error")
        case .keychainPasswordFailture:
            return NSLocalizedString("iCloud_backup.error.keychain_password_failture", comment: "iCloudBackup error")
        case .uploadToICloudFailture:
            return NSLocalizedString("iCloud_backup.error.upload_to_iCloud_failture", comment: "iCloudBackup error")
        case .noInternetConnection:
            return NSLocalizedString("iCloud_backup.error.no_internet_connection", comment: "iCloudBackup error")
        }
    }

    public var failureReason: String? {
        switch self {
        case .uploadToICloudFailture:
            return NSLocalizedString("iCloud_backup.error.title.iCloud_synch", comment: "iCloudBackup error")
        default:
            return NSLocalizedString("iCloud_backup.error.title.create_backup", comment: "iCloudBackup error")
        }
    }
}

protocol ICloudBackupObserver: AnyObject {
    func onUploadProgress(percent: Double, completed: Bool, error: Error?)
}

class ICloudBackup: NSObject {

    private var reachability: Reachability?

    private var query = NSMetadataQuery()

    private let directory = TariLib.shared.databaseDirectory
    private let fileName = "Tari-Aurora-Backup"
    private var observers = NSPointerArray.weakObjects()

    private(set) var inProgress: Bool = false
    private(set) var progressValue: Double = 0.0

    private(set) var isLastBackupFailed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isLastBackupFailed")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isLastBackupFailed")
        }
    }

    var lastBackupString: String? {
        if let date = lastBackupDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd yyy 'at' HH:mm a"
            dateFormatter.timeZone = .current

            let dateString = dateFormatter.string(from: date)
            return dateString
        }
        return nil
    }

    var lastBackupDate: Date? {
        do {
            guard let backupFolder = TariLib.shared.tariWallet?.publicKey.0?.hex.0 else { return nil }
            let iCloudFolderURL = try iCloudDirectory().appendingPathComponent(backupFolder)
            if let last = try FileManager.default.contentsOfDirectory(atURL: iCloudFolderURL, sortedBy: .created, options: []).last {
                guard let date = try last.resourceValues(forKeys: [.creationDateKey]).allValues.first?.value as? Date else { return nil }
                return date
            }
            return nil
        } catch {
            return nil
        }
    }

    static let shared = ICloudBackup()

    override init() {
        super.init()
        initialiseQuery()
        addNotificationObservers()
        try? startObserveReachabilityChanges()
    }

    private func initialiseQuery() {
        query = NSMetadataQuery.init()
        query.operationQueue = .main
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        query.predicate = NSPredicate(format: "%K LIKE '\(fileName)*'", NSMetadataItemFSNameKey)
    }

    func addObserver(_ observer: ICloudBackupObserver) {
        observers.addObject(observer)
    }

    // returns true if backup of current wallet is exist
    func backupExists() -> Bool {
        if isLastBackupFailed { return false }
        if inProgress { return false }
        let fileManager = FileManager.default
        guard let backupFolder = TariLib.shared.tariWallet?.publicKey.0?.hex.0 else { return false }

        do {
            let iCloudFolderURL = try iCloudDirectory()

            if let urls = try? fileManager.contentsOfDirectory(at: iCloudFolderURL, includingPropertiesForKeys: nil, options: []) {
                if let _ = urls.first(where: { $0.absoluteString.contains(backupFolder) }) { return true }
            }
        } catch {
            return false
        }

        return false
    }

    func createWalletBackup(password: String?) throws {
        do {
            if inProgress { query.stop(); inProgress = false }

            guard let backupFolder = TariLib.shared.tariWallet?.publicKey.0?.hex.0 else { throw ICloudBackupWalletError.iCloudContainerNotFound }

            let fileURL: URL
            if let keyString = password {
                fileURL = try encryptedZipWalletDatabase(keyString: keyString)
            } else {
                fileURL = try zipWalletDatabase()
            }

            let containerURL = try iCloudDirectory().appendingPathComponent(backupFolder)

            if !FileManager.default.fileExists(atPath: containerURL.path) {
                try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
            }
            let backupFileURL = containerURL.appendingPathComponent(fileURL.lastPathComponent)

            if FileManager.default.fileExists(atPath: backupFileURL.path) {
                try FileManager.default.replaceItem(at: backupFileURL,
                                                    withItemAt: fileURL,
                                                    backupItemName: fileURL.lastPathComponent,
                                                    options: .usingNewMetadataOnly,
                                                    resultingItemURL: nil)
            } else {
                try FileManager.default.copyItem(at: fileURL, to: backupFileURL)
            }
            inProgress = true
            progressValue = 0.0

            synchWithiCloud()
        } catch {
            inProgress = false
            isLastBackupFailed = true
            throw error
        }
    }

    func restoreWallet(completion: @escaping (_ error: Error?) -> Void) {
        let dbDirectory = TariLib.shared.databaseDirectory

        do {
            let walletFolder = try getLastWalletBackupFolder()
            try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true, attributes: nil)

            restoreBackup(walletFolder: walletFolder, to: dbDirectory) { error in
                if error == nil {
                    Migrations.handle()
                }
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
}

// MARK: Reachability
extension ICloudBackup {
    private func startObserveReachabilityChanges() throws {
        reachability = try Reachability()
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        try reachability?.startNotifier()
    }

    @objc private func reachabilityChanged(note: Notification) {
        synchWithiCloud()
    }
    private func stopReachability() {
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
    }
}

// MARK: - uploading to iCloud observation

extension ICloudBackup {
    private func addNotificationObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidStartGathering, object: query, queue: query.operationQueue) { [weak self] (_) in
            self?.notifyObservers(percent: 0, completed: false, error: nil)
            self?.processCloudFiles()
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: query, queue: query.operationQueue) { [weak self] (_) in
            self?.processCloudFiles()
        }
    }

    private func processCloudFiles() {
        if query.resultCount == 0 { return }
        var fileItem: NSMetadataItem?
        var fileURL: URL?

        for item in query.results {
            guard let item = item as? NSMetadataItem else { continue }
            guard let fileItemURL = item.value(forAttribute: NSMetadataItemURLKey) as? URL else { continue }
            if fileItemURL.lastPathComponent.contains(fileName) {
                fileItem = item
                fileURL = fileItemURL
            }
        }
        guard let url = fileURL  else { return }
        do {
            let fileValues = try url.resourceValues(forKeys: [URLResourceKey.ubiquitousItemIsUploadingKey])
            if let fileUploaded = fileItem?.value(forAttribute: NSMetadataUbiquitousItemIsUploadedKey) as? Bool, fileUploaded == true, fileValues.ubiquitousItemIsUploading == false {
                progressValue = 0.0
                inProgress = false
                isLastBackupFailed = false
                notifyObservers(percent: 100, completed: true, error: nil)
                try cleanTempDirectory()
            } else if let error = fileValues.ubiquitousItemUploadingError {
                progressValue = 0.0
                inProgress = false
                isLastBackupFailed = true
                notifyObservers(percent: 0, completed: false, error: error)
            } else {
                if let fileProgress = fileItem?.value(forAttribute: NSMetadataUbiquitousItemPercentUploadedKey) as? Double {
                    progressValue = fileProgress
                    notifyObservers(percent: fileProgress, completed: false, error: nil)
                }
            }
        } catch {
            isLastBackupFailed = true
            inProgress = false
            notifyObservers(percent: 0, completed: false, error: ICloudBackupWalletError.uploadToICloudFailture)
        }
    }

    private func notifyObservers(percent: Double, completed: Bool, error: Error?) {
        observers.allObjects.forEach {
            if let object = $0 as? ICloudBackupObserver {
                object.onUploadProgress(percent: percent, completed: completed, error: error)
            }
        }
    }
}

// MARK: - private methods
extension ICloudBackup {

    private func synchWithiCloud() {
        if isInternetConnection() {
            query.operationQueue?.addOperation({ [weak self] in
                _ = self?.query.start()
                self?.query.enableUpdates()
            })
        } else {
            if !inProgress { return }
            query.stop()
            inProgress = false
            if backupExists() {
                isLastBackupFailed = false
                notifyObservers(percent: 100, completed: true, error: ICloudBackupWalletError.uploadToICloudFailture)
            }
        }
    }

    private func isInternetConnection() -> Bool {
        guard let reachability = self.reachability else { return false }
        switch reachability.connection {
        case .wifi, .cellular:
            return true
        case .unavailable, .none:
            return false
        }
    }

    private func restoreBackup(walletFolder: String, to directory: URL, completion: @escaping ((_ error: Error?) -> Void)) {
        downloadBackup(walletFolder: walletFolder) { [weak self] (url, error) in
            guard let backupURL = url, error == nil else {
                completion(error)
                return
            }

            let isBackupEncrypted = backupURL.pathExtension.isEmpty

            let zippedBackupURL: URL
            if isBackupEncrypted {
                do {
                    guard let zippedURL = try self?.decryptedZipWalletDatabase(encryptedFileUrl: backupURL) else {
                        completion(ICloudBackupWalletError.unarchiveError)
                        return
                    }
                    zippedBackupURL = zippedURL
                } catch {
                    completion(error)
                    return
                }
            } else {
                zippedBackupURL = backupURL
            }

            do {
                try FileManager.default.unzipItem(at: zippedBackupURL, to: directory)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    private func downloadBackup(walletFolder: String, completion: @escaping ((_ url: URL?, _ error: Error?) -> Void)) {
        let iCloudFolderURL: URL!
        var urls = [URL]()

        do {
            iCloudFolderURL = try iCloudDirectory().appendingPathComponent(walletFolder)
            urls = try FileManager.default.contentsOfDirectory(atURL: iCloudFolderURL, sortedBy: .created, options: [])
        } catch {
            completion(nil, error)
        }

        if let backupUrl = urls.last {
            var lastPathComponent = backupUrl.lastPathComponent
            let folderPath = backupUrl.deletingLastPathComponent().path
            // if the last path component contains the “.icloud” extension. If yes the file is not on the device else the file is already downloaded.

            if lastPathComponent.contains(".icloud") {
                if !isInternetConnection() { completion(nil, ICloudBackupWalletError.noInternetConnection) }

                lastPathComponent.removeFirst()
                let downloadedFilePath = folderPath + "/" + lastPathComponent.replacingOccurrences(of: ".icloud", with: "")

                do {
                    try FileManager.default.startDownloadingUbiquitousItem(at: backupUrl)
                } catch {
                    completion(nil, error)
                }

                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                    if FileManager.default.fileExists(atPath: downloadedFilePath) {
                        timer.invalidate()
                        completion(URL(fileURLWithPath: downloadedFilePath), nil)
                    }
                }
            } else {
                completion(backupUrl, nil)
            }
        }
    }

    private func getLastWalletBackupFolder() throws -> String {
        let iCloudFolderURL = try iCloudDirectory()
        do {
            let urls = try FileManager.default.contentsOfDirectory(atURL: iCloudFolderURL, sortedBy: .created, options: [])

            guard let wallet = urls.last?.lastPathComponent else {
                throw ICloudBackupWalletError.noICloudBackupExists
            }
            return wallet
        } catch {
            throw ICloudBackupWalletError.noICloudBackupExists
        }
    }

    private func zipWalletDatabase() throws -> URL {
        let archiveName = fileName + ".zip"

        let tmpDirectory = try tempDirectory()
        let archiveURL = tmpDirectory.appendingPathComponent(archiveName)

        if FileManager.default.fileExists(atPath: archiveURL.path) {
            try FileManager.default.removeItem(atPath: archiveURL.path)
        }

        let sqlite3File = TariLib.databaseName.appending(".sqlite3")
        try FileManager().zipItem(at: directory.appendingPathComponent(sqlite3File), to: archiveURL, compressionMethod: .deflate)
        return archiveURL
    }

    private func encryptedZipWalletDatabase(keyString: String) throws -> URL {
        let zipURL = try zipWalletDatabase()
        let data = try Data(contentsOf: zipURL)

        let aes = try AESEncryption(keyString: keyString)

        let encryptedData = try aes.encrypt(data)
        let fileURL = try tempDirectory().appendingPathComponent(fileName)
        try encryptedData.write(to: fileURL)

        return fileURL
    }

    private func decryptedZipWalletDatabase(encryptedFileUrl: URL) throws -> URL {
        guard let password = Migrations.loadBackupPasswordFromKeychain() else { throw ICloudBackupWalletError.keychainPasswordFailture }
        let data = try Data(contentsOf: encryptedFileUrl)
        let aes = try AESEncryption(keyString: password)

        let decryptedZipUrl = try tempDirectory().appendingPathComponent(fileName + ".zip")

        let decryptedData = try aes.decrypt(data)
        try decryptedData.write(to: decryptedZipUrl)

        return decryptedZipUrl
    }

    private func iCloudDirectory() throws -> URL {
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: TariSettings.shared.iCloudContainerIdentifier)?.appendingPathComponent("Tari-Wallet-Backups") else {
            throw ICloudBackupWalletError.iCloudContainerNotFound
        }
        return url
    }

    private func tempDirectory() throws -> URL {
        if let tempZipDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Backups") {

            if !FileManager.default.fileExists(atPath: tempZipDirectory.path) {
                try FileManager.default.createDirectory(at: tempZipDirectory, withIntermediateDirectories: true, attributes: nil)
            }

            return tempZipDirectory
        } else { throw ICloudBackupWalletError.failedToCreateZip }
    }

    private func cleanTempDirectory() throws {
        let directory = try tempDirectory()
        try FileManager.default.removeItem(at: directory)
    }
}
