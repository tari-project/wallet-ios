//  NetworkManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 01/09/2021
	Using Swift 5.0
	Running on macOS 12.0

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

import Combine

final class NetworkManager {

    enum InternalError: Error {
        case noBaseNode
    }

    // MARK: - Properties

    static let shared = NetworkManager()
    private static var defaultNetwork: TariNetwork { .nextnet }

    @Published var selectedNetwork: TariNetwork

    var defaultBaseNodes: [BaseNode] { (try? Tari.shared.connection.defaultBaseNodePeers()) ?? [] }

    var selectedBaseNode: BaseNode? {
        get { settings.selectedBaseNode }
        set { update(settings: settings.update(selectedBaseNode: newValue)) }
    }

    var customBaseNodes: [BaseNode] {
        get { settings.customBaseNodes }
        set { update(settings: settings.update(customBaseNodes: newValue)) }
    }

    var blockHeight: UInt64 {
        get { settings.blockHeight }
        set { update(settings: settings.update(blockHeight: newValue)) }
    }

    var allBaseNodes: [BaseNode] { defaultBaseNodes + customBaseNodes }

    private var settings: NetworkSettings {
        let allSettings = GroupUserDefaults.networksSettings ?? []

        guard let existingSettings = allSettings.first(where: { $0.name == selectedNetwork.name }) else {
            let newSettings = NetworkSettings(name: selectedNetwork.name, selectedBaseNode: nil, customBaseNodes: [], blockHeight: 0)
            update(settings: newSettings)
            return newSettings
        }
        return existingSettings
    }

    private var cancelables = Set<AnyCancellable>()

    // MARK: - Initializers

    init() {
        selectedNetwork = Self.setupNetwork()
        setupFeedbacks()
    }

    // MARK: - Setups

    private static func setupNetwork() -> TariNetwork {
        guard let selectedNetworkName = GroupUserDefaults.selectedNetworkName, let network = TariNetwork.all.first(where: { $0.name == selectedNetworkName }) else {
            GroupUserDefaults.selectedNetworkName = defaultNetwork.name
            return defaultNetwork
        }
        return network
    }

    private func setupFeedbacks() {
        $selectedNetwork
            .sink { GroupUserDefaults.selectedNetworkName = $0.name }
            .store(in: &cancelables)
    }

    // MARK: - Actions

    func removeSelectedNetworkSettings() {
        GroupUserDefaults.networksSettings?.removeAll { $0.name == GroupUserDefaults.selectedNetworkName }
        GroupUserDefaults.selectedNetworkName = nil
    }

    func randomBaseNode() throws -> BaseNode {
        guard let newBaseNode = defaultBaseNodes.randomElement() else { throw InternalError.noBaseNode }
        return newBaseNode
    }

    private func update(settings: NetworkSettings) {
        var allSettings = GroupUserDefaults.networksSettings ?? []
        allSettings.removeAll { $0 == settings }
        allSettings.append(settings)
        GroupUserDefaults.networksSettings = allSettings
    }
}
