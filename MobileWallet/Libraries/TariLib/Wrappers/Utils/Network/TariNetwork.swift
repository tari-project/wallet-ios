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

    static var all: [TariNetwork] { [nextnet, stagenet].compactMap { $0 } }

    static var nextnet: Self {
        makeNetwork(
            name: "nextnet",
            presentedName: "NextNet (\(localized("common.recommended")))",
            isMainNet: false,
            rawBaseNodes: [
                "NextNet 1": "0cff11dff44458bfea3e39444d440e54260746ff2a5ce6a6c3f7355decff2167::/ip4/54.195.217.107/tcp/18189",
                "NextNet 2": "0cff11dff44458bfea3e39444d440e54260746ff2a5ce6a6c3f7355decff2167::/onion3/h6oj2cusgtaxo63zbfw2wjir4mltkqzz4jquoak2i5mvgyszaieowwad:18141",
                "NextNet 3": "4c236de788e803ef9615f72a4d973cf3f8a9b83c9d2fb176cbaf65c1b0442572::/onion3/3jtk3e2ud3zqtbrq36sw6ata6u5epkjmqgr5tfuemcfpyhisrzkgbtyd:18141"
            ]
        )
    }

    static var stagenet: Self {
        makeNetwork(
            name: "stagenet",
            presentedName: "StageNet",
            isMainNet: false,
            rawBaseNodes: [
                "StageNet 01": "1a294e0312ba507899a3f3eadc390d492ab620ce29cad94ba496b4d4fd78aa16::/ip4/34.252.174.111/tcp/18189",
                "StageNet 02": "1a294e0312ba507899a3f3eadc390d492ab620ce29cad94ba496b4d4fd78aa16::/onion3/mfqsxcw4fsq7djzbbgcgfvx3tl6zcciqxzdrl7w5axozbs654zojijyd:18141",
                "StageNet 03": "34cfce7c91290a7eb82127a76d7608d18df3992ec66fbcf9d6f97ca85fe10c17::/onion3/2tmbjqsvnaelbxv66tm3wze3oudwzdlfifwqptofgcmuvgvhdw563oid:18141",
                "StageNet 04": "38feed1438270fc8c9c7211d3a5faf0aeab1b65d5bce2083476be6483b35b217::/onion3/2cufeex4t2rr3466cw5ijhexsapyg2hwkoc6mlwfiusiyg5dr7wkxdad:18141",
                "StageNet 05": "3cfd696d646c0b2b2ab19de2f76727553d34e4bf1c5be41a1b9079430f0ea331::/ip4/54.77.66.39/tcp/18189",
                "StageNet 06": "3cfd696d646c0b2b2ab19de2f76727553d34e4bf1c5be41a1b9079430f0ea331::/onion3/b6gtdaogqgs26jy32nb2u3elpalfzcnaa5krkpczeltpod5i54anh2id:18141",
                "StageNet 07": "502f6306c80293e0455b1dd9b05aefaa32002630e7d1f628f09a652479f26727::/onion3/t76s5ngz3j6vxt2isjlp5utwrwjw2wl56ffknar62q24y33ucuzswhid:18141",
                "StageNet 08": "6222a5627a0d53cc2fcc8d829ea79b7e07af6e305133bb71e8e72475f34cea29::/onion3/fc5apmwrtt3nmuw7srp4khcnpedzhfwynxmf4nwceqrn5xwutvtkg6ad:18141",
                "StageNet 09": "70a5a84c75a7950cc805c17c6cf99160e8df6786df82cb93a044df1456ff566d::/onion3/whwgiuqkc23jtx266nbbjilzz6lrc7enljtef6tjlgvxijunkwmwh6yd:18141",
                "StageNet 10": "b040d2e4cabad05fa0bb671bcfc822bd26fb526a3b116bfe74d0d516c4589b41::/ip4/63.35.51.217/tcp/18189",
                "StageNet 11": "b040d2e4cabad05fa0bb671bcfc822bd26fb526a3b116bfe74d0d516c4589b41::/onion3/6idckzqo5hejteuitzbzthstf22ux5schi5f5wjia5w3pvbtt7hrb3ad:18141",
                "StageNet 12": "c81a8e314b7c06fd136d7e836b26fe821de36ebb42a3c47f671190eb9fc5695d::/ip4/54.73.25.246/tcp/18189",
                "StageNet 13": "c81a8e314b7c06fd136d7e836b26fe821de36ebb42a3c47f671190eb9fc5695d::/onion3/yhvolqnqbznwc2fet7laxmusqcoeaie3bfc3vnmq26udz67ayscqgyqd:18141",
                "StageNet 14": "d80b5ccaea9d85f868ba55c243f8fc5c7c8a31ead0c28f072e42ac8ae862dd00::/onion3/dskj4ecpegae2ypzq7icpmhcu7ylbbo7siqqdul6537zi3ykx3hzqsqd:18141"
            ]
        )
    }

    private static func makeNetwork(name: String, presentedName: String, isMainNet: Bool, rawBaseNodes: [String: String]) -> Self {
        let baseNodes = rawBaseNodes.compactMap { try? BaseNode(name: $0, peer: $1) }
        let currencySymbol = isMainNet ? "XTR" : "tXTR"
        return Self(name: name, presentedName: presentedName, tickerSymbol: currencySymbol, baseNodes: baseNodes)
    }
}
