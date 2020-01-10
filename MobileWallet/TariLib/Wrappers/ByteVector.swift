//  ByteVector.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/14
	Using Swift 5.0
	Running on macOS 10.15

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

enum ByteVectorError: Error {
    case generic(_ errorCode: Int32)
}

class ByteVector {
    private var ptr: OpaquePointer

    var pointer: OpaquePointer {
        return ptr
    }

    var count: (UInt32, Error?) {
        var errorCode: Int32 = -1
        let result = byte_vector_get_length(ptr, UnsafeMutablePointer<Int32>(&errorCode))
        return (result, errorCode != 0 ? ByteVectorError.generic(errorCode) : nil )
    }

    var hexString: (String, Error?) {
        var byteArray: [UInt8] = [UInt8]()

        let (byteArrayLength, error) = self.count

        if error != nil {
            return ("", error)
        }

        for n in 0...byteArrayLength - 1 {
            do {
                let byte = try self.at(position: n)
                byteArray.append(byte)
            } catch {
                return ("", error)
            }
        }

        let data = Data(byteArray)

        return (data.map {String(format: "%02hhx", $0)}.joined(), nil)
    }

    init(byteArray: [UInt8]) throws {
        var errorCode: Int32 = -1
        let result = byte_vector_create(byteArray, UInt32(byteArray.count), UnsafeMutablePointer<Int32>(&errorCode))
        guard (errorCode == 0) else {
            throw ByteVectorError.generic(errorCode)
        }

        ptr = result!
    }

    init (pointer: OpaquePointer) {
        ptr = pointer
    }

    func at(position: UInt32) throws -> (UInt8) {
        var errorCode: Int32 = -1
        let result = byte_vector_get_at(ptr, position, UnsafeMutablePointer<Int32>(&errorCode))

        guard errorCode == 0 else {
            throw ByteVectorError.generic(errorCode)
        }

        return result
    }

    deinit {
        byte_vector_destroy(ptr)
    }
}
