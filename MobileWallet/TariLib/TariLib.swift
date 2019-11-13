//  TariLib.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/12
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

class TariLib {
    static let wallet = TariLib()
    private var databasePath: String?

    var walletExists: Bool {
        get {
            return true //TODO check for wallet db possibly
        }
    }

    init() {
        let dbName = "db1"
        let fileManager = FileManager.default
        let documentsURL =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        databasePath = documentsURL.appendingPathComponent(dbName).path

        do {
            try FileManager.default.createDirectory(atPath: databasePath!, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }

        print(databasePath!)

//        let alice_hex = "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"
//        let alice_hex_ptr = UnsafeMutablePointer<Int8>(mutating: (alice_hex))
//        let alice_key = private_key_from_hex(alice_hex_ptr)//private_key_generate()
//
//        let alice_path_ptr = UnsafeMutablePointer<Int8>(mutating: databasePath)

//        let alice_address = "172.30.30.74:80"
//        let alice_address_ptr = UnsafeMutablePointer<Int8>(mutating: (alice_address as NSString).utf8String)
//        let alice_database_ptr = UnsafeMutablePointer<Int8>(mutating: (dbName as NSString).utf8String)
//        let alice_config = comms_config_create(alice_address_ptr, alice_database_ptr, alice_path_ptr, alice_key)
//        print("Alice: Created config ")
//        let alice_wallet = wallet_create(alice_config)
    }

    /*
     Called automatically, just before instance deallocation takes place
     */
    deinit {
        //Destroy wallet
    }

    func createNewWallet() {
        print("New Wallet")
    }
}
