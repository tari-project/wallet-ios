//  CommsConfig.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/15
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

enum CommsConfigError: Error {
    case generic(_ errorCode: Int32)
}

class CommsConfig {
    private var ptr: OpaquePointer

    var pointer: OpaquePointer {
        return ptr
    }

    var dbPath: String
    var dbName: String

    init(transport: TransportType, databaseFolderPath: String, databaseName: String, publicAddress: String, discoveryTimeoutSec: UInt64, safMessageDurationSec: UInt64) throws {
        dbPath = databaseFolderPath
        dbName = databaseName
        var errorCode: Int32 = -1
        let result = databaseName.withCString({ db in
            databaseFolderPath.withCString({ path in
                publicAddress.withCString({ address in
                     withUnsafeMutablePointer(to: &errorCode, { error in
                        comms_config_create(
                            address,
                            transport.pointer,
                            db,
                            path,
                            discoveryTimeoutSec,
                            safMessageDurationSec,
                            error
                        )
                    })
                })
            })
        })
    ptr = result!
    guard errorCode == 0 else {
         throw CommsConfigError.generic(errorCode)
        }
    }

    func setPrivateKey(_ privateKey: PrivateKey) throws {
        var errorCode: Int32 = -1
        withUnsafeMutablePointer(to: &errorCode, { error in
            comms_config_set_secret_key(pointer, privateKey.pointer, error)
        })
        guard errorCode == 0 else {
            throw CommsConfigError.generic(errorCode)
        }
    }

    deinit {
        comms_config_destroy(ptr)
    }
}
