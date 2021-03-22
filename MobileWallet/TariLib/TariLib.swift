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
}

class TariLib {
    static let shared = TariLib()
    static let databaseName = "tari_wallet"
    static let logFilePrefix = "log"
    var torPortsOpened = false
    public private(set) var walletState = WalletState.notReady

    enum KeyValueStorageKeys: String {
        case network = "SU7FM2O6Q3BU4XVN7HDD"
    }

    enum WalletState {
        case notReady
        case starting
        case startFailed
        case started
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

    var walletPublicKeyHex: String? // we need a cache of this for function that run while tariWallet = nil

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
        torPortsOpened = false
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
    /// - Throws: Can fail to generate a comms config, wallet creation and adding a basenode
    func startWallet() {
        walletState = .starting
        TariEventBus.postToMainThread(.walletStateChanged, sender: walletState)
        guard let config = commsConfig else {
            walletState = .startFailed
            TariEventBus.postToMainThread(.walletStateChanged, sender: walletState)
            return
        }
        let loggingFilePath = TariLib.shared.logFilePath
        do {
            tariWallet = try Wallet(
                commsConfig: config,
                loggingFilePath: loggingFilePath
            )
            walletPublicKeyHex = tariWallet?.publicKey.0?.hex.0
            walletState = .started
            TariEventBus.postToMainThread(
                .walletStateChanged,
                sender: walletState
            )
        } catch {
            walletState = .startFailed
            TariEventBus.postToMainThread(.walletStateChanged, sender: walletState)
            return
        }
        do {
            try setBasenode(syncAfterSetting: false)
        } catch {
            // no-op for now
        }
        startListeningToBaseNodeSync()
        backgroundStorageCleanup()
        walletState = .started
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
        // start listening to wallet events first
        TariEventBus.onMainThread(self, eventType: .walletStateChanged) {
            [weak self]
            (sender) in
            guard let self = self else { return }
            let walletState = sender!.object as! WalletState
            switch walletState {
            case .started:
                do {
                    try self.setCurrentNetworkKeyValue()
                } catch {
                    // no-op for now
                }
                TariEventBus.unregister(self, eventType: .walletStateChanged)
            case .startFailed:
                TariEventBus.unregister(self, eventType: .walletStateChanged)
            default:
                break
            }
        }
        // then start wallet
        startWallet()
    }

    func setCurrentNetworkKeyValue() throws {
        _ = try tariWallet?.setKeyValue(
            key: KeyValueStorageKeys.network.rawValue,
            value: TariSettings.shared.network.rawValue
        )
    }

    func stopWallet() {
        walletState = WalletState.notReady
        tariWallet = nil
        TariEventBus.unregister(self)
    }

    func deleteWallet() {
        stopWallet()
        do {
            // delete database files
            try FileManager.default.removeItem(at: databaseDirectory)
            // delete cached value
            walletPublicKeyHex = nil
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
