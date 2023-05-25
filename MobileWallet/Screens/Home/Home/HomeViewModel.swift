//  HomeViewModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 12/07/2022
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

import UIKit
import Combine

final class HomeViewModel {

    // MARK: - Constants

    private let offlineIcon = Theme.shared.images.connectionIndicatorDisconnectedIcon
    private let limitedConnectionIcon = Theme.shared.images.connectionIndicatorLimitedConnectonIcon
    private let onlineIcon = Theme.shared.images.connectionIndicatorConnectedIcon

    // MARK: - View Model

    @Published private(set) var connectionStatusImage: UIImage?
    @Published private(set) var balance: String = ""
    @Published private(set) var availableBalance: String = ""
    @Published private(set) var isNetworkCompatible: Bool = true

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
        checkNetworkCompatibility()
        BLEPeripheralManager.shared.isEnabled = true
    }

    // MARK: - Setups

    private func setupCallbacks() {

        let monitor = Tari.shared.connectionMonitor

        Publishers.CombineLatest4(monitor.$networkConnection, monitor.$torConnection, monitor.$baseNodeConnection, monitor.$syncStatus)
            .sink { [weak self] in self?.handle(networkConnection: $0, torConnection: $1, baseNodeConnection: $2, syncStatus: $3) }
            .store(in: &cancellables)

        Tari.shared.walletBalance.$balance
            .sink { [weak self] in self?.handle(walletBalance: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func updateCompatibleNetworkName() {
        _ = try? Tari.shared.keyValues.set(key: .network, value: NetworkManager.shared.selectedNetwork.name)
    }

    func deleteWallet() {
        Tari.shared.deleteWallet()
        Tari.shared.canAutomaticalyReconnectWallet = false
        BackupManager.shared.disableBackup()
        BLEPeripheralManager.shared.isEnabled = false
    }

    private func checkNetworkCompatibility() {
        guard let persistedNetworkName = try? Tari.shared.keyValues.value(key: .network), persistedNetworkName == NetworkManager.shared.selectedNetwork.name else {
            isNetworkCompatible = false
            return
        }

        isNetworkCompatible = true
    }

    // MARK: - Helpers

    private func handle(networkConnection: NetworkMonitor.Status, torConnection: TorManager.ConnectionStatus, baseNodeConnection: BaseNodeConnectivityStatus, syncStatus: TariValidationService.SyncStatus) {

        switch (networkConnection, torConnection, baseNodeConnection, syncStatus) {
        case (.disconnected, _, _, _),
            (.connected, .disconnected, _, _),
            (.connected, .disconnecting, _, _):
            connectionStatusImage = offlineIcon
        case (.connected, .connecting, _, _),
            (.connected, .portsOpen, _, _),
            (.connected, .connected, .offline, _),
            (.connected, .connected, .connecting, _),
            (.connected, .connected, .online, .idle),
            (.connected, .connected, .online, .failed):
            connectionStatusImage = limitedConnectionIcon
        case (.connected, .connected, .online, .syncing),
            (.connected, .connected, .online, .synced):
            connectionStatusImage = onlineIcon
        }
    }

    private func handle(walletBalance: WalletBalance) {
        balance = MicroTari(walletBalance.available + walletBalance.incoming).formatted
        availableBalance = MicroTari(walletBalance.available).formatted
    }
}
