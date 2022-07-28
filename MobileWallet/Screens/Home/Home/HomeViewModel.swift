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
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisers
    
    init() {
        setupCallbacks()
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        ConnectionMonitor.shared.$status
            .compactMap { $0 }
            .sink { [weak self] in self?.handle(connectionStatus: $0) }
            .store(in: &cancellables)
    }
    
    // MARK: - Helpers
    
    private func handle(connectionStatus: ConnectionMonitor.StatusModel) {
        
        switch (connectionStatus.networkConnection, connectionStatus.torConnection, connectionStatus.baseNodeConnectivity, connectionStatus.syncStatus) {
        case (.disconnected, _, _, _):
            connectionStatusImage = offlineIcon
        case (.connected, .disconnected, _, _):
            connectionStatusImage = offlineIcon
        case (.connected, .failed, _, _):
            connectionStatusImage = offlineIcon
        case (.connected, .connecting, _, _):
            connectionStatusImage = limitedConnectionIcon
        case (.connected, .connected, .offline, _):
            connectionStatusImage = limitedConnectionIcon
        case (.connected, .connected, .connecting, _):
            connectionStatusImage = limitedConnectionIcon
        case (.connected, .connected, .online, .idle):
            connectionStatusImage = limitedConnectionIcon
        case (.connected, .connected, .online, .failure):
            connectionStatusImage = limitedConnectionIcon
        case (.connected, .connected, .online, .pending):
            connectionStatusImage = onlineIcon
        case (.connected, .connected, .online, .success):
            connectionStatusImage = onlineIcon
        }
    }
}
