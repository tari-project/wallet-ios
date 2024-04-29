//  Data+Utlis.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 20/06/2023
	Using Swift 5.0
	Running on macOS 13.4

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

extension Data {

    enum BLEChunkType {
        case normal
        case last
    }

    var isBLEChunk: Bool { bleChunkType != nil }

    var bleChunkType: BLEChunkType? {
        switch last {
        case 0:
            return .last
        case 1:
            return .normal
        default:
            return nil
        }
    }

    var bleDataChunks: [Data] {
        let rawChunks = split(chunkSize: BLEConstants.chunkSize)
        return rawChunks
            .enumerated()
            .map {
                let controlByte: UInt8 = $0 == rawChunks.count - 1 ? 0 : 1
                return $1.appending(byte: controlByte)
            }
    }

    func split(chunkSize: Int) -> [Data] {

        let lastIndex = count
        var index = 0
        var result: [Data] = []

        repeat {
            let nextIndex = Swift.min(index + chunkSize, lastIndex)
            result.append(subdata(in: index..<nextIndex))
            index = nextIndex
        } while index != lastIndex

        return result
    }

    func appending(byte: UInt8) -> Data {
        var data = self
        data.append(contentsOf: [byte])
        return data
    }

    func value<T: Any>(type: T.Type, byteCount: Int) -> T? {
        guard byteCount == count else { return nil }
        return withUnsafeBytes { $0.load(as: T.self) }
    }
}

extension Array where Element == Data {

    var dataFromBLEChunks: Data? {
        guard first(where: { !$0.isBLEChunk }) == nil else { return nil }
        return map { $0.dropLast() }
            .reduce(into: Data()) { $0.append($1) }
    }

    var stringFromBLEChunks: String? {
        guard let dataFromBLEChunks else { return nil }
        return String(data: dataFromBLEChunks, encoding: .utf8)
    }
}
