//  BaseNode.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/03/14
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

import Foundation

enum BaseNodeErrors: Error {
    case invalidPeerString
    case addressNotOnion
}

struct BaseNode {
    let publicKey: PublicKey
    let address: String
    let isCustom: Bool

    static let addressPattern = "\\/onion3\\/[a-z0-9]{56}:[0-9]{2,6}"
    private static let hasCustomBaseNodeSetKey = "hasCustomBaseNodeSet"
    /// If we have a custom base node set don't try set a random one when syncs fail
    static var hasCustomBaseNodeSet: Bool {
        get {
            UserDefaults.standard.bool(forKey: BaseNode.hasCustomBaseNodeSetKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: BaseNode.hasCustomBaseNodeSetKey)
        }
    }

    var peer: String {
        return "\(publicKey.hex.0)::\(address)"
    }

    //Expects format found in Tari code base for setting a peer: pubkey::/onion/key:port
    //Can be used to determine if the users clipboard contains a valid base node seed
    init(_ peer: String, isCustom: Bool = false) throws {
        let regex = try NSRegularExpression(pattern: "[a-z0-9]{64}::\(BaseNode.addressPattern)")
        guard regex.matches(in: peer, options: [], range: NSRange(location: 0, length: peer.utf16.count)).count == 1 else {
            throw BaseNodeErrors.invalidPeerString
        }

        let splitPeerDetails = peer.components(separatedBy: "::")

        //Sanity check. This would actually get caught by the regex above
        guard splitPeerDetails.count == 2 else {
            throw BaseNodeErrors.invalidPeerString
        }

        self.publicKey = try PublicKey(hex: splitPeerDetails[0])
        self.address = splitPeerDetails[1]
        self.isCustom = isCustom
    }

    init(publicKey: PublicKey, address: String, isCustom: Bool = false) throws {
        let regex = try NSRegularExpression(pattern: BaseNode.addressPattern)

        guard regex.matches(in: address, options: [], range: NSRange(location: 0, length: address.utf16.count)).count == 1 else {
            throw BaseNodeErrors.invalidPeerString
        }

        self.publicKey = publicKey
        self.address = address
        self.isCustom = isCustom
    }

    func set(_ wallet: Wallet) throws {
        try wallet.addBaseNodePeer(self)
        try? wallet.syncBaseNode()
    }
}
