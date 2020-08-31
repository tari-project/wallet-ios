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
    case saveToKeychain
    case failedToCreateCommsConfig
    case extensionHasLock
    case mainAppHasLock
}

class TariLib {
    static let shared = TariLib()

    static let databaseName = "tari_wallet"

    static let logFilePrefix = "log"

    lazy var logFilePath: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        return "\(TariSettings.storageDirectory.path)/\(TariLib.logFilePrefix)-\(dateString).txt"
    }()

    lazy var databaseDirectory: URL = {
        return TariSettings.storageDirectory.appendingPathComponent(TariLib.databaseName, isDirectory: true)
    }()

    var allLogFiles: [URL] {
        do {
            let allLogFiles = try FileManager.default.contentsOfDirectory(
                at: TariSettings.storageDirectory,
                includingPropertiesForKeys: nil
            ).filter({$0.lastPathComponent.contains(TariLib.logFilePrefix)}).sorted(by: { (a, b) -> Bool in
                return a.path > b.path
            })
            return allLogFiles
        } catch {
            return []
        }
    }

    var publicAddress: String {
        return "/ip4/0.0.0.0/tcp/9838"
    }

    var listenerAddress: String {
        return "/ip4/0.0.0.0/tcp/9838"
    }

    var tariWallet: Wallet?

    var walletPublicKeyHex: String? //We need a cache of this for function that run while tariWallet = nil

    var walletExists: Bool {
        do {
            let fileExists = try TariSettings.storageDirectory.appendingPathComponent(TariLib.databaseName, isDirectory: true).checkResourceIsReachable()
            return fileExists
        } catch {
            TariLogger.warn("Database path not reachable. Assuming wallet doesn't exist.", error: error)
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
                    try setBasenode(try BaseNode(TariSettings.shared.getRandomBaseNode())) //Override with random peer from default pool
                    baseNodeConsecutiveFails = 0
                } catch {
                    TariLogger.error("Failed to add random base node peer")
                }
            }
        }
    }

    var commsConfig: CommsConfig? {
        var config: CommsConfig?

        do {
            let transport = try transportType()
            config = try CommsConfig(
               transport: transport,
               databaseFolderPath: databaseDirectory.path,
               databaseName: TariLib.databaseName,
               publicAddress: publicAddress,
               discoveryTimeoutSec: TariSettings.shared.discoveryTimeoutSec
            )
        } catch {
            TariLogger.error("Failed to create comms config", error: error)
        }

        return config
    }

    //Used to determine whether or not to restart the wallet service when app moved to forground
    var walletIsStopped = false

    static let currentBaseNodeUserDefaultsKey = "currentBaseNodeSet"

    private init() {}

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

                    TariLogger.error("Failing to sync with base node (\(ConnectionMonitor.shared.state.currentBaseNodeName))")

                    try? self.tariWallet?.syncBaseNode()
                }
            }
        }
    }

    private static let torIdentityKeychainKey = "torIdentityKey"

    private func getPersistedTorIdentity() throws -> ByteVector? {
        if let base64EncodedTorIdentity = TariSettings.sharedKeychainGroup.string(forKey: TariLib.torIdentityKeychainKey) {
            if let data = Data(base64Encoded: base64EncodedTorIdentity) {
                TariLogger.verbose("Using persisted tor identity")
                return try ByteVector(byteArray: [UInt8](data))
            }
        }

        return nil
    }

    private func persistTorIdentity(_ identity: ByteVector) {
        let identityBytes = identity.bytes.0
        guard identityBytes.count > 0 else {
            return
        }

        TariSettings.sharedKeychainGroup.set(Data(identityBytes).base64EncodedString(), forKey: TariLib.torIdentityKeychainKey)
        TariLogger.verbose("Saved tor identity to keychain")
    }

    private func transportType() throws -> TransportType {
        if TariSettings.shared.torEnabled {
            let torIdentity = try getPersistedTorIdentity()
            let torCookieBytes = [UInt8](try OnionManager.getCookie())
            let torCookie = try ByteVector(byteArray: torCookieBytes)

            return try TransportType(
                controlServerAddress: "/ip4/\(OnionManager.CONTROL_ADDRESS)/tcp/\(OnionManager.CONTROL_PORT)",
                torPort: 18101,
                torIdentity: torIdentity,
                torCookie: torCookie,
                socksUsername: "",
                socksPassword: ""
            )
        } else {
            TariLogger.warn("Tor disabled. Update TariSettings.swift to enable it.")
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

    private func cancelAllExpiredPendingTxAfterSync() {
        TariEventBus.onBackgroundThread(self, eventType: .baseNodeSyncComplete) { [weak self] (result) in
            guard let self = self else { return }
            if let success: Bool = result?.object as? Bool {
                if success {
                    do {
                        try self.tariWallet?.cancelAllExpiredPendingTx()
                        TariLogger.verbose("Checked for expired pending transactions")
                    } catch {
                        TariLogger.error("Failed to cancel expired pending transactions", error: error)
                    }
                }
            }
        }
    }

    /// Starts an existing wallet service. Must only be called if wallet DB files already exist.
    /// - Parameter container: container checks a lock file and renames the log file for debugging tasks that happened in the background
    /// - Throws: Can fail to generate a comms config, wallet creation and adding a basenode
    func startWalletService(container: AppContainer = .main) throws {
        if container == .main && AppContainerLock.shared.hasLock(.ext) {
            throw TariLibErrors.extensionHasLock
        }

        if container == .ext && AppContainerLock.shared.hasLock(.main) {
            throw TariLibErrors.mainAppHasLock
        }

        guard let config = commsConfig else {
            throw TariLibErrors.failedToCreateCommsConfig
        }

        var loggingFilePath = TariLib.shared.logFilePath
        if container != .main {
            loggingFilePath = loggingFilePath.replacingOccurrences(of: ".txt", with: "-\(container.rawValue).txt")
        }

        Migrations.privateKeyKeychainToDB(config)

        tariWallet = try Wallet(commsConfig: config, loggingFilePath: loggingFilePath)
        try setBasenode(syncAfterSetting: false)
        //try setBasenode(try BaseNode(TariSettings.shared.defaultBaseNodePool["t-tbn-seoul"]!))

        TariEventBus.postToMainThread(.walletServiceStarted)

        walletPublicKeyHex = tariWallet?.publicKey.0?.hex.0

        walletIsStopped = false

        cancelAllExpiredPendingTxAfterSync()

        baseNodeSyncCheck() //TODO remove when no longer needed

        if let torIdentity = tariWallet?.torPrivateKey.0 {
            persistTorIdentity(torIdentity)
        }

        backgroundStorageCleanup(logFilesMaxMB: TariSettings.shared.maxMbLogsStorage)
    }

    func setBasenode(syncAfterSetting: Bool = true, _ overridePeer: BaseNode? = nil) throws {
        var basenode: BaseNode!
        if overridePeer != nil {
            basenode = overridePeer!
        } else if let currentBaseNodeString = TariSettings.groupUserDefaults.string(forKey: TariLib.currentBaseNodeUserDefaultsKey) {
            basenode = try BaseNode(currentBaseNodeString)
        } else {
            basenode = try BaseNode(TariSettings.shared.getRandomBaseNode())
        }

        try tariWallet?.addBaseNodePeer(basenode)
        TariSettings.groupUserDefaults.set(basenode.peer, forKey: TariLib.currentBaseNodeUserDefaultsKey)

        if syncAfterSetting {
            try? tariWallet?.syncBaseNode()
        }
    }

    func createNewWallet() throws {
        try FileManager.default.createDirectory(at: databaseDirectory, withIntermediateDirectories: true, attributes: nil)
        try startWalletService()
    }

    func restartWalletIfStopped() {
        if !walletExists {
            return
        }

        guard walletIsStopped else {
            return
        }

        TariEventBus.onMainThread(self, eventType: .torPortsOpened) { [weak self] (_) in
            guard let self = self else { return }

            TariLogger.verbose("Restarting stopped wallet")

            //Crash if we can't restart
            do {
                try self.startWalletService()
            } catch {
                TariLogger.error("Failed to restart wallet on first try", error: error)

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    guard let self = self else { return }
                    guard self.walletIsStopped else { return }

                    do {
                        try self.startWalletService()
                    } catch {
                        TariLogger.error("Failed to restart wallet on second try", error: error)
                    }
                }
            }

            TariEventBus.postToMainThread(.txListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
        }
    }

    func stopWallet() {
        tariWallet = nil
        walletIsStopped = true
        TariEventBus.unregister(self)
    }

    func waitIfWalletIsRestarting(completion: @escaping ((_ success: Bool?) -> Void)) {
        if !walletExists { completion(false); return }
        if tariWallet != nil { completion(true); return }

        var waitingTime = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] (timer) in
            guard let self = self else { timer.invalidate(); return }
            if (self.tariWallet != nil && self.walletPublicKeyHex != nil) || waitingTime >= 5.0 {
                completion(!self.walletIsStopped)
                timer.invalidate()
            }
            waitingTime += timer.timeInterval
        }
    }
}
