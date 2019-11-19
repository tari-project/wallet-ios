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
    //Use a random DB path for each test
    private var dbName: String {        
        return "test_db_\(UUID().uuidString)"
    }
    
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
        //Init manually. Initializing from pointers happens in priv/pub key tests.
        let byteVector = ByteVector(byteArray: [0, 1, 2, 3, 4, 5])
        XCTAssertEqual(byteVector.hexString, "000102030405")
    }
    
    func testPrivateKey() {
        //Create priv key from hex, then create hex from that to test ByteVector toString()
        let originalPrivateKeyHex = "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"
        
        let privateKey = PrivateKey(hex: originalPrivateKeyHex)
        XCTAssertEqual(privateKey.hex, originalPrivateKeyHex)
                
        XCTAssertEqual(PrivateKey.validHex("I_made_this_up"), false)
        XCTAssertEqual(PrivateKey.validHex(originalPrivateKeyHex), true)
    }
    
    func testPublicKey() {
        //Create pub key from hex, then create hex from that to test ByteVector toString()
        let originalPublicKeyHex = "6a493210f7499cd17fecb510ae0cea23a110e8d5b901f8acadd3095c73a3b919"
        
        let publicKey = PublicKey(hex: originalPublicKeyHex)
        XCTAssertEqual(publicKey.hex, originalPublicKeyHex)
        
        XCTAssertEqual(PublicKey.validHex("I_made_this_up"), false)
        XCTAssertEqual(PublicKey.validHex(originalPublicKeyHex), true)
    }
    
    func testWallet() {
        let privateKeyHex = "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"

        let comsConfig = CommsConfig(
            privateKey: PrivateKey(hex: privateKeyHex),
            databasePath: databasePath,
            databaseName: dbName,
            address: "0.0.0.0:80"
        )

        //MARK: Create new wallet
        let wallet = Wallet(comsConfig: comsConfig)
        XCTAssertEqual(wallet.publicKey.hex, "30e1dfa197794858bfdbf96cdce5dc8637d4bd1202dc694991040ddecbf42d40")
        
        //MARK: Add bob as a contact
        let bobPublicKeyHex = "6a493210f7499cd17fecb510ae0cea23a110e8d5b901f8acadd3095c73a3b919"
        let bobAlias = "BillyBob"
        
        do {
            try wallet.addContact(alias: bobAlias, publicKeyHex: bobPublicKeyHex)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertEqual(wallet.contacts.count, 1)
                
        do {
            let justAddedContact = try wallet.contacts.at(position: 0)
            let alias = justAddedContact.alias
            XCTAssertEqual(alias, bobAlias)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertEqual(wallet.completedTransactions.count, 0)
        XCTAssertEqual(wallet.pendingOutboundTransactions.count, 0)
        XCTAssertEqual(wallet.pendingInboundTransactions.count, 0)
        XCTAssertEqual(wallet.availableBalance, 0)
        XCTAssertEqual(wallet.pendingIncomingBalance, 0)
        XCTAssertEqual(wallet.pendingOutgoingBalance, 0)
        
        //MARK: Receive a transaction
        
        do {
            try wallet.generateTestReceiveTransaction()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertEqual(wallet.completedTransactions.count, 0)
        XCTAssertEqual(wallet.pendingOutboundTransactions.count, 0)
        XCTAssertEqual(wallet.pendingInboundTransactions.count, 1)
        XCTAssertEqual(wallet.availableBalance, 0)
        XCTAssertGreaterThan(wallet.pendingIncomingBalance, 0)
        XCTAssertEqual(wallet.pendingOutgoingBalance, 0)
        
        //MARK: Confirm received transaction
        do {
            let pendingInboundTransaction = try wallet.pendingInboundTransactions.at(position: 0)

            try wallet.testTransactionBroadcast(pendingInboundTransaction: pendingInboundTransaction)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        XCTAssertEqual(wallet.completedTransactions.count, 1)
        XCTAssertEqual(wallet.pendingOutboundTransactions.count, 0)
        XCTAssertEqual(wallet.pendingInboundTransactions.count, 0)
        
//        XCTAssertGreaterThan(wallet.availableBalance, 0)
//        XCTAssertEqual(wallet.pendingIncomingBalance, 0)
//        XCTAssertEqual(wallet.pendingOutgoingBalance, 0)
     
        //TODO create send tx
        //TODO assert wallet.pendingOutgoingBalance
        
        //TODO confirm send tx
        //TODO assert wallet.availableBalance
    }
}
