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
    let presentedName: String
    let tickerSymbol: String
    let baseNodes: [BaseNode]
    let faucetURL: URL?
}

extension TariNetwork {

    enum Error: Swift.Error {
        case noPredefinedNodes
    }

    var allBaseNodes: [BaseNode] { baseNodes.sorted { $0.name < $1.name } + customBaseNodes }

    private var settings: NetworkSettings {
        let allSettings = GroupUserDefaults.networksSettings ?? []

        guard let existingSettings = allSettings.first(where: { $0.name == name }) else {
            let newSettings = NetworkSettings(name: name, selectedBaseNode: baseNodes.randomElement()!, customBaseNodes: [])
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

    static var all: [TariNetwork] { [esmeralda].compactMap { $0 } }
    
    static var esmeralda: Self {
        makeNetwork(
            name: "esmeralda",
            presentedName: "Esmeralda (\(localized("common.recommended")))",
            isMainNet: false,
            rawBaseNodes: [
                "london": "083ff333ad7e0e9f3678b67378ec339074474342a6357de64a76bdf15e4c955b::/onion3/ldgdytcrwzfbmbpz3dmyi6yzqzqbeamitpb2saxzxmp52qywlmsg4vyd:18141",
                "ireland": "747d45b8416ffe605d17958d36747eab7d3f5fc3d671e1b1b4884b2a44b98365::/onion3/n35n5fikcqqhhhjcdzpqul5v74mu7k6nikpafmlnwgiapphiw45tmryd:18141",
                "ncal": "ea420ae2948739bc35907b8ab5a2d41526ccef22ec92f8f8e2bb398500bf435a::/onion3/uybnlnzve4j4w2lj5bdoe2uurwsbjm73ck2cotlnknhu2l7msn26oeyd:18141",
                "nvir": "f688c69f2397dc0d4ad18168cd6ad13f93241a665acf19ab7f358fd661ac3d1c::/onion3/qejny5yprzidxt4rhstjmhsyfmeq4yb4r6tnn3pqowjr7e7roxcpxsqd:18141",
                "oregon": "8648575c606269b032f43cd0d54728628ddb911e636bd65ea36e867a5ffd3643::/onion3/5d2owx6uoqcsoapprattb4fmektm3rcpfyzmmwmf64dsu55mhcqef2yd:18141",
                "seoul": "78b2c0bda70fd12a9987757ffc2851e197080af804353e8e025d28c785b6b447::/onion3/ysj76foyp7qkl7d5x63hyocmp5ydwcgkb25oalo23kj2vvx7zjvofqad:18141",
                "area7": "ced769f66b4398ea62eb9f74a08b5ebfdc1a51554a695c0aff4b949fea875b61::/onion3/m4koteatwthmozsbg54y6c4io26d4md6ub5l3rnco4s7a4qu2xkvonyd:18141",
                "area8": "40717ea5146cf6183c07469d188792b12a57b9da2e5af5bc50df270ff789257f::/onion3/qhmrwr2h3fnszwc4udhlgfpealm7mvw64enqghullrarc633fzmd6zqd:18141"
            ],
            faucetURL: URL(string: "https://esmeralda-faucet.tari.com")
        )
    }

    private static func makeNetwork(name: String, presentedName: String, isMainNet: Bool, rawBaseNodes: [String: String], faucetURL: URL?) -> Self {
        let baseNodes = rawBaseNodes.compactMap { try? BaseNode(name: $0, peer: $1) }
        let currencySymbol = isMainNet ? "XTR" : "tXTR"
        return Self(name: name, presentedName: presentedName, tickerSymbol: currencySymbol, baseNodes: baseNodes, faucetURL: faucetURL)
    }
}
