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
    var torPortsOpened = false

    enum KeyValueStorageKeys: String {
        case network = "SU7FM2O6Q3BU4XVN7HDD"
    }

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
            let fileExists = try TariSettings.storageDirectory.appendingPathComponent(
                TariLib.databaseName,
                isDirectory: true
            ).checkResourceIsReachable()
            return fileExists
        } catch {
            TariLogger.warn("Database path not reachable. Assuming wallet doesn't exist.", error: error)
            return false
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
               discoveryTimeoutSec: TariSettings.shared.discoveryTimeoutSec,
               safMessageDurationSec: TariSettings.shared.safMessageDurationSec
            )
        } catch {
            TariLogger.error("Failed to create comms config", error: error)
        }

        return config
    }

    // Used to determine whether or not to restart the wallet service when app moved to forground
    var walletIsStopped = false

    static let currentBaseNodeUserDefaultsKey = "currentBaseNodeSet"

    private init() {
        OnionConnector.shared.addObserver(self)
    }

    deinit {

    }

    private func transportType() throws -> TransportType {
        let torCookieBytes = [UInt8](try OnionManager.getCookie())
        let torCookie = try ByteVector(byteArray: torCookieBytes)

        return try TransportType(
            controlServerAddress: "/ip4/\(OnionManager.CONTROL_ADDRESS)/tcp/\(OnionManager.CONTROL_PORT)",
            torPort: 18101,
            torCookie: torCookie,
            socksUsername: "",
            socksPassword: ""
        )
    }

    func startTor() {
        guard !TariSettings.shared.isUnitTesting else {
            TariLogger.verbose("Ignoring tor start for unit tests")
            return
        }
        guard OnionConnector.shared.connectionState != .started
                && OnionConnector.shared.connectionState != .connected else {
            return
        }
        OnionConnector.shared.start()
        TariEventBus.postToMainThread(.torConnectionProgress, sender: Int(0))
    }

    func stopTor() {
        guard !TariSettings.shared.isUnitTesting else {
            TariLogger.verbose("Ignoring tor stop for unit tests")
            return
        }
        OnionConnector.shared.stop()
    }

    private func startListeningToBaseNodeSync() {
        TariEventBus.onBackgroundThread(self, eventType: .baseNodeSyncComplete) {
            [weak self]
            (result) in
            guard let self = self else { return }
            if let result: [String: Any] = result?.object as? [String: Any] {
                let result = result["result"] as! BaseNodeValidationResult
                switch result {
                case .success:
                    do {
                        try self.tariWallet?.cancelAllExpiredPendingTx()
                        TariLogger.verbose("Checked for expired pending transactions")
                    } catch {
                        TariLogger.error("Failed to cancel expired pending transactions", error: error)
                    }
                default:
                    break
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

        tariWallet = try Wallet(commsConfig: config, loggingFilePath: loggingFilePath)
        try setBasenode(syncAfterSetting: false)

        TariEventBus.postToMainThread(.walletServiceStarted)

        walletPublicKeyHex = tariWallet?.publicKey.0?.hex.0

        walletIsStopped = false

        startListeningToBaseNodeSync()

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
        try FileManager.default.createDirectory(
            at: databaseDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try startWalletService()
        // persist network
        try setCurrentNetworkKeyValue()
    }

    func setCurrentNetworkKeyValue() throws {
        _ = try TariLib.shared.tariWallet?.setKeyValue(
            key: KeyValueStorageKeys.network.rawValue,
            value: TariSettings.shared.network.rawValue
        )
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

    func deleteWallet() {
        stopWallet()
        do {
            // delete database files
            try FileManager.default.removeItem(at: databaseDirectory)
            // delete cached value
            walletPublicKeyHex = nil
            // this value also needs to be unset, it implies existence of a wallet
            walletIsStopped = false
            // delete log files
            for logFile in allLogFiles {
                try FileManager.default.removeItem(at: logFile)
            }
            // remove all user defaults
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.removePersistentDomain(forName: TariSettings.groupIndentifier)
            UserDefaults.standard.synchronize()
        } catch {
            fatalError()
        }
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

extension TariLib: OnionConnectorDelegate {

    func onTorConnProgress(_ progress: Int) {
        TariEventBus.postToMainThread(.torConnectionProgress, sender: progress)
    }

    func onTorPortsOpened() {
        self.torPortsOpened = true
        TariEventBus.postToMainThread(.torPortsOpened, sender: nil)
    }

    func onTorConnDifficulties(error: OnionError) {
        TariLogger.error("Tor connection failed to complete", error: error)
        TariEventBus.postToMainThread(.torConnectionFailed, sender: error)

        // might as well keep trying
        if error == .invalidBridges {
            OnionConnector.shared.restoreBridgeConfiguration()
        }
        self.startTor()
    }

    func onTorConnFinished(_ configuration: BridgesConfuguration) {
        TariEventBus.postToMainThread(.torConnectionProgress, sender: Int(100))
        TariEventBus.postToMainThread(.torConnected, sender: nil)
    }
}
