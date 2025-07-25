//  DeepLinkFormatter.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 01/03/2022
	Using Swift 5.0
	Running on macOS 12.1

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

enum DeeplinkType: String {
    case transactionSend = "/transactions/send"
    case contacts = "/contacts"
    case profile = "/profile"
    case paperWallet = "/paper_wallet"
    case login = "/airdrop/auth"
}

protocol DeepLinkable: Codable {
    static var type: DeeplinkType { get }
}

extension DeepLinkable {
    static var command: String { type.rawValue }
    var type: DeeplinkType { Self.type }
}

enum DeepLinkError: Error {
    case invalidNetworkName
    case invalidCommandName
    case unableToParse(key: String)
    case unableToEncode(error: Error)
}

enum DeepLinkFormatter {

    private static var validScheme: String { "tari" }
    private static var validNetworkName: String { NetworkManager.shared.selectedNetwork.name }

    static func model<T: DeepLinkable>(type: T.Type, deeplink: URL) throws -> T {
        guard let networkName = deeplink.host else { throw DeepLinkError.invalidNetworkName }
        guard deeplink.path == T.command else { throw DeepLinkError.invalidCommandName }
        let decoder = DeepLinkDecoder(deeplink: deeplink)
        return try T(from: decoder)

    }

    static func deeplink<T: DeepLinkable>(model: T, networkName: String = validNetworkName) throws -> URL? {
        let encoder = DeepLinkEncoder()

        do {
         try model.encode(to: encoder)
        } catch {
            throw DeepLinkError.unableToEncode(error: error)
        }

        let query = encoder.result

        var urlComponents = URLComponents()
        urlComponents.scheme = validScheme
        urlComponents.host = networkName
        urlComponents.path = T.command

        if !query.isEmpty {
            urlComponents.query = query
        }

        return urlComponents.url
    }
}
