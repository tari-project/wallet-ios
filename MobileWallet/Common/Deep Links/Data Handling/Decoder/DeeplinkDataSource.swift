//  DeeplinkDataSource.swift

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

struct DeeplinkDataSource {

    let parameters: [String: Any]

    func value<ValueType: Decodable>(key: String) throws -> ValueType {

        if let rawValue = parameters[key] as? String {
            guard let value: ValueType = value(rawValue: rawValue) else { throw DeepLinkError.unableToParse(key: key) }
            return value
        }

        guard let subParameters = parameters[key] as? [String: Any] else { throw DeepLinkError.unableToParse(key: key) }
        let decoder = DeepLinkDecoder(parameters: subParameters)
        return try ValueType(from: decoder)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func value<ValueType>(rawValue: String) -> ValueType? {
        switch ValueType.self {
        case is Bool.Type:
            return Bool(rawValue) as? ValueType
        case is String.Type:
            return rawValue as? ValueType
        case is Double.Type:
            return Double(rawValue) as? ValueType
        case is Float.Type:
            return Float(rawValue) as? ValueType
        case is Int.Type:
            return Int(rawValue) as? ValueType
        case is Int8.Type:
            return Int8(rawValue) as? ValueType
        case is Int16.Type:
            return Int16(rawValue) as? ValueType
        case is Int32.Type:
            return Int32(rawValue) as? ValueType
        case is Int64.Type:
            return Int64(rawValue) as? ValueType
        case is UInt.Type:
            return UInt(rawValue) as? ValueType
        case is UInt8.Type:
            return UInt8(rawValue) as? ValueType
        case is UInt16.Type:
            return UInt16(rawValue) as? ValueType
        case is UInt32.Type:
            return UInt32(rawValue) as? ValueType
        case is UInt64.Type:
            return UInt64(rawValue) as? ValueType
        default:
            fatalError()
        }
    }
}
