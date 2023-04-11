//  DeepLinkKeyedDecodingContainter.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 07/04/2023
	Using Swift 5.0
	Running on macOS 13.0

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

struct DeepLinkKeyedDecodingContainter<Key: CodingKey>: KeyedDecodingContainerProtocol {

    let codingPath: [CodingKey] = []
    var allKeys: [Key] { dataSource.parameters.keys.compactMap { Key(stringValue: $0) }}

    private let dataSource: DeeplinkDataSource

    init(parameters: [String: Any]) {
        dataSource = DeeplinkDataSource(parameters: parameters)
    }

    func contains(_ key: Key) -> Bool { dataSource.parameters.keys.contains(key.stringValue) }
    func decodeNil(forKey key: Key) throws -> Bool { false }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try dataSource.value(key: key.stringValue) }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { try dataSource.value(key: key.stringValue) }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try dataSource.value(key: key.stringValue) }
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try dataSource.value(key: key.stringValue) }
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try dataSource.value(key: key.stringValue) }
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try dataSource.value(key: key.stringValue) }
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try dataSource.value(key: key.stringValue) }
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try dataSource.value(key: key.stringValue) }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try dataSource.value(key: key.stringValue) }
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try dataSource.value(key: key.stringValue) }
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try dataSource.value(key: key.stringValue) }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try dataSource.value(key: key.stringValue) }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try dataSource.value(key: key.stringValue) }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try dataSource.value(key: key.stringValue) }
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable { try dataSource.value(key: key.stringValue) }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey { fatalError() }
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer { fatalError() }
    func superDecoder() throws -> Decoder { fatalError() }
    func superDecoder(forKey key: Key) throws -> Decoder { fatalError() }
}
