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
                "london": "68667362ceadf4543f4bac3a47e8bd1b6c5cbdab90fa781392e419b8ee03a153::/onion3/lf2p2zwuinjkk4bzzwddbol64x5ycofanja25zu2oxmrofa3nk43ypyd:18141",
                "ireland": "a482e5541dfc76b53bddda5ad68a8bdec290c862e6e5c716e6014acd65347411::/onion3/3mpymjycel3ufraw55cnl5tvednrnzmqvq56vaydswnboibkja2d4tid:18141",
                "ncal": "fe67c469fe61f31765f43ec781dcdde78092204d36bbdc544cb09ca41d495e06::/onion3/tbmffvb67hf2ujfh5md6n2hhgi5guao2ahmv54bh3vr5x3wjor2u5cid:18141",
                "nvir": "3cf5da9cecaf347b6fcfee9c8751be9fad529878572b19da3bd24c9704ab2426::/onion3/jxh2bl4zunbrd3y7pgayvcj3l4iczcne2s5h47lclv6e3kjzxbaplgqd:18141",
                "oregon": "18df727907476f455809d3794cfec1d489b6bf305d06467e8cf5cb102402530b::/onion3/vv26lxr727pvvxbmgf3sdbobqsqqfrtasfkavs4js5vlq3lk34a54hid:18141",
                "seoul": "72468fae60e65218276793eabb764ed7280049bb74560ca18710755234bcce49::/onion3/oqpd4wgd7tzagvvgkfwrdu6ssvoqaw4zdoqhvutof2flgkgj6gwrpfqd:18141"
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
