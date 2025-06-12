//  SelectNetworkModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 26/08/2021
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

final class SelectNetworkModel {

    struct NetworkModel: Hashable {
        let networkName: String
        let isSelected: Bool
    }

    final class ViewModel {
        @Published var networkModels: [NetworkModel] = []
        @Published var selectedIndex: Int?
    }

    // MARK: - Properties

    let viewModel = ViewModel()
    private let networks = [NetworkManager.defaultNetwork]

    // MARK: - Actions

    func refreshData() {
        viewModel.selectedIndex = networks.firstIndex { $0.name == NetworkManager.shared.selectedNetwork.name }
        viewModel.networkModels = networks
            .enumerated()
            .map { NetworkModel(networkName: $1.fullPresentedName, isSelected: $0 == viewModel.selectedIndex) }
    }

    func update(selectedIndex: Int) {
        guard viewModel.selectedIndex != selectedIndex else { return }
        Tari.shared.select(network: networks[selectedIndex])
        Tari.shared.canAutomaticalyReconnectWallet = false
        AppRouter.transitionToSplashScreen()
    }
}
