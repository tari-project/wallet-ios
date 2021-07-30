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
        case invalidPeerString, noPredefinedNodes
    }

    private static let defaultNodes: [String: String] = [
        "london": "9a26e910288213d649b26f9a7a7ee51fe2b2a67ff7d42334523463bf4be94312::/onion3/56kq54ylttnbl5ikotqex3oqvtzlxdpn7zlx4v56rvzf4kq7eezlclid:18141",
        "ncal": "6afd5b3c7772ad7d4bb26e0c19668fe04f2d68f99de9e132bee50a6c1846946d::/onion3/may4ajbmcn4dlnzf6fanvqlklxzqiw6qwu6ywqwkjc3bb354rc2i5wid:18141",
        "nvir": "8e7beec9becdc44fe6015a00d97a77fa3dbafe65127dcc988df6326bd9fd040d::/onion3/3pise36l4imoopsbjic5rtw67adx7rms6w5pgjmccpdwiqx66j7oqcqd:18141",
        "oregon": "80bb590d943a46e63ae79af5dc2c7d35a3dcd7922c182b28f619dc4cfc366f44::/onion3/oaxwahri7r3h5qjlcdbveyjmg4jsttausik66bicmhixft73nmvecdad:18141",
        "seoul": "981cc8cd1e4fe2f99ea1bd3e0ab1e7821ca0bfab336a4967cfec053fee86254c::/onion3/7hxpnxrxycdfevirddau7ybofwedaamjrg2ijm57k2kevh5q46ixamid:18141",
        "stockholm": "f2ce179fb733725961a5f7e1e45dacdd443dd43ba6237438d6abe344fb717058::/onion3/nvgdmjf4wucgatz7vemzvi2u4sw5o4gyzwuikagpepoj4w7mkii47zid:18141",
        "sydney": "909c0160f4d8e815aba5c2bbccfcceb448877e7b38759fb160f3e9494484d515::/onion3/qw5uxv533sqdn2qoncfyqo35dgecy4rt4x27rexi2her6q6pcpxbm4qd:18141"
    ]

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

    static func randomNode() throws -> Self {
        guard let randomElement = defaultNodes.randomElement() else { throw Error.noPredefinedNodes }
        return try BaseNode(name: randomElement.key, peer: randomElement.value)
    }

    static func allNodes() -> [Self] { defaultNodes.compactMap { try? BaseNode(name: $0.key, peer: $0.value) } }

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
