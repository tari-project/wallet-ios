//  TariLib.swift

/*
    Package MobileWallet
    Created by Jason van den Berg on 2019/11/12
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

enum TariLibErrors: Error {
    case privateKeyNotFound
}

class TariLib {
    static let shared = TariLib()

    private let DATABASE_NAME = "tari_wallet"
    private let PRIVATE_KEY_STORAGE_KEY = "privateKey"

    private var storagePath: String {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.path
    }

    var databasePath: String {
        return "\(storagePath)/\(DATABASE_NAME)"
    }

    static let logFilePrefix = "log"

    lazy var logFilePath: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        return "\(storagePath)/\(TariLib.logFilePrefix)-\(dateString).txt"
    }()

    var allLogFiles: [URL] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let allLogFiles = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil).filter({$0.lastPathComponent.contains(TariLib.logFilePrefix)}).sorted(by: { (a, b) -> Bool in
                return a.path > b.path
            })
            return allLogFiles
        } catch {
            return []
        }
    }

    var publicAddress: String {
        return "/ip4/172.30.30.112/tcp/9838"
    }

    var listenerAddress: String {
        return "/ip4/0.0.0.0/tcp/9838"
    }

    private let fileManager = FileManager.default

    var tariWallet: Wallet?

    var walletExists: Bool {
        get {
            if UserDefaults.standard.string(forKey: PRIVATE_KEY_STORAGE_KEY) != nil {
                return true
            }

            return false
        }
    }

    var isTorConnected: Bool {
        //If we're not using tor (for a simulator) or if tor is actually connected
        return !TariSettings.shared.torEnabled || OnionConnector.shared.connectionState == .connected
    }

    //If we're not using tor at all, assume the ports start as open
    var torPortsOpened = !TariSettings.shared.torEnabled

    //TODO remove this when no longer required. Temp solution until this logic is added to the lib
    private var baseNodeConsecutiveFails = 0 {
        didSet {
            if baseNodeConsecutiveFails > 5 {
                do {
                    TariLogger.warn("Base node sync failed \(baseNodeConsecutiveFails) times. Setting another random peer.")
                    try tariWallet?.addBaseNodePeer(try BaseNode(TariSettings.shared.getRandomBaseNode()))
                    baseNodeConsecutiveFails = 0
                } catch {
                    TariLogger.error("Failed to add random base node peer")
                }
            }
        }
    }

    init() {}

    /*
     Called automatically, just before instance deallocation takes place
     */
    deinit {}

    //Temp solution until this logic is added to the lib
    private func baseNodeSyncCheck() {
        TariEventBus.onMainThread(self, eventType: .baseNodeSyncComplete) { [weak self] (result) in
            guard let self = self else { return }
            guard self.isTorConnected else { return }

            if let success: Bool = result?.object as? Bool {
                if success {
                    self.baseNodeConsecutiveFails = 0
                } else {
                    self.baseNodeConsecutiveFails = self.baseNodeConsecutiveFails + 1
                }
            }
        }
    }

    private func transportType() throws -> TransportType {
        if TariSettings.shared.torEnabled {
            let torKey = ""
            let torBytes = [UInt8](torKey.utf8)
            let torIdentity = try ByteVector(byteArray: torBytes)

            let torCookieBytes = [UInt8](try OnionManager.getCookie())
            let torCookie = try ByteVector(byteArray: torCookieBytes)

            return try TransportType(
                controlServerAddress: "/ip4/\(OnionManager.CONTROL_ADDRESS)/tcp/\(OnionManager.CONTROL_PORT)",
                torPort: 39051,
                torIdentity: torIdentity,
                torCookie: torCookie,
                socksUsername: "",
                socksPassword: ""
            )
        } else {
            TariLogger.warn("Tor disabled. Update TariSettings.swift to enable it on a simulator.")
            return TransportType() //In memory transport
        }
    }

    func startTor() {
        guard !TariSettings.shared.isUnitTesting else {
            TariLogger.verbose("Ignoring tor start for unit tests")
            return
        }

        guard OnionConnector.shared.connectionState != .connected && OnionConnector.shared.connectionState != .started else {
            return
        }

        guard TariSettings.shared.torEnabled else {
            TariEventBus.postToMainThread(.torConnected, sender: URLSessionConfiguration.default)
            return
        }

        TariEventBus.postToMainThread(.torConnectionProgress, sender: Int(0))
        OnionConnector.shared.start(
            onProgress: { [weak self] percentage in
                guard let _ = self else { return }

                TariEventBus.postToMainThread(.torConnectionProgress, sender: percentage)
            },
            onPortsOpen: { [weak self] in
                guard let self = self else { return }
                self.torPortsOpened = true
                TariEventBus.postToMainThread(.torPortsOpened, sender: nil)
            },
            onCompletion: { [weak self] result in
                guard let self = self else { return }

                switch result {
                    case .success(let urlSessionConfiguration):
                        TariEventBus.postToMainThread(.torConnectionProgress, sender: Int(100))
                        TariEventBus.postToMainThread(.torConnected, sender: urlSessionConfiguration)
                        try? self.tariWallet?.syncBaseNode()
                    case .failure(let error):
                        TariLogger.error("Tor connection failed to complete", error: error)
                        TariEventBus.postToMainThread(.torConnectionFailed, sender: error)

                        //Might as well keep trying
                        self.startTor()
                }
            }
        )
    }

    func stopTor() {
        guard !TariSettings.shared.isUnitTesting else {
            TariLogger.verbose("Ignoring tor stop for unit tests")
            return
        }

        OnionConnector.shared.stop()
    }

    private func expirePendingTransactionsAfterSync() {
        TariEventBus.onBackgroundThread(self, eventType: .baseNodeSyncComplete) { [weak self] (result) in
            guard let self = self else { return }
            if let success: Bool = result?.object as? Bool {
                if success {
                    do {
                        try self.tariWallet?.cancelExpiredPendingTransactions()
                        TariLogger.verbose("Checked for expired pending transactions")
                    } catch {
                        TariLogger.error("Failed to cancel expired pending transactions", error: error)
                    }
                }
            }
        }
    }

    func createNewWallet() throws {
        try fileManager.createDirectory(atPath: storagePath, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(atPath: databasePath, withIntermediateDirectories: true, attributes: nil)

        TariLogger.verbose("Database path: \(databasePath)")

        let privateKey = PrivateKey()

        let (hex, hexError) = privateKey.hex
        if hexError != nil {
            throw hexError!
        }

        //TODO use secure enclave
        UserDefaults.standard.set(hex, forKey: PRIVATE_KEY_STORAGE_KEY)

        let transport = try transportType()
        let commsConfig = try CommsConfig(privateKey: privateKey, transport: transport, databasePath: databasePath, databaseName: DATABASE_NAME, publicAddress: publicAddress, discoveryTimeoutSec: TariSettings.shared.discoveryTimeoutSec)

        tariWallet = try Wallet(commsConfig: commsConfig, loggingFilePath: TariLib.shared.logFilePath)

        try tariWallet?.addBaseNodePeer(try BaseNode(TariSettings.shared.getRandomBaseNode()))

        baseNodeSyncCheck() //TODO remove when no longer needed
    }

    func startExistingWallet(isBackgroundTask: Bool = false) throws {
        if let privateKeyHex = UserDefaults.standard.string(forKey: PRIVATE_KEY_STORAGE_KEY) {
            TariLogger.verbose("Database path: \(databasePath)")

            let privateKey = try PrivateKey(hex: privateKeyHex)
            let transport = try transportType()
            let commsConfig = try CommsConfig(
                privateKey: privateKey,
                transport: transport,
                databasePath: databasePath,
                databaseName: DATABASE_NAME,
                publicAddress: publicAddress,
                discoveryTimeoutSec: TariSettings.shared.discoveryTimeoutSec
            )

            var loggingFilePath = TariLib.shared.logFilePath
            //So we can check the logs for sessions that happend in the background
            if isBackgroundTask {
                loggingFilePath = loggingFilePath.replacingOccurrences(of: ".txt", with: "-background.txt")
            }

            tariWallet = try Wallet(commsConfig: commsConfig, loggingFilePath: loggingFilePath)
        } else {
            throw TariLibErrors.privateKeyNotFound
        }

        expirePendingTransactionsAfterSync()

        backgroundStorageCleanup(logFilesMaxMB: TariSettings.shared.maxMbLogsStorage)

        baseNodeSyncCheck() //TODO remove when no longer needed
    }
}
