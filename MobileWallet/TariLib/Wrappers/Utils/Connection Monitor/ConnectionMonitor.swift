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
    
    // MARK: - Properties
    
    @Published private(set) var networkConnection: NetworkMonitor.Status = .disconnected
    @Published private(set) var torConnection: TorManager.ConnectionStatus = .disconnected
    @Published private(set) var torBootstrapProgress: Int = 0
    @Published private(set) var isTorBootstrapCompleted: Bool = false
    @Published private(set) var baseNodeConnection: BaseNodeConnectivityStatus = .offline
    @Published private(set) var syncStatus: TariValidationService.SyncStatus = .idle
    
    private let networkMonitor = NetworkMonitor()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setups
    
    func setupPublishers(torConnectionStatus: AnyPublisher<TorManager.ConnectionStatus, Never>, torBootstrapProgress: AnyPublisher<Int, Never>,
                         baseNodeConnectionStatus: AnyPublisher<BaseNodeConnectivityStatus, Never>, baseNodeSyncStatus: AnyPublisher<TariValidationService.SyncStatus, Never>) {
        
        networkMonitor.$status
            .assign(to: \.networkConnection, on: self)
            .store(in: &cancellables)
        
        torConnectionStatus
            .assign(to: \.torConnection, on: self)
            .store(in: &cancellables)
        
        torBootstrapProgress
            .assign(to: \.torBootstrapProgress, on: self)
            .store(in: &cancellables)
        
        torBootstrapProgress
            .map { $0 >= 100 }
            .assign(to: \.isTorBootstrapCompleted, on: self)
            .store(in: &cancellables)
        
        baseNodeConnectionStatus
            .assign(to: \.baseNodeConnection, on: self)
            .store(in: &cancellables)
        
        baseNodeSyncStatus
            .assign(to: \.syncStatus, on: self)
            .store(in: &cancellables)
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

private extension TorManager.ConnectionStatus {
    
    var statusName: String {
        switch self {
        case .disconnected, .disconnecting:
            return localized("connection_status.popUp.label.tor_status.disconnected")
        case .connecting, .portsOpen:
            return localized("connection_status.popUp.label.tor_status.connecting")
        case .connected:
            return localized("connection_status.popUp.label.tor_status.connected")
        }
    }
    
    var statusColor: UIColor? {
        switch self {
        case .disconnected, .disconnecting:
            return .tari.system.red
        case .connecting, .portsOpen:
            return .tari.system.orange
        case .connected:
            return .tari.system.green
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

private extension TariValidationService.SyncStatus {
    
    var statusName: String {
        switch self {
        case .idle:
            return localized("connection_status.popUp.label.base_node_sync.idle")
        case .syncing:
            return localized("connection_status.popUp.label.base_node_sync.pending")
        case .synced:
            return localized("connection_status.popUp.label.base_node_sync.success")
        case .failed:
            return localized("connection_status.popUp.label.base_node_sync.failure")
        }
    }
    
    var statusColor: UIColor? {
        switch self {
        case .idle:
            return .tari.system.red
        case .syncing:
            return .tari.system.orange
        case .synced:
            return .tari.system.green
        case .failed:
            return .tari.system.red
        }
    }
}

extension ConnectionMonitor {
    
    var formattedDisplayItems: [String] {
        var entries: [String] = []
        entries.append("Reachability: \(networkConnection.statusName)")
        entries.append("Base node (\(NetworkManager.shared.selectedNetwork.selectedBaseNode.name)): \(syncStatus.statusName)")
        entries.append("Base node connection status: \(baseNodeConnection.statusName)")
        entries.append("Tor status: \(torConnection.statusName)")
        entries.append("Tor bootstrap progress: \(torBootstrapProgress)%")
        
        return entries
    }
    
    func showDetailsPopup() {
        
        let headerSection = PopUpHeaderView()
        let contentSection = PopUpNetworkStatusContentView()
        let buttonsSection = PopUpButtonsView()
        
        headerSection.label.text = localized("connection_status.popUp.header")
        
        var cancellables = Set<AnyCancellable>()
        
        $networkConnection
            .receive(on: DispatchQueue.main)
            .sink { [weak contentSection] in contentSection?.updateNetworkStatus(text: $0.statusName, statusColor: $0.statusColor) }
            .store(in: &cancellables)
        
        $torConnection
            .receive(on: DispatchQueue.main)
            .sink { [weak contentSection] in contentSection?.updateTorStatus(text: $0.statusName, statusColor: $0.statusColor) }
            .store(in: &cancellables)
        
        $baseNodeConnection
            .receive(on: DispatchQueue.main)
            .sink { [weak contentSection] in contentSection?.updateBaseNodeConnectionStatus(text: $0.statusName, statusColor: $0.statusColor) }
            .store(in: &cancellables)
        
        $syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak contentSection] in contentSection?.updateBaseNodeSyncStatus(text: $0.statusName, statusColor: $0.statusColor) }
            .store(in: &cancellables)
        
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.close"), type: .text, callback: { PopUpPresenter.dismissPopup { cancellables.forEach { $0.cancel() }}}))
        
        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popUp, configuration: .dialog(hapticType: .none))
    }
}
