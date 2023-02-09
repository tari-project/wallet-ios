//  DeepLinkDataEncoder.swift

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

struct DeepLinkDataEncoder: Encoder {

    fileprivate class InternalData {
        var query: String = ""
    }

    var codingPath: [CodingKey] =  []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var query: String { internalData.query }

    private let internalData = InternalData()

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(DeepLinkDataEncoderContainter(internalData: internalData))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer { fatalError() }
    func singleValueContainer() -> SingleValueEncodingContainer { fatalError() }
}

private struct DeepLinkDataEncoderContainter<Key: CodingKey> {
    var codingPath: [CodingKey] = []
    var internalData: DeepLinkDataEncoder.InternalData
}

extension DeepLinkDataEncoderContainter: KeyedEncodingContainerProtocol {

    mutating func encodeNil(forKey key: Key) throws {}

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        add(key: key, value: value)
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable { fatalError() }
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey { fatalError() }
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer { fatalError() }
    mutating func superEncoder() -> Encoder { fatalError() }
    mutating func superEncoder(forKey key: Key) -> Encoder { fatalError() }

    private func add(key: Key, value: Any) {

        let element = [key.stringValue, "\(value)"].joined(separator: "=")

        guard !internalData.query.isEmpty else {
            internalData.query = element
            return
        }

        internalData.query = [internalData.query, element].joined(separator: "&")
    }
}
