//  TariConnectionService.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 04/10/2022
	Using Swift 5.0
	Running on macOS 12.4

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

final class TariConnectionService: CoreTariService {

    enum InternalError: Error {
            case invalidPeerString
        }

    // MARK: - Actions

    @discardableResult func select(baseNode: BaseNode) throws -> Bool {
        services.validation.reset()
        do {
            let result = try walletManager.set(baseNodePeer: baseNode.makePublicKey(), address: baseNode.address)
            NetworkManager.shared.selectedBaseNode = baseNode
            return result
        } catch FFIWalletManager.GeneralError.unableToCreateWallet {
            NetworkManager.shared.selectedBaseNode = baseNode
            return false
        } catch {
            throw error
        }
    }

    @discardableResult func selectCurrentNode() throws -> Bool {
        guard let selectedBaseNode = NetworkManager.shared.selectedBaseNode else { return false }
        return try select(baseNode: selectedBaseNode)
    }

    func addBaseNode(name: String, hex: String, address: String?) throws {
        let baseNode = BaseNode(name: name, hex: hex, address: address)
        NetworkManager.shared.customBaseNodes.append(baseNode)
        try select(baseNode: baseNode)
    }

    func addBaseNode(name: String, peer: String) throws {
        let components = peer.components(separatedBy: "::")
        guard components.count == 2 else { throw InternalError.invalidPeerString }
        try addBaseNode(name: name, hex: components[0], address: components[1])
    }

    func defaultBaseNodePeers() throws -> [BaseNode] {
        try walletManager.seedPeers()
            .all
            .enumerated()
            .map { try BaseNode(name: "\(NetworkManager.shared.selectedNetwork.presentedName) \($0 + 1)", hex: $1.byteVector.hex, address: nil) }
    }
}
