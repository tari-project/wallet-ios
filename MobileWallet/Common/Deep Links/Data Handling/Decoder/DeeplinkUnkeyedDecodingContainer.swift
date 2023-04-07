//  DeeplinkUnkeyedDecodingContainer.swift

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

struct DeeplinkUnkeyedDecodingContainer: UnkeyedDecodingContainer {

    var codingPath: [CodingKey] = []
    var count: Int? { dataSource.parameters.count }
    var isAtEnd: Bool { count == currentIndex }
    var currentIndex: Int = 0

    private let dataSource: DeeplinkDataSource
    private var key: String { "\(currentIndex)" }

    init(parameters: [String: Any]) {
        dataSource = DeeplinkDataSource(parameters: parameters)
    }

    mutating func decodeNil() throws -> Bool { false }

    mutating func decode(_ type: Bool.Type) throws -> Bool { try nextValue() }
    mutating func decode(_ type: String.Type) throws -> String { try nextValue() }
    mutating func decode(_ type: Double.Type) throws -> Double { try nextValue() }
    mutating func decode(_ type: Float.Type) throws -> Float { try nextValue() }
    mutating func decode(_ type: Int.Type) throws -> Int { try nextValue() }
    mutating func decode(_ type: Int8.Type) throws -> Int8 { try nextValue() }
    mutating func decode(_ type: Int16.Type) throws -> Int16 { try nextValue() }
    mutating func decode(_ type: Int32.Type) throws -> Int32 { try nextValue() }
    mutating func decode(_ type: Int64.Type) throws -> Int64 { try nextValue() }
    mutating func decode(_ type: UInt.Type) throws -> UInt { try nextValue() }
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 { try nextValue() }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { try nextValue() }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { try nextValue() }
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { try nextValue() }
    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable { try nextValue() }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey { fatalError() }
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer { fatalError() }
    mutating func superDecoder() throws -> Decoder { fatalError() }

    private mutating func nextValue<Value: Decodable>() throws -> Value {
        let value: Value = try dataSource.value(key: key)
        currentIndex += 1
        return value
    }
}
