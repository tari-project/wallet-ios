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

    static var all: [TariNetwork] { [stagenet].compactMap { $0 } }

    static var stagenet: Self {
        makeNetwork(
            name: "stagenet",
            presentedName: "StageNet (\(localized("common.recommended")))",
            isMainNet: false,
            rawBaseNodes: [
                "StageNet 01": "a062ae2345b0db0df9fb1504b99511e23d98f8513f9b5503efcc6dad8eca7e47::/onion3/rhoqxfbzz3uidp23erxu4mkwwexc2gg4q45rcxfpbhb35ycdv4ex2fid:18141",
                "StageNet 02": "b2c5db3a2858451d241d4e88677536f9e82a760111962785fb6a3cddc41f766e::/onion3/q32yxdg7l7os2zzx64e3f5u4mzib3lxlkdyguybkhtkd4pwfkpunjcyd:18141",
                "StageNet 03": "1cdf34d27bee5e1edbc343a17f7d79a8a1974fe3f790e899d8987c1f11697e41::/onion3/fwvmhhcifr7yh7neqsweyjvu4bnlmljg6a6fsjdwify3b4aals2oc3yd:18141",
                "StageNet 04": "a42eea2088e0ef663b8d29a9d039b0e5d51c1ddc1cf5ae28feb05ed52ead5a69::/onion3/k5khqg7fwkq7ujxievps22r42i5ykuieai64ze3kj5snsjkew3v7piid:18141",
                "StageNet 05": "d49df057e1f1ae399ffabdeb59e7ad542439ab2b0bbd9ed23042175a93e4d03c::/onion3/hjeczose7rjo6o6qhsszkuzhrm6qfs7s4yeqzeuz2m67rkpijrtrwsad:18141",
                "StageNet 06": "e65f18cb4a362b33667e0d39b3c93f06c0e822af09906914bdc65907b7cdc130::/onion3/uuv6j3vwq4dac6z3dblc2mjcoecrnxfka3wg43bcass5avbzix4nmzyd:18141",
                "StageNet 07": "0a755298f4bee8e6db64e345fe8f937e3882693a48c71b942b88744761b02067::/onion3/ksdogedobmqoud6ampvrjrhoozftgfkolhxqvnt7mo7ajqczku5tyyqd:18141",
                "StageNet 08": "0c22d3dc3983c74131d7dfb0c4c8ae9fb90c434826cf8ccc71e793bb72d36213::/onion3/so2be7uyg4kf5l7ys3fbk4eqovsfi63yuaqj7pahkkw2crujq43jdnyd:18141",
                "StageNet 09": "2ade610a2e95f1c686873944096f5a1f2c7ffcf47d67112b472c9208cc6e9532::/onion3/rmiknlrf7ngfvgpayf5qzuer2c547rzmyqbkbw45w5uessi3jodasdqd:18141",
                "StageNet 10": "369ae9a89c3fc2804d6ec07e20bf10e5d0e72f565a71821fc7c611ae5bee0116::/onion3/crvsrmoyrk5uatvnafsmoykiqgywdqowupn3auq25iz7zxyf7xusjxid:18141"
            ]
        )
    }

    private static func makeNetwork(name: String, presentedName: String, isMainNet: Bool, rawBaseNodes: [String: String]) -> Self {
        let baseNodes = rawBaseNodes.compactMap { try? BaseNode(name: $0, peer: $1) }
        let currencySymbol = isMainNet ? "XTR" : "tXTR"
        return Self(name: name, presentedName: presentedName, tickerSymbol: currencySymbol, baseNodes: baseNodes)
    }
}
