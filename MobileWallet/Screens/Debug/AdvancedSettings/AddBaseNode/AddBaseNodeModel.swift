//  AddBaseNodeModel.swift

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

final class AddBaseNodeModel {

    final class ViewModel {
        @Published var name: String = ""
        @Published var peer: String = ""
        @Published var isFinished: Bool = false
        @Published var errorMessage: String?
    }

    // MARK: - Properties

    let viewModel = ViewModel()

    // MARK: - Actions

    func saveNode() {

        guard !viewModel.name.isEmpty else {
            viewModel.errorMessage = localized("add_base_node.error.invalid_peer")
            return
        }

        do {
            let node = try BaseNode(name: viewModel.name, peer: viewModel.peer)
            try? TariLib.shared.update(baseNode: node, syncAfterSetting: false)

            NetworkManager.shared.selectedNetwork.customBaseNodes.append(node)
            NetworkManager.shared.selectedNetwork.selectedBaseNode = node

            viewModel.isFinished = true
            viewModel.errorMessage = nil
        } catch {
            viewModel.errorMessage = localized("add_base_node.error.invalid_peer")
        }
    }
}
