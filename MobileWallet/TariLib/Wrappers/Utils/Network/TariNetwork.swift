//  TariNetwork.swift

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

struct TariNetwork {
    let name: String
    let tickerSymbol: String
    let baseNodes: [BaseNode]
}

extension TariNetwork {

    enum Error: Swift.Error {
        case noPredefinedNodes
    }

    var allBaseNodes: [BaseNode] { baseNodes + customBaseNodes }

    var settings: NetworkSettings {
        let allSettings = GroupUserDefaults.networksSettings ?? []

        guard let existingSettings = allSettings.first(where: { $0.name == name }) else {
            let newSettings = NetworkSettings(name: name, selectedBaseNode: baseNodes.randomElement()!, customBaseNodes: [], isCloudBackupEnabled: false)
            update(settings: newSettings)
            return newSettings
        }
        return existingSettings
    }

    var selectedBaseNode: BaseNode {
        get { settings.selectedBaseNode }
        set { update(settings: settings.update(selectedBaseNode: newValue)) }
    }

    var customBaseNodes: [BaseNode] {
        get { settings.customBaseNodes }
        set { update(settings: settings.update(customBaseNodes: newValue)) }
    }

    var isCloudBackupEnabled: Bool {
        get { settings.isCloudBackupEnabled }
        set { update(settings: settings.update(isCloudBackupEnabled: newValue)) }
    }

    func randomNode() throws -> BaseNode {
        guard let randomNode = baseNodes.randomElement() else { throw Error.noPredefinedNodes }
        return randomNode
    }

    private func update(settings: NetworkSettings) {
        var allSettings = GroupUserDefaults.networksSettings ?? []
        allSettings.removeAll { $0 == settings }
        allSettings.append(settings)
        GroupUserDefaults.networksSettings = allSettings
    }
}

extension TariNetwork {

    static var all: [TariNetwork] { [weatherwax, igor].compactMap { $0 } }

    static var weatherwax: Self {
        makeNetwork(
            name: "weatherwax",
            isMainNet: false,
            rawBaseNodes: [
                "jozi": "98bc76afc1c35ad4651bdc9ef57bbe0655a2ea3cd86c0e19b5fd5890546eb040::/onion3/33izgtjkrlxhxybj6luqowkpiy2wvte43osejnbqyieqtdfhovzghxad:18141",
                "london": "9a26e910288213d649b26f9a7a7ee51fe2b2a67ff7d42334523463bf4be94312::/onion3/56kq54ylttnbl5ikotqex3oqvtzlxdpn7zlx4v56rvzf4kq7eezlclid:18141",
                "ncal": "6afd5b3c7772ad7d4bb26e0c19668fe04f2d68f99de9e132bee50a6c1846946d::/onion3/may4ajbmcn4dlnzf6fanvqlklxzqiw6qwu6ywqwkjc3bb354rc2i5wid:18141",
                "nvir": "8e7beec9becdc44fe6015a00d97a77fa3dbafe65127dcc988df6326bd9fd040d::/onion3/3pise36l4imoopsbjic5rtw67adx7rms6w5pgjmccpdwiqx66j7oqcqd:18141",
                "oregon": "80bb590d943a46e63ae79af5dc2c7d35a3dcd7922c182b28f619dc4cfc366f44::/onion3/oaxwahri7r3h5qjlcdbveyjmg4jsttausik66bicmhixft73nmvecdad:18141",
                "seoul": "981cc8cd1e4fe2f99ea1bd3e0ab1e7821ca0bfab336a4967cfec053fee86254c::/onion3/7hxpnxrxycdfevirddau7ybofwedaamjrg2ijm57k2kevh5q46ixamid:18141",
                "stockholm": "f2ce179fb733725961a5f7e1e45dacdd443dd43ba6237438d6abe344fb717058::/onion3/nvgdmjf4wucgatz7vemzvi2u4sw5o4gyzwuikagpepoj4w7mkii47zid:18141",
                "sydney": "909c0160f4d8e815aba5c2bbccfcceb448877e7b38759fb160f3e9494484d515::/onion3/qw5uxv533sqdn2qoncfyqo35dgecy4rt4x27rexi2her6q6pcpxbm4qd:18141"
            ]
        )
    }

    static var igor: Self {
        makeNetwork(
            name: "igor",
            isMainNet: false,
            rawBaseNodes: [
                "ncal": "8e7eb81e512f3d6347bf9b1ca9cd67d2c8e29f2836fc5bd608206505cc72af34::/onion3/l4wouomx42nezhzexjdzfh7pcou5l7df24ggmwgekuih7tkv2rsaokqd:18141",
                "oregon": "00b35047a341401bcd336b2a3d564280a72f6dc72ec4c739d30c502acce4e803::/onion3/ojhxd7z6ga7qrvjlr3px66u7eiwasmffnuklscbh5o7g6wrbysj45vid:18141",
                "stockholm": "40a9d8573745072534bce7d0ecafe882b1c79570375a69841c08a98dee9ecb5f::/onion3/io37fylc2pupg4cte4siqlsmuszkeythgjsxs2i3prm6jyz2dtophaad:18141",
                "sydney": "126c7ee64f71aca36398b977dd31fbbe9f9dad615df96473fb655bef5709c540::/onion3/6ilmgndocop7ybgmcvivbdsetzr5ggj4hhsivievoa2dx2b43wqlrlid:18141"
            ]
        )
    }

    private static func makeNetwork(name: String, isMainNet: Bool, rawBaseNodes: [String: String]) -> Self {
        let baseNodes = rawBaseNodes.compactMap { try? BaseNode(name: $0, peer: $1) }
        let currencySymbol = isMainNet ? "XTR" : "tXTR"
        return Self(name: name, tickerSymbol: currencySymbol, baseNodes: baseNodes)
    }
}
