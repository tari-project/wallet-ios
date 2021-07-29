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

struct BaseNode: Equatable {

    // MARK: - Subelements

    enum Error: Swift.Error {
        case invalidPeerString
    }

    enum DefaultNode: CaseIterable {
        case ncal
        case oregon
        case london
        case stockholm
        case seoul
        case sydney

        func baseNode() throws -> BaseNode {
            switch self {
            case .ncal:
                return try BaseNode(name: "t-tbn-ncal", hex: "b60d073e2f2337fdd95a58065e1d0182cca1d36c20ed10b27bc1232bc2836a17", address: "/onion3/ssiz76b33emcerusblo6wba3ejqsub6ihkabjilem6ygoldodf6aenid:18141")
            case .oregon:
                return try BaseNode(name: "t-tbn-oregon", hex: "e2cef0473117da34108dd85d4425536b8a1f317478686a6d7a0bbb5c800a747d", address: "/onion3/3eiacmnozk7rcvrx7brhlssnpueqsjdsfbfmq63d2bk7h3vtah35tcyd:18141")
            case .london:
                return try BaseNode(name: "t-tbn-london", hex: "f606c82d23b2a2eda65156cef9efcaf77031d16a681fca99af7c08e98035f21d", address: "/onion3/i7nsgt2p7tkvpnhygnvihpuaqlunbtw3zti3qvi3eur7obkjkwgla4id:18141")
            case .stockholm:
                return try BaseNode(name: "t-tbn-stockholm", hex: "d23cfeb05674d25c5b970b6bffefdc1e7c2c1f1f9c32fde04688d1b94c81705a", address: "/onion3/obfjpoon2hm4uqerirhp4sf26bvq5ztokxhq274c2fg2uadrsu5drnqd:18141")
            case .seoul:
                return try BaseNode(name: "t-tbn-seoul", hex: "9cedfc16708f857e070e32d9cc1939fd6a57b5945ee97fdc707aa2f034ba6507", address: "/onion3/ryfa3iufgmvwmghyhamkjz5rfygde6kmy7e5jn5oc2n44cpbvey654ad:18141")
            case .sydney:
                return try BaseNode(name: "t-tbn-sydney", hex: "50ee725e2c6ca8282ab62bb7aef52a9c4df283ec99e00497a358dbaf4112ff0c", address: "/onion3/yrzdnyayg2jqym7rmeoc3lwixylasokqwkrtqyvutobllz27jdznuoyd:18141")
            }
        }
    }

    // MARK: - Properties

    let name: String
    let hex: String
    let address: String
    let publicKey: PublicKey

    var peer: String { "\(hex)::\(address)" }

    // MARK: - Initializers

    init(name: String, peer: String) throws {
        let peerComponents = peer.components(separatedBy: "::")
        guard peerComponents.count == 2 else { throw Error.invalidPeerString }
        try self.init(name: name, hex: peerComponents[0], address: peerComponents[1])
    }

    init(name: String, hex: String, address: String) throws {
        self.name = name
        self.hex = hex
        self.address = address

        publicKey = try PublicKey(hex: hex)

        try validateData()
    }

    // MARK: - Actions

    static func randomNode() throws -> Self { try DefaultNode.allCases.randomElement()!.baseNode() }
    static func allNodes() -> [Self] { DefaultNode.allCases.compactMap { try? $0.baseNode() }}

    private func validateData() throws {
        let regex = try NSRegularExpression(pattern: "[a-z0-9]{64}::\\/onion3\\/[a-z0-9]{56}:[0-9]{2,6}")
        let range = NSRange(location: 0, length: peer.utf16.count)
        guard regex.matches(in: peer, options: [], range: range).count == 1 else { throw Error.invalidPeerString }
    }
}

extension BaseNode: Codable {

    enum CodingKeys: CodingKey {
        case name, hex, address
    }

    init(from decoder: Decoder) throws {
        let containter = try decoder.container(keyedBy: CodingKeys.self)
        let name = try containter.decode(String.self, forKey: .name)
        let hex = try containter.decode(String.self, forKey: .hex)
        let address = try containter.decode(String.self, forKey: .address)
        try self.init(name: name, hex: hex, address: address)
    }
}
