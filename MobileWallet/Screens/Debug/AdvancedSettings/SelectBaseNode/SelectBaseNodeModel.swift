//  SelectBaseNodeModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 19/07/2021
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

final class SelectBaseNodeModel {

    struct NodeModel: Hashable {
        let title: String
        let subtitle: String
        let isSelected: Bool
        let canBeRemoved: Bool
    }

    final class ViewModel {
        @Published var nodes: [NodeModel] = []
    }

    // MARK: - Properties

    var viewModel = ViewModel()

    private let predefinedNodes: [BaseNode] = NetworkManager.shared.selectedNetwork.baseNodes.sorted { $0.name < $1.name }
    private var avaiableNodes: [BaseNode] { NetworkManager.shared.selectedNetwork.allBaseNodes }
    private var selectedNodeIndex: Int?

    // MARK: - Setups

    private func updateSelectedNodeIndex() {
        let selectedNode = NetworkManager.shared.selectedNetwork.selectedBaseNode
        selectedNodeIndex = avaiableNodes.firstIndex { $0 == selectedNode }
    }

    private func updateViewModelNodes() {
        viewModel.nodes = avaiableNodes
            .enumerated()
            .map {
                let isSelected = $0 == selectedNodeIndex
                let isCustomNode = !predefinedNodes.contains($1)
                return NodeModel(
                    title: $1.name,
                    subtitle: $1.peer,
                    isSelected: isSelected,
                    canBeRemoved: !isSelected && isCustomNode
                )
            }
    }

    // MARK: - Actions

    func refreshData() {
        updateSelectedNodeIndex()
        updateViewModelNodes()
    }

    func selectNode(index: Int) {
        let baseNode = avaiableNodes[index]
        try? TariLib.shared.update(baseNode: baseNode, syncAfterSetting: true)
        selectedNodeIndex = index
        updateViewModelNodes()
    }

    func deleteNode(index: Int) {
        guard avaiableNodes.count >= index else { return }
        let node = avaiableNodes[index]
        guard let index = NetworkManager.shared.selectedNetwork.customBaseNodes.firstIndex(of: node) else { return }
        NetworkManager.shared.selectedNetwork.customBaseNodes.remove(at: index)
        refreshData()
    }
}
