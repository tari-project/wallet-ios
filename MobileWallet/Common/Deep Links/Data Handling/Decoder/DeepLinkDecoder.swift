//  DeepLinkDecoder.swift

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

struct DeepLinkDecoder {

    private let parameters: [String: Any]

    init(parameters: [String: Any]) {
        self.parameters = parameters
    }

    init(deeplink: URL) {
        parameters = deeplink
            .keysValueComponents?
            .map { Self.object(keys: $0, value: $1) }
            .reduce(into: [String: Any]()) { $0.nestedMerge(with: $1) } ?? [:]
    }

    private static func object(keys: [String], value: Any) -> [String: Any] {
        var keys = keys
        let workingKey = keys.popLast()!
        let value = [workingKey: value]
        guard !keys.isEmpty else { return value }
        return object(keys: keys, value: value)
    }
}

extension DeepLinkDecoder: Decoder {

    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(DeepLinkKeyedDecodingContainter(parameters: parameters))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer { DeeplinkUnkeyedDecodingContainer(parameters: parameters) }
    func singleValueContainer() throws -> SingleValueDecodingContainer { fatalError() }
}
