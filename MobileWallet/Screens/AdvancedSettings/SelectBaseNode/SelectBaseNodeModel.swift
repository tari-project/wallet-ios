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

    struct NodeModel: Hashable, Identifiable {
        let id: UUID = UUID()
        let title: String
        let subtitle: String
        let isSelected: Bool
        let canBeRemoved: Bool

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    // MARK: - View Model

    @Published private(set) var nodes: [NodeModel] = []
    @Published private(set) var errorMessaage: MessageModel?

    // MARK: - Properties

    private var predefinedNodes: [BaseNode] { NetworkManager.shared.defaultBaseNodes }
    private var avaiableNodes: [BaseNode] { NetworkManager.shared.allBaseNodes }
    private var selectedNodeIndex: Int?

    // MARK: - Setups

    private func updateSelectedNodeIndex() {
        let selectedBaseNode = NetworkManager.shared.selectedBaseNode
        selectedNodeIndex = avaiableNodes.firstIndex { $0.peer == selectedBaseNode?.peer }
    }

    private func updateViewModelNodes() {
        nodes = avaiableNodes
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
        do {
            try Tari.shared.wallet(.main).connection.select(baseNode: baseNode)
            selectedNodeIndex = index
            updateViewModelNodes()
        } catch {
            errorMessaage = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func addNode(name: String, hex: String, address: String) {

        guard !name.isEmpty else {
            errorMessaage = MessageModel(title: localized("add_base_node.error.title"), message: localized("add_base_node.error.no_name"), type: .error)
            return
        }

        do {
            try Tari.shared.wallet(.main).connection.addBaseNode(name: name, hex: hex, address: address)
            refreshData()
        } catch {
            errorMessaage = MessageModel(title: localized("add_base_node.error.title"), message: localized("add_base_node.error.invalid_peer"), type: .error)
        }
    }

    func deleteNode(index: Int) {
        guard avaiableNodes.count >= index else { return }
        let node = avaiableNodes[index]
        guard let index = NetworkManager.shared.customBaseNodes.firstIndex(of: node) else { return }
        NetworkManager.shared.customBaseNodes.remove(at: index)
        refreshData()
    }
}
