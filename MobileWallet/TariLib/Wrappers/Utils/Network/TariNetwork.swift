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

    static var all: [TariNetwork] { [dibbler].compactMap { $0 } }
    
    static var dibbler: Self {
        makeNetwork(
            name: "dibbler",
            presentedName: "Dibbler (\(localized("common.recommended")))",
            isMainNet: false,
            rawBaseNodes: [
                "london": "c2eca9cf32261a1343e21ed718e79f25bfc74386e9305350b06f62047f519347::/onion3/6yxqk2ybo43u73ukfhyc42qn25echn4zegjpod2ccxzr2jd5atipwzqd:18141",
                "ireland": "42fcde82b44af1de95a505d858cb31a422c56c4ac4747fbf3da47d648d4fc346::/onion3/2l3e7ysmihc23zybapdrsbcfg6omtjtfkvwj65dstnfxkwtai2fawtyd:18141",
                "ncal": "50e6aa8f6c50f1b9d9b3d438dfd2a29cfe1f3e3a650bd9e6b1e10f96b6c38f4d::/onion3/7s6y3cz5bnewlj5ypm7sekhgvqjyrq4bpaj5dyvvo7vxydj7hsmyf5ad:18141",
                "nvir": "36a9df45e1423b5315ffa7a91521924210c8e1d1537ad0968450f20f21e5200d::/onion3/v24qfheti2rztlwzgk6v4kdbes3ra7mo3i2fobacqkbfrk656e3uvnid:18141",
                "oregon": "be128d570e8ec7b15c101ee1a56d6c56dd7d109199f0bd02f182b71142b8675f::/onion3/ha422qsy743ayblgolui5pg226u42wfcklhc5p7nbhiytlsp4ir2syqd:18141",
                "seoul": "3e0321c0928ca559ab3c0a396272dfaea705efce88440611a38ff3898b097217::/onion3/sl5ledjoaisst6d4fh7kde746dwweuge4m4mf5nkzdhmy57uwgtb7qqd:18141"
            ],
            faucetURL: URL(string: "https://dibbler-faucet.tari.com")
        )
    }

    private static func makeNetwork(name: String, presentedName: String, isMainNet: Bool, rawBaseNodes: [String: String], faucetURL: URL?) -> Self {
        let baseNodes = rawBaseNodes.compactMap { try? BaseNode(name: $0, peer: $1) }
        let currencySymbol = isMainNet ? "XTR" : "tXTR"
        return Self(name: name, presentedName: presentedName, tickerSymbol: currencySymbol, baseNodes: baseNodes, faucetURL: faucetURL)
    }
}
