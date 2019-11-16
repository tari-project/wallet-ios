//  TariLib.swift
	
/*
	Package MobileWalletTests
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

import XCTest

class TariLibWrapperTests: XCTestCase {
    private let dbName = "test_db"
    
    var databasePath: String {
        get {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsURL.appendingPathComponent(dbName).path
        }
    }
    
    override func setUp() {
    }

    override func tearDown() {
    }

    func testByteVector() {
        //Init manually
        let byteVector = ByteVector(byte_array: [0, 1, 2, 3, 4, 5])
        
        XCTAssertEqual(byteVector.length(), 6)
        XCTAssertEqual(byteVector.at(position: 2), 2)
        
        //init from using `private_key_get_bytes(ptr)` happens in testPrivateKey()
    }
    
    func testPrivateKey() {
        let privateKey = PrivateKey(hex: "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801")
        let byteVector = privateKey.getBytes()
        
        XCTAssertEqual(byteVector.length(), 32)
        XCTAssertEqual(byteVector.at(position: 5), 226)
    }
    
    func testCommsConfig() {
        let _ = CommsConfig(
            privateKey: PrivateKey(hex: "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"),
            databasePath: databasePath,
            databaseName: dbName,
            address: "0.0.0.0:80")
        
        let _ = CommsConfig(
        privateKey: PrivateKey(hex: "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"),
        databasePath: databasePath,
        databaseName: dbName,
        address: "0.0.0.0:80")
        
        //Nothing to assert yet
    }
    
    func testWallet() {
        let address = "0.0.0.0:80"
        let hex_str = "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"

        let comsConfig = CommsConfig(
            privateKey: PrivateKey(hex: hex_str),
            databasePath: databasePath,
            databaseName: dbName,
            address: address
        )

        let wallet = Wallet(config: comsConfig.pointer())
        
        //If test data can be generated deterministically they wallet tests could cover more than just checking empty states
        //wallet.generateTestData()
        
        XCTAssertEqual(wallet.getAvailableBalance(), 0)
        XCTAssertEqual(wallet.getPendingIncomingBalance(), 0)
        XCTAssertEqual(wallet.getPendingOutgoingBalance(), 0)
    }
}
