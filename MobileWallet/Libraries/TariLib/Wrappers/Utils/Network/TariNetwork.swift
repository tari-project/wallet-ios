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
    let isRecommended: Bool
    let dnsPeer: String
    let blockExplorerURL: URL?
    let currencySymbol: String
    let minValidVersion: String
    let version: String
}

extension TariNetwork {

    static var mainnet: Self {
        makeNetwork(
            name: "mainnet",
            presentedName: "Mainnet",
            isRecommended: true,
            dnsPeer: "seeds.tari.com",
            blockExplorerURL: URL(string: "https://explore.tari.com"),
            currencySymbol: "XTM",
            minValidVersion: "2.0.0-alpha.1",
            version: "2.1.1"
        )
    }

    static var nextnet: Self {
        makeNetwork(
            name: "nextnet",
            presentedName: "Nextnet",
            isRecommended: false,
            dnsPeer: "aurora.nextnet.tari.com",
            blockExplorerURL: URL(string: "https://explore-nextnet.tari.com"),
            currencySymbol: "tXTM",
            minValidVersion: "1.4.1-rc.0",
            version: "1.18.0-rc.0"
        )
    }

    static var esmeralda: Self {
        makeNetwork(
            name: "esmeralda",
            presentedName: "Esmeralda",
            isRecommended: true,
            dnsPeer: "seeds.esmeralda.tari.com",
            blockExplorerURL: nil,
            currencySymbol: "tXTM",
            minValidVersion: "1.6.0-pre.0",
            version: "1.6.0"
        )
    }

    var fullPresentedName: String {
        guard isRecommended else { return presentedName }
        return "\(presentedName) (\(localized("common.recommended")))"
    }

    var isBlockExplorerAvailable: Bool { blockExplorerURL != nil }

    func blockExplorerKernelURL(nounce: String, signature: String) -> URL? {
        if #available(iOS 16.0, *) {
            return blockExplorerURL?
                .appending(path: "kernel_search")
                .appending(queryItems: [
                    URLQueryItem(name: "nonces", value: nounce),
                    URLQueryItem(name: "signatures", value: signature)
                ])
        } else {
            guard let rawURL = blockExplorerURL?.absoluteString.appending("/kernel_search?nonces=\(nounce)&signatures=\(signature)") else { return nil }
            return URL(string: rawURL)
        }
    }

    private static func makeNetwork(
        name: String,
        presentedName: String,
        isRecommended: Bool,
        dnsPeer: String,
        blockExplorerURL: URL?,
        currencySymbol: String,
        minValidVersion: String,
        version: String
    ) -> Self {
        return Self(
            name: name,
            presentedName: presentedName,
            tickerSymbol: currencySymbol,
            isRecommended: isRecommended,
            dnsPeer: dnsPeer,
            blockExplorerURL: blockExplorerURL,
            currencySymbol: currencySymbol,
            minValidVersion: minValidVersion,
            version: version
        )
    }
}
