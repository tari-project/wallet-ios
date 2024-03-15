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
    let dnsPeer: String
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

    static var all: [TariNetwork] { [nextnet].compactMap { $0 } }

    static var nextnet: Self {
        makeNetwork(
            name: "nextnet",
            presentedName: "NextNet (\(localized("common.recommended")))",
            isMainNet: false,
            rawBaseNodes: [
                "NextNet 1": "0cff11dff44458bfea3e39444d440e54260746ff2a5ce6a6c3f7355decff2167::/ip4/54.195.217.107/tcp/18189",
                "NextNet 2": "0cff11dff44458bfea3e39444d440e54260746ff2a5ce6a6c3f7355decff2167::/onion3/h6oj2cusgtaxo63zbfw2wjir4mltkqzz4jquoak2i5mvgyszaieowwad:18141",
                "NextNet 3": "4c236de788e803ef9615f72a4d973cf3f8a9b83c9d2fb176cbaf65c1b0442572::/onion3/3jtk3e2ud3zqtbrq36sw6ata6u5epkjmqgr5tfuemcfpyhisrzkgbtyd:18141"
            ],
            dnsPeer: "seeds.nextnet.tari.com"
        )
    }

    private static func makeNetwork(name: String, presentedName: String, isMainNet: Bool, rawBaseNodes: [String: String], dnsPeer: String) -> Self {
        let baseNodes = rawBaseNodes.compactMap { try? BaseNode(name: $0, peer: $1) }
        let currencySymbol = isMainNet ? "XTR" : "tXTR"
        return Self(name: name, presentedName: presentedName, tickerSymbol: currencySymbol, baseNodes: baseNodes, dnsPeer: dnsPeer)
    }
}
