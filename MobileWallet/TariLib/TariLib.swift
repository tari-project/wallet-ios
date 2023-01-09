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
import Combine

enum TariLibErrors: Error {
    case saveToKeychain
}

class TariLib {

    private let databaseNamespace = "tari_wallet"

    static let shared = TariLib()
    static let logFilePrefix = "log"

    var walletState: WalletState { walletStateSubject.value }
    var walletStatePublisher: AnyPublisher<WalletState, Never> { walletStateSubject.share().eraseToAnyPublisher() }
    private let walletStateSubject = CurrentValueSubject<WalletState, Never>(.notReady)
    private var cancelables = Set<AnyCancellable>()

    @Published private(set) var areTorPortsOpen = false
    @Published private(set) var baseNodeConnectionStatus: BaseNodeConnectivityStatus = .offline

    private var cancellables = Set<AnyCancellable>()

    var connectedDatabaseName: String { databaseNamespace }
    var connectedDatabaseDirectory: URL { TariSettings.storageDirectory.appendingPathComponent("\(databaseNamespace)_\(NetworkManager.shared.selectedNetwork.name)", isDirectory: true) }

    enum KeyValueStorageKeys: String {
        case network = "SU7FM2O6Q3BU4XVN7HDD"
    }

    enum WalletState: Equatable {
        static func == (lhs: TariLib.WalletState, rhs: TariLib.WalletState) -> Bool {
            switch (lhs, rhs) {
            case (.notReady, .notReady), (.starting, .starting), (.started, .started), (.startFailed, .startFailed):
                return true
            default:
                return false
            }
        }

        case notReady
        case starting
        case startFailed(error: WalletError)
        case started
    }

    lazy var logFilePath: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        return "\(TariSettings.storageDirectory.path)/\(TariLib.logFilePrefix)-\(dateString).txt"
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

    private let publicAddress: String = "/ip4/0.0.0.0/tcp/9838"
    private let listenerAddress: String = "/ip4/0.0.0.0/tcp/9838"

    var tariWallet: Wallet?
    var walletPublicKeyHex: String? // we need a cache of this for function that run while tariWallet = nil

    var isWalletExist: Bool {
        do {
            return try connectedDatabaseDirectory.checkResourceIsReachable()
        } catch {
            TariLogger.warn("Database path not reachable. Assuming wallet doesn't exist.", error: error)
            return false
        }
    }

    var commsConfig: CommsConfig? {
        do {
            return try CommsConfig(
                transport: try transportType(),
                databaseFolderPath: connectedDatabaseDirectory.path,
                databaseName: connectedDatabaseName,
                publicAddress: publicAddress,
                discoveryTimeoutSec: TariSettings.shared.discoveryTimeoutSec,
                safMessageDurationSec: TariSettings.shared.safMessageDurationSec
            )
        } catch {
            TariLogger.error("Failed to create comms config", error: error)
            return nil
        }
    }

    private init() {
        setupListeners()
    }

    private func transportType() throws -> TransportConfig {
        let torCookieBytes = [UInt8](try OnionManager.getCookie())
        let torCookie = try ByteVector(byteArray: torCookieBytes)

        return try TransportConfig(
            controlServerAddress: "/ip4/\(OnionManager.CONTROL_ADDRESS)/tcp/\(OnionManager.CONTROL_PORT)",
            torPort: 18101,
            torCookie: torCookie,
            socksUsername: "",
            socksPassword: ""
        )
    }

    private func setupListeners() {
        OnionConnector.shared.addObserver(self)
        walletStatePublisher
            .sink { TariEventBus.postToMainThread(.walletStateChanged, sender: $0) }
            .store(in: &cancelables)

        TariEventBus.events(forType: .connectionStatusChanged)
            .compactMap { $0.object as? BaseNodeConnectivityStatus }
            .assign(to: \.baseNodeConnectionStatus, on: self)
            .store(in: &cancellables)
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
        areTorPortsOpen = false
    }

    private func startListeningToBaseNodeSync() {
        TariEventBus.onBackgroundThread(self, eventType: .baseNodeSyncComplete) { [weak self] result in
            guard let result = result?.object as? [String: Any], let isSuccess = result["success"] as? Bool, isSuccess else { return }

            do {
                try self?.tariWallet?.cancelAllExpiredPendingTx()
                TariLogger.verbose("Checked for expired pending transactions")
            } catch {
                TariLogger.error("Failed to cancel expired pending transactions", error: error)
            }
        }
    }

    /// Starts an existing wallet service. Must only be called if wallet DB files already exist.
    func startWallet(seedWords: SeedWords?) {
        walletStateSubject.send(.starting)
        guard let config = commsConfig else {
            walletStateSubject.send(.startFailed(error: .unknown))
            return
        }
        let loggingFilePath = TariLib.shared.logFilePath
        do {
            tariWallet = try Wallet(commsConfig: config, loggingFilePath: loggingFilePath, seedWords: seedWords, networkName: NetworkManager.shared.selectedNetwork.name)
            walletPublicKeyHex = tariWallet?.publicKey.0?.hex.0
            walletStateSubject.send(.started)
        } catch let error as WalletError {
            walletStateSubject.send(.startFailed(error: error))
            return
        } catch {
            walletStateSubject.send(.startFailed(error: .unknown))
            return
        }

        try? setupBasenode()
        startListeningToBaseNodeSync()
        backgroundStorageCleanup()
        walletStateSubject.send(.started)
    }

    /// Base note basic setup. Selects previously used base node or use random node if there wasn't any node selected before.
    func setupBasenode() throws {
        try update(baseNode: NetworkManager.shared.selectedNetwork.selectedBaseNode, syncAfterSetting: false)
    }

    /// Selects new base node peer for Tari Wallet.
    /// - Parameters:
    ///   - baseNode: Selected base node.
    ///   - syncAfterSetting: Boolean. If it  `true` then the wallet will try to sync with newly selected base node.
    func update(baseNode: BaseNode, syncAfterSetting: Bool) throws {

        NetworkManager.shared.selectedNetwork.selectedBaseNode = baseNode

        try tariWallet?.add(baseNode: baseNode)
        guard syncAfterSetting else { return }
        try? tariWallet?.syncBaseNode()
    }

    func createNewWallet(seedWords: SeedWords?) throws {
        try FileManager.default.createDirectory(
            at: connectedDatabaseDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // start listening to wallet events first
        var cancelable: AnyCancellable?

        cancelable = walletStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] walletState in
                switch walletState {
                case .started:
                    try? self?.setCurrentNetworkKeyValue()
                    cancelable?.cancel()
                case .startFailed:
                    cancelable?.cancel()
                case .starting, .notReady:
                    break
                }
            }

        cancelable?
            .store(in: &cancelables)

        startWallet(seedWords: seedWords)
    }

    func setCurrentNetworkKeyValue() throws {
        _ = try tariWallet?.setKeyValue(
            key: KeyValueStorageKeys.network.rawValue,
            value: NetworkManager.shared.selectedNetwork.name
        )
    }

    func stopWallet() {
        walletStateSubject.send(.notReady)
        tariWallet = nil
        baseNodeConnectionStatus = .offline
        TariEventBus.unregister(self)
    }

    func deleteWallet() {
        stopWallet()
        do {
            // delete database files
            try FileManager.default.removeItem(at: connectedDatabaseDirectory)
            // delete cached value
            walletPublicKeyHex = nil
            // delete log files
            for logFile in allLogFiles {
                try FileManager.default.removeItem(at: logFile)
            }
            // remove all user defaults
            UserDefaults.standard.removeAll()
            NetworkManager.shared.removeSelectedNetworkSettings()
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
        self.areTorPortsOpen = true
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
