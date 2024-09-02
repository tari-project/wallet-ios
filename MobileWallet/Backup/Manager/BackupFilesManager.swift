//  BackupFilesManager.swift

/*
    Package MobileWallet
    Created by Adrian Truszczynski on 15/04/2022
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

import Zip

enum BackupFilesManager {

    enum InternalError: Error {
        case noPassphrase
        case noDatabaseInBackup
    }

    static var encryptedFileName: String { "Tari-Aurora-Backup" + "-" + NetworkManager.shared.selectedNetwork.name }
    static var unencryptedFileName: String { encryptedFileName + ".json" }
    private static var zippedFileName: String { encryptedFileName + ".zip" }

    private static let passphraseFileName = "passphrase"
    private static let internalWorkingDirectoryName = "Internal"
    private static let workingDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("Backups")

    private static let jsonEncoder = JSONEncoder()
    private static let jsonDecoder = JSONDecoder()

    private static var databaseDirectory: URL { Tari.shared.connectedDatabaseDirectory }
    private static var databaseURL: URL { Tari.shared.databaseURL }

    // MARK: - Prepare Backup

    static func prepareBackup(workingDirectoryName: String, password: String?) async throws -> URL {

        let workingDirectory = try prepareWorkingDirectory(name: workingDirectoryName)

        guard let password else {
            return try preparePartialBackup(workingDirectory: workingDirectory)
        }

        return try await prepareFullBackup(workingDirectory: workingDirectory, password: password)
    }

    private static func preparePartialBackup(workingDirectory: URL) throws -> URL {

        let rawUTXOs = try Tari.shared.unspentOutputsService
            .unspentOutputs()
            .all
            .map { try $0.json }

        let model = PartialBackupModel(source: try Tari.shared.walletAddress.components.fullRaw, utxos: rawUTXOs)
        let data = try jsonEncoder.encode(model)

        let fileURL = workingDirectory.appendingPathComponent(unencryptedFileName)

        FileManager.default.createFile(atPath: fileURL.path, contents: data)

        return fileURL
    }

    private static func prepareFullBackup(workingDirectory: URL, password: String) async throws -> URL {

        var filesToRemove = [URL]()

        defer {
            filesToRemove.forEach { try? FileManager.default.removeItem(at: $0) }
        }

        guard let passphrase = AppKeychainWrapper.dbPassphrase else { throw InternalError.noPassphrase }

        let databaseURL = try exportDatabase(workingDirectory: workingDirectory)
        let passphraseFileURL = workingDirectory.appendingPathComponent(passphraseFileName)
        let pasphraseData = passphrase.data(using: .utf8)

        FileManager.default.createFile(atPath: passphraseFileURL.path, contents: pasphraseData)

        filesToRemove += [databaseURL, passphraseFileURL]

        let zipFileURL = workingDirectory.appendingPathComponent(zippedFileName)
        try await zip(inputURLs: [databaseURL, passphraseFileURL], outputURL: zipFileURL)

        filesToRemove.append(zipFileURL)

        let encryptedFileURL = workingDirectory.appendingPathComponent(encryptedFileName)
        try encryptFile(inputURL: zipFileURL, outputURL: encryptedFileURL, password: password)

        return encryptedFileURL
    }

    // MARK: - Recover Backup

    static func recover(backup: URL, password: String?) async throws {
        do {
            guard let password else {
                try await recoverPartialBackup(backup: backup)
                return
            }
            try await recoverFullBackup(backupURL: backup, password: password)
        } catch {
            Tari.shared.deleteWallet()
            throw error
        }
    }

    private static func recoverPartialBackup(backup: URL) async throws {

        let jsonData = try Data(contentsOf: backup)
        let model = try jsonDecoder.decode(PartialBackupModel.self, from: jsonData)

        try await Tari.shared.startWallet()

        let sourceAddress = try TariAddress(base58: model.source)

        try model.utxos
            .map { try UnblindedOutput(json: $0) }
            .forEach { _ = try Tari.shared.unspentOutputsService.store(unspentOutput: $0, sourceAddress: sourceAddress, message: localized("backup.cloud.partial.recovery_message")) }
    }

    private static func recoverFullBackup(backupURL: URL, password: String) async throws {

        defer {
            try? removeWorkingDirectory(workingDirectoryName: internalWorkingDirectoryName)
        }

        let workingDirectory = try prepareWorkingDirectory(name: internalWorkingDirectoryName)
        let zipURL = workingDirectory.appendingPathComponent(zippedFileName)

        try decryptFile(inputURL: backupURL, outputURL: zipURL, password: password)
        try await unzip(inputURL: zipURL, outputURL: workingDirectory)

        let passphraseURL = workingDirectory.appendingPathComponent(passphraseFileName)
        let passphrase = try String(contentsOf: passphraseURL, encoding: .utf8)

        let databaseFileName = Tari.shared.databaseURL.lastPathComponent

        let backupURL = try FileManager.default
            .contentsOfDirectory(atURL: workingDirectory, sortedBy: .modified, ascending: false)
            .first { $0.lastPathComponent == databaseFileName }

        guard let backupURL else { throw InternalError.noDatabaseInBackup }

        try importBackup(backupURL: backupURL)
        AppKeychainWrapper.dbPassphrase = passphrase
    }

    // MARK: - Working Directory

    private static func workingDirectoryURL(name: String) -> URL {
        workingDirectory.appendingPathComponent(name)
    }

    static func prepareWorkingDirectory(name: String) throws -> URL {

        try removeWorkingDirectory(workingDirectoryName: name)
        let directory = workingDirectoryURL(name: name)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }

        return directory
    }

    static func removeWorkingDirectory(workingDirectoryName: String) throws {
        let workingDirectory = workingDirectoryURL(name: workingDirectoryName)
        guard FileManager.default.fileExists(atPath: workingDirectory.path) else { return }
        try FileManager.default.removeItem(atPath: workingDirectory.path)
    }

    // MARK: - File Actions

    private static func exportDatabase(workingDirectory: URL) throws -> URL {

        let filename = Tari.shared.databaseURL.lastPathComponent
        let workingFileURL = workingDirectory.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: workingFileURL.path) {
            try FileManager.default.removeItem(at: workingFileURL)
        }

        try FileManager.default.copyItem(at: Tari.shared.databaseURL, to: workingFileURL)
        return workingFileURL
    }

    private static func importBackup(backupURL: URL) throws {

        if FileManager.default.fileExists(atPath: databaseURL.path) {
            try FileManager.default.removeItem(at: databaseURL)
        }

        try FileManager.default.createDirectory(at: databaseDirectory, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: backupURL, to: databaseURL)
    }

    private static func zip(inputURLs: [URL], outputURL: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try Zip.zipFiles(paths: inputURLs, zipFilePath: outputURL, password: nil) { progress in
                    guard progress >= 1.0 else { return }
                    continuation.resume(with: .success(()))
                }
            } catch {
                continuation.resume(with: .failure(error))
            }
        }
    }

    private static func unzip(inputURL: URL, outputURL: URL) async throws {

        try await withCheckedThrowingContinuation { continuation in
            do {
                try Zip.unzipFile(inputURL, destination: outputURL, overwrite: true, password: nil, progress: { progress in
                    guard progress >= 1.0 else { return }
                    continuation.resume(with: .success(()))
                })
            } catch {
                continuation.resume(with: .failure(error))
            }
        }
    }

    private static func encryptFile(inputURL: URL, outputURL: URL, password: String) throws {
        let encryption = try AESEncryption(keyString: password)
        let data = try Data(contentsOf: inputURL)
        let encryptedData = try encryption.encrypt(data)
        try encryptedData.write(to: outputURL)
    }

    private static func decryptFile(inputURL: URL, outputURL: URL, password: String) throws {
        let encryption = try AESEncryption(keyString: password)
        let data = try Data(contentsOf: inputURL)
        let decryptedData = try encryption.decrypt(data)
        try decryptedData.write(to: outputURL)
    }
}
