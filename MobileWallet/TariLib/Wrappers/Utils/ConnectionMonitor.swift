//  ConnectionMonitor.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/04/07
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

enum ConnectionMonitorStateReachability: String {
    case cellular = "Cellular ✅"
    case wifi = "WiFi ✅"
    case offline = "Offline ❌"
    case unknown = "Unknown ❓"
}

enum ConnectionMonitorStateTor: String {
    case connected = "Connected ✅"
    case failed = "Failed ❌"
    case connecting = "Connecting ⌛"
    case unknown = "Unknown ❓"
}

enum ConnectionMonitorStateBaseNode: String {
    case notInited = "Not initialized"
    case pending = "Pending sync ⌛"
    case failure = "Sync failed ❌"
    case success = "Synced ✅"
}

class ConnectionMonitorState {
    var reachability: ConnectionMonitorStateReachability = .unknown { didSet { onUpdate() } }
    var torBootstrapProgress: Int = 0 { didSet { onUpdate() } }
    var torPortsOpen = false { didSet { onUpdate() } }
    var torPortsOpenDisplay: String {
        return torPortsOpen ? "Open ✅" : "Closed ❌"
    }
    var torStatus: ConnectionMonitorStateTor = .unknown { didSet { onUpdate() } }
    var baseNodeSyncStatus: ConnectionMonitorStateBaseNode = ConnectionMonitorStateBaseNode.notInited { didSet { onUpdate() } }

    var currentBaseNodeName: String {
        var name = "unknown"
        if let currentPeer = TariSettings.groupUserDefaults.string(forKey: TariLib.currentBaseNodeUserDefaultsKey) {
            if let currentPeerName = (TariSettings.shared.defaultBaseNodePool.filter { (_, val) -> Bool in val  == currentPeer}).first {
                name = currentPeerName.key
            } else {
                name = "Custom"
            }
        }

        return name
    }

    var formattedDisplayItems: [String] {
        var entries: [String] = []
        entries.append("Reachability: \(reachability.rawValue)")
        entries.append("Base node (\(currentBaseNodeName)): \(baseNodeSyncStatus.rawValue)")
        entries.append("Tor ports: \(torPortsOpenDisplay)")
        entries.append("Tor status: \(torStatus.rawValue)")
        entries.append("Tor bootstrap progress: \(torBootstrapProgress)%")

        return entries
    }

    // ALlow other components to subscribe to connection state changes from one place
    private func onUpdate() {
        TariEventBus.postToMainThread(.connectionMonitorStatusChanged, sender: self)
    }
}

class ConnectionMonitor {
    public static let shared = ConnectionMonitor()
    private var reachability: Reachability?

    var state = ConnectionMonitorState()

    private init() {
        do {
            reachability = try Reachability()
        } catch {
            TariLogger.error("Failed to init Reachability. Network status not being monitored", error: error)
        }
    }

    func start() {
        state = ConnectionMonitorState() // Reset state to defaults
        startMonitoringNetwork()
        startMonitoringTor()
        startMonitoringBaseNodeSync()
        TariLogger.verbose("Started monitoring network connections")
    }

    private func startMonitoringNetwork() {
        guard let reachability = self.reachability else {
            return
        }

        self.setReachability(reachability)

        reachability.whenReachable = { [weak self] reachability in
            guard let self = self else { return }

            self.setReachability(reachability)
        }

        reachability.whenUnreachable = { [weak self] _ in
            guard let self = self else { return }
            self.state.reachability = .offline
        }

        do {
            try reachability.startNotifier()
        } catch {
            TariLogger.error("Failed to start Reachability notifier", error: error)
        }
    }

    private func setReachability(_ reachability: Reachability) {
        switch reachability.connection {
        case .cellular:
            self.state.reachability = .cellular
        case .wifi:
            self.state.reachability = .wifi
        default:
            self.state.reachability = .unknown
        }
    }

    private func startMonitoringTor() {
        TariEventBus.onMainThread(self, eventType: .torPortsOpened) { [weak self] (_) in
            guard let self = self else { return }
            self.state.torPortsOpen = true
        }

        TariEventBus.onMainThread(self, eventType: .torConnected) { [weak self] (_) in
            guard let self = self else { return }

            // TODO check torController.isConnected as well
            self.state.torStatus = .connected
        }

        TariEventBus.onMainThread(self, eventType: .torConnectionFailed) { [weak self] (_) in
            guard let self = self else { return }
            self.state.torStatus = .failed
        }

        TariEventBus.onMainThread(self, eventType: .torConnectionProgress) {
            [weak self]
            (result) in
            guard let self = self else { return }
            if let progress: Int = result?.object as? Int {
                self.state.torBootstrapProgress = progress
                self.state.torStatus = .connecting
            }
        }
    }

    private func startMonitoringBaseNodeSync() {
        TariEventBus.onMainThread(self, eventType: .baseNodeSyncStarted) {
            [weak self]
            (_) in
            guard let self = self else { return }
            self.state.baseNodeSyncStatus = .pending
        }
        TariEventBus.onMainThread(self, eventType: .baseNodeSyncComplete) {
            [weak self]
            (result) in
            guard let self = self else { return }
            if let result: [String: Any] = result?.object as? [String: Any] {
                let result = result["result"] as! BaseNodeValidationResult
                switch result {
                case .success:
                    self.state.baseNodeSyncStatus = .success
                case .aborted:
                    fallthrough
                case .baseNodeNotInSync:
                    fallthrough
                case .failure:
                    self.state.baseNodeSyncStatus = .failure
                }
            }
        }
    }

    func stop() {
        reachability?.stopNotifier()
        TariEventBus.unregister(self)
        TariLogger.verbose("Stopped monitoring network connections")
    }
}
