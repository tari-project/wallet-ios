//  DeeplinkDataDecoder.swift

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

import Foundation

struct DeepLinkDataDecoder {

    private var parameters: [String: String] = [:]

    init(deeplink: URL) {
        parameters = deeplink.queryParameters
    }
}

extension DeepLinkDataDecoder: Decoder {

    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(DeepLinkDataContainter(parameters: parameters))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer { fatalError() }
    func singleValueContainer() throws -> SingleValueDecodingContainer { fatalError() }
}

private struct DeepLinkDataContainter<Key: CodingKey>: KeyedDecodingContainerProtocol {

    let codingPath: [CodingKey] = []
    var allKeys: [Key] { parameters.keys.compactMap { Key(stringValue: $0) }}

    let parameters: [String: String]

    func contains(_ key: Key) -> Bool { parameters.keys.contains(key.stringValue) }
    func decodeNil(forKey key: Key) throws -> Bool { false }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let rawValue = parameters[key.stringValue], let value = Bool(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let value = parameters[key.stringValue] else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let rawValue = parameters[key.stringValue], let value = Double(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let rawValue = parameters[key.stringValue], let value = Float(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let rawValue = parameters[key.stringValue], let value = Int(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        guard let rawValue = parameters[key.stringValue], let value = Int8(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        guard let rawValue = parameters[key.stringValue], let value = Int16(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let rawValue = parameters[key.stringValue], let value = Int32(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        guard let rawValue = parameters[key.stringValue], let value = Int64(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let rawValue = parameters[key.stringValue], let value = UInt(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        guard let rawValue = parameters[key.stringValue], let value = UInt8(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        guard let rawValue = parameters[key.stringValue], let value = UInt16(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        guard let rawValue = parameters[key.stringValue], let value = UInt32(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        guard let rawValue = parameters[key.stringValue], let value = UInt64(rawValue) else { throw DeepLinkError.unableToParse(key: key.stringValue) }
        return value
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable { fatalError() }
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey { fatalError() }
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer { fatalError() }
    func superDecoder() throws -> Decoder { fatalError() }
    func superDecoder(forKey key: Key) throws -> Decoder { fatalError() }
}
