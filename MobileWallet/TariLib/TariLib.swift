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
    static let shared = TariLib()

    private static let DATABASE_NAME = "tari_wallet"

    private let fileManager = FileManager.default

    private var tariWallet: Wallet?

    var databasePath: String {
        get {
            let documentsURL =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsURL.appendingPathComponent(TariLib.DATABASE_NAME).path
        }
    }

    var walletExists: Bool {
        get {
            //TODO check for actual keys, not just the wallet directory
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: databasePath, isDirectory: &isDir) {
                return true
            }

            return false
        }
    }

    init() {}

    /*
     Called automatically, just before instance deallocation takes place
     */
    deinit {}

    func createNewWallet() {
        do {
            try fileManager.createDirectory(atPath: databasePath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }

        print(databasePath)

        let address = "0.0.0.0:80"
        let hex_str = "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"
        let privateKey = PrivateKey(hex: hex_str)

        let comsConfig = CommsConfig(privateKey: privateKey, databasePath: databasePath, databaseName: TariLib.DATABASE_NAME, address: address)

        tariWallet = Wallet(config: comsConfig.pointer())
    }
}
