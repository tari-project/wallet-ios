//  DeepLinkUnkeyedEncodingContainer.swift

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

struct DeepLinkUnkeyedEncodingContainer: UnkeyedEncodingContainer {

    private let storage: DeepLinkEncoderStorage

    var codingPath: [CodingKey] = []
    var count: Int = 0

    var key: String { "\(count)" }

    init(storage: DeepLinkEncoderStorage) {
        self.storage = storage
    }

    mutating func encodeNil() throws { }

    mutating func encode(_ value: Bool) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: String) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: Double) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: Float) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: Int) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: Int8) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: Int16) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: Int32) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: Int64) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: UInt) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: UInt8) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: UInt16) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: UInt32) throws { storage.add(key: key, value: value) }
    mutating func encode(_ value: UInt64) throws { storage.add(key: key, value: value) }

    mutating func encode<T: Encodable>(_ value: T) throws {

        var keys = storage.keysHierarchy
        keys.append("\(count)")

        let encoder = DeepLinkEncoder(keysHierarchy: keys)
        try value.encode(to: encoder)
        let value = encoder.result
        storage.add(subquery: value)
        count += 1
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey { fatalError() }
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { fatalError() }
    mutating func superEncoder() -> Encoder { fatalError() }
}
