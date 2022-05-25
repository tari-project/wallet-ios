//  TransportType.swift

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

enum TransportTypeError: Error {
    case generic(_ errorCode: Int32)
}

class TransportConfig {
    private var ptr: OpaquePointer

    var pointer: OpaquePointer {
        return ptr
    }

    var address: (String, Error?) {
        var errorCode: Int32 = -1
        let resultPtr = withUnsafeMutablePointer(to: &errorCode, { error in
            transport_memory_get_address(ptr, error)})
        let result = String(cString: resultPtr!)
        return (result, errorCode != 0 ? ByteVectorError.generic(errorCode) : nil )
    }

    init() {
        let result = transport_memory_create()
        ptr = result!
    }

    init(listenerAddress: String) throws {
        var errorCode: Int32 = -1
        let result = listenerAddress.withCString({ chars in
            withUnsafeMutablePointer(to: &errorCode, { error in
            transport_tcp_create(chars, error)})
        })
        guard errorCode == 0 else {
            throw TransportTypeError.generic(errorCode)
        }
        ptr = result!
    }

    init(
        controlServerAddress: String,
        torPort: Int,
        torCookie: ByteVector,
        socksUsername: String = "",
        socksPassword: String = ""
    ) throws {
        var errorCode: Int32 = -1

        let result = controlServerAddress.withCString({control in
            socksUsername.withCString({ user in
                socksPassword.withCString({ pass in
                    withUnsafeMutablePointer(to: &errorCode, { error in
                        transport_tor_create(
                            controlServerAddress.count > 0 ? control : nil,
                            torCookie.pointer,
                            UInt16(torPort),
                            false,
                            socksUsername.count > 0 ? user : nil,
                            socksPassword.count > 0 ? pass : nil,
                            error
                        )
                    })
                })
            })
        })
        guard errorCode == 0 else {
            throw TransportTypeError.generic(errorCode)
        }
        ptr = result!
    }

    init (pointer: OpaquePointer) {
        ptr = pointer
    }

    deinit {
        transport_type_destroy(ptr)
    }
}
