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

import Reachability
import UIKit
import Combine

final class ConnectionMonitor {
    
    struct StatusModel {
        let networkConnection: NetworkMonitor.Status
        let torConnection: TorMonitor.Status
        let baseNodeConnectivity: BaseNodeConnectivityStatus
        let syncStatus: BaseNodeStatusMonitor.SyncStatus
    }
    
    // MARK: - Properties
    
    static let shared = ConnectionMonitor()
    
    @Published private(set) var status: StatusModel?
    
    private let networkMonitor = NetworkMonitor()
    private let torMonitor = TorMonitor()
    private let baseNodeStatusMonitor = BaseNodeStatusMonitor()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisers
    
    private init() {
        setupCallbacks()
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        Publishers.CombineLatest4(networkMonitor.$status, torMonitor.$status, baseNodeStatusMonitor.$connectionStatus, baseNodeStatusMonitor.$syncStatus)
            .map { StatusModel(networkConnection: $0, torConnection: $1, baseNodeConnectivity: $2, syncStatus: $3) }
            .assign(to: \.status, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func showDetailsPopup() {
        
        let headerSection = PopUpHeaderView()
        let contentSection = PopUpNetworkStatusContentView()
        let buttonsSection = PopUpButtonsView()
        
        headerSection.label.text = localized("connection_status.popUp.header")
        
        let cancellable = $status
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak contentSection] in
                contentSection?.updateNetworkStatus(text: $0.networkConnection.statusName, statusColor: $0.networkConnection.statusColor)
                contentSection?.updateTorStatus(text: $0.torConnection.statusName, statusColor: $0.torConnection.statusColor)
                contentSection?.updateBaseNodeConnectionStatus(text: $0.baseNodeConnectivity.statusName, statusColor: $0.baseNodeConnectivity.statusColor)
                contentSection?.updateBaseNodeSyncStatus(text: $0.syncStatus.statusName, statusColor: $0.syncStatus.statusColor)
            }
        
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.close"), type: .text, callback: { PopUpPresenter.dismissPopup { [weak cancellable] in cancellable?.cancel() }}))
        
        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popUp, configuration: .dialog(hapticType: .none))
    }
}

private extension NetworkMonitor.Status {
    
    var statusName: String {
        switch self {
        case .disconnected:
            return localized("connection_status.popUp.label.network_status.disconnected")
        case .connected:
            return localized("connection_status.popUp.label.network_status.connected")
        }
    }
    
    var statusColor: UIColor? {
        switch self {
        case .disconnected:
            return .tari.system.red
        case .connected:
            return .tari.system.green
        }
    }
}

private extension TorMonitor.Status {
    
    var statusName: String {
        switch self {
        case .disconnected:
            return localized("connection_status.popUp.label.tor_status.disconnected")
        case .connecting:
            return localized("connection_status.popUp.label.tor_status.connecting")
        case .connected:
            return localized("connection_status.popUp.label.tor_status.connected")
        case .failed:
            return localized("connection_status.popUp.label.tor_status.failed")
        }
    }
    
    var statusColor: UIColor? {
        switch self {
        case .disconnected:
            return .tari.system.red
        case .connecting:
            return .tari.system.orange
        case .connected:
            return .tari.system.green
        case .failed:
            return .tari.system.red
        }
    }
}

private extension BaseNodeConnectivityStatus {
    
    var statusName: String {
        switch self {
        case .offline:
            return localized("connection_status.popUp.label.base_node_connection.disconnected")
        case .connecting:
            return localized("connection_status.popUp.label.base_node_connection.connecting")
        case .online:
            return localized("connection_status.popUp.label.base_node_connection.connected")
        }
    }
    
    var statusColor: UIColor? {
        switch self {
        case .offline:
            return .tari.system.red
        case .connecting:
            return .tari.system.orange
        case .online:
            return .tari.system.green
        }
    }
}

private extension BaseNodeStatusMonitor.SyncStatus {
    
    var statusName: String {
        switch self {
        case .idle:
            return localized("connection_status.popUp.label.base_node_sync.idle")
        case .pending:
            return localized("connection_status.popUp.label.base_node_sync.pending")
        case .success:
            return localized("connection_status.popUp.label.base_node_sync.success")
        case .failure:
            return localized("connection_status.popUp.label.base_node_sync.failure")
        }
    }
    
    var statusColor: UIColor? {
        switch self {
        case .idle:
            return .tari.system.red
        case .pending:
            return .tari.system.orange
        case .success:
            return .tari.system.green
        case .failure:
            return .tari.system.red
        }
    }
}

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

final class ConnectionMonitorState {
    var reachability: ConnectionMonitorStateReachability = .unknown { didSet { onUpdate() } }
    var torBootstrapProgress: Int = 0 { didSet { onUpdate() } }
    var torPortsOpen = false { didSet { onUpdate() } }
    var torPortsOpenDisplay: String {
        return torPortsOpen ? "Open ✅" : "Closed ❌"
    }
    var torStatus: ConnectionMonitorStateTor = .unknown { didSet { onUpdate() } }
    var baseNodeSyncStatus: ConnectionMonitorStateBaseNode = ConnectionMonitorStateBaseNode.notInited { didSet { onUpdate() } }

    var currentBaseNodeName: String { NetworkManager.shared.selectedNetwork.selectedBaseNode.name }
    var baseNodeConnectivityStatus: BaseNodeConnectivityStatus? { didSet { onUpdate() } }

    var formattedDisplayItems: [String] {
        var entries: [String] = []
        entries.append("Reachability: \(reachability.rawValue)")
        entries.append("Base node (\(currentBaseNodeName)): \(baseNodeSyncStatus.rawValue)")
        entries.append("Base node connection status: \(baseNodeConnectivityStatus?.name ?? "Unknown ❓")")
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

@available(*, deprecated, message: "This monitor will be removed in the near future. Please Use ConnectionMonitor instead")
class LegacyConnectionMonitor {
    public static let shared = LegacyConnectionMonitor()
    private var reachability: Reachability?

    var state = ConnectionMonitorState()

    private var cancellables = Set<AnyCancellable>()

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

        TariEventBus.onMainThread(self, eventType: .baseNodeSyncStarted) { [weak self] _ in
            self?.state.baseNodeSyncStatus = .pending
        }

        TariEventBus.onMainThread(self, eventType: .baseNodeSyncComplete) { [weak self] result in
            guard let result = result?.object as? [String: Any] else { return }
            guard let isSuccess = result["success"] as? Bool, isSuccess else {
                self?.state.baseNodeSyncStatus = .failure
                return
            }
            self?.state.baseNodeSyncStatus = .success
        }

        TariEventBus.events(forType: .connectionStatusChanged)
            .map { $0.object as? BaseNodeConnectivityStatus }
            .assign(to: \.baseNodeConnectivityStatus, on: state)
            .store(in: &cancellables)
    }

    func stop() {
        reachability?.stopNotifier()
        TariEventBus.unregister(self)
        TariLogger.verbose("Stopped monitoring network connections")
    }
}

private extension BaseNodeConnectivityStatus {
    var name: String {
        switch self {
        case .offline:
            return "Disconnected ❌"
        case .connecting:
            return "Connecting ⌛"
        case .online:
            return "Connected ✅"
        }
    }
}
