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
    private var dbName = "test_db"
        
    private var newTestStoragePath: String {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_\(UUID().uuidString)").path
    }
    
    private func databaseTestPath(_ storagePath: String) -> String {
        return "\(storagePath)/\(dbName)"
    }
    
    private func loggingTestPath(_ storagePath: String) -> String {
        return "\(storagePath)/log.txt"
    }

    override func setUp() {
    }

    override func tearDown() {
    }

    func testByteVector() {
        //Init manually. Initializing from pointers happens in priv/pub key tests.
        do {
            let byteVector = try ByteVector(byteArray: [0, 1, 2, 3, 4, 5])
            
            let (hexString, hexError) = byteVector.hexString
            if hexError != nil {
                XCTFail(hexError!.localizedDescription)
            }
            
            XCTAssertEqual(hexString, "000102030405")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPrivateKey() {
        //Create priv key from hex, then create hex from that to test ByteVector toString()
        let originalPrivateKeyHex = "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"
        
        do {
            let privateKey = try PrivateKey(hex: originalPrivateKeyHex)
            let (hex, hexError) = privateKey.hex
            if hexError != nil {
                XCTFail(hexError!.localizedDescription)
            }
            
            XCTAssertEqual(hex, originalPrivateKeyHex)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPublicKey() {
        //Create pub key from hex, then create hex from that to test ByteVector toString()
        let originalPublicKeyHex = "6a493210f7499cd17fecb510ae0cea23a110e8d5b901f8acadd3095c73a3b919"
        
        do {
            _ = try PublicKey(privateKey: PrivateKey())
            
            let publicKey = try PublicKey(hex: originalPublicKeyHex)
            let (hex, hexError) = publicKey.hex
            if hexError != nil {
                XCTFail(hexError!.localizedDescription)
            }
            XCTAssertEqual(hex, originalPublicKeyHex)
            let (emojis, error) = publicKey.emojis
            if error != nil {
                XCTFail(error!.localizedDescription)
            }
            
            let emojiKey = try PublicKey(emojis: emojis)
            XCTAssertEqual(emojiKey.hex.0, publicKey.hex.0)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        //Valid emoji ID
        XCTAssertNoThrow(try PublicKey(emojis: "🐒🐑🍔🔧❌👂🦒💇🔋💥🍷🍺👔😷🐶🧢🤩💥🎾🎲🏀🤠💪👮🤯🎁💉🌞🍉🤷🍦👽🔈"))
        
        //Valid emoji ID
        XCTAssertNoThrow(try PublicKey(emojis: "😷💍💎🐍🤩💺🚔💊🧗🤤😉⛅🐶✋🧦🧜🤠🧤💻🌸📌👸🥁🍇🏀🎲😵💇❓⛵💊🦋🎸"))
        
        //Invalid emoji ID
        XCTAssertThrowsError(try PublicKey(emojis: "🐒🐑🍔🔧❌👂🦒💇🔋💥🍷🍺👔😷🐶🧢🤩💥🎾🎲🏀🤠💪👮🤯🎁💉🌞🍉🤷🍦👽👽"))
        
        //Valid deep links
        XCTAssertNoThrow(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/eid/🐒🐑🍔🔧❌👂🦒💇🔋💥🍷🍺👔😷🐶🧢🤩💥🎾🎲🏀🤠💪👮🤯🎁💉🌞🍉🤷🍦👽🔈"))
        XCTAssertNoThrow(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/pubkey/70350e09c474809209824c6e6888707b7dd09959aa227343b5106382b856f73a"))
        //Derive a deep link from random pubkey, then init a pubkey using that deep link
        XCTAssertNoThrow(try PublicKey(deeplink: PublicKey(privateKey: PrivateKey()).emojiDeeplink.0))
        XCTAssertNoThrow(try PublicKey(deeplink: PublicKey(privateKey: PrivateKey()).hexDeeplink.0))

        //Invalid deep links
        XCTAssertThrowsError(try PublicKey(deeplink: "bla bla bla"))
        XCTAssertThrowsError(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/eid/🖖🥴😍🙃💦🤘🤜👁🙃🙌😱"))
        XCTAssertThrowsError(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/pubkey/invalid"))
        XCTAssertThrowsError(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://made-up-net/pubkey/70350e09c474809209824c6e6888707b7dd09959aa227343b5106382b856f73a"))
        
        //Convenience init
        XCTAssertThrowsError(try PublicKey(any: "bla"))
        XCTAssertThrowsError(try PublicKey(any: "Hey use this emoji ID 🐒🐑🍔🔧❌👂🦒"))
        XCTAssertNoThrow(try PublicKey(any: "🐒🐑🍔 | 🔧❌👂 | 🦒💇🔋 | 💥🍷🍺 | 👔😷🐶 | 🧢🤩💥 | 🎾🎲🏀 | 🤠💪👮 | 🤯🎁💉 | 🌞🍉🤷 | 🍦👽🔈"))
        XCTAssertNoThrow(try PublicKey(any: "copy this: 🐒🐑🍔🔧❌👂🦒💇🔋💥🍷🍺👔😷🐶🧢🤩💥🎾🎲🏀🤠💪👮🤯🎁💉🌞🍉🤷🍦👽🔈 please"))
        XCTAssertNoThrow(try PublicKey(any: "My emojis are \"🐒🐑🍔🔧❌👂🦒💇🔋💥🍷🍺👔😷🐶🧢🤩💥🎾🎲🏀🤠💪👮🤯🎁💉🌞🍉🤷🍦👽🔈\""))
        XCTAssertNoThrow(try PublicKey(any: "🐒🐑🍔🔧❌👂🦒💇🔋💥🍷🍺👔😷🐶🧢🤩 bla bla bla 💥🎾🎲🏀🤠💪👮🤯🎁💉🌞🍉🤷🍦👽🔈"))
        XCTAssertNoThrow(try PublicKey(any: "My emojis 🐒🐑🍔🔧❌👂🦒💇🔋💥🍷🍺👔😷🐶 and here are the rest 🧢🤩💥🎾🎲🏀🤠💪👮🤯🎁💉🌞🍉🤷🍦👽🔈"))
    }
    
    func testBaseNode() {
        //Invalid peers
        XCTAssertThrowsError(try BaseNode("bla bla bla"))
        XCTAssertThrowsError(try BaseNode("5edb022af1c21d644dfceeea2fcc7d3fac7a57ab44cf775b9a6f692cb75ed767::/onion3/vjkj44zpriqzrlve2qbiasrluaaxagrb6iuavzaascbujri6gw3rcmyd"))
        XCTAssertThrowsError(try BaseNode("5edb022af1c21d644dfceeea2fcc7d3fac7a57ab44cf775b9a6f692cb75ed767::vjkj44zpriqzrlve2qbiasrluaaxagrb6iuavzaascbujri6gw3rcmyd:18141"))

        //Valid peer
        XCTAssertNoThrow(try BaseNode("2e93c460df49d8cfbbf7a06dd9004c25a84f92584f7d0ac5e30bd8e0beee9a43::/onion3/nuuq3e2olck22rudimovhmrdwkmjncxvwdgbvfxhz6myzcnx2j4rssyd:18141"))
    }
   
    func testWallet() {
        //MARK: Create new wallet
        var w: Wallet?
        
        let fileManager = FileManager.default
        let storagePath = newTestStoragePath
        let databasePath = databaseTestPath(storagePath)
        let loggingFilePath = loggingTestPath(storagePath)
        
        do {
            try fileManager.createDirectory(atPath: storagePath, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(atPath: databasePath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Unable to create directory \(error.localizedDescription)")
        }
        
        let privateKeyHex = "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"
        
        var commsConfig: CommsConfig?
        do {
            let transport = TransportType()
            let address = transport.address.0
            commsConfig = try CommsConfig(
                privateKey: PrivateKey(hex: privateKeyHex),
                transport: transport,
                databasePath: databasePath,
                databaseName: dbName,
                publicAddress: address,
                discoveryTimeoutSec: TariSettings.shared.discoveryTimeoutSec
            )
            
            TariLogger.verbose("TariLib Logging path: \(loggingFilePath)")
        } catch {
            XCTFail("Unable to create comms config \(error.localizedDescription)")
            return
        }
        
        do {
            w = try Wallet(commsConfig: commsConfig!, loggingFilePath: loggingFilePath)
        } catch {
            XCTFail("Unable to create wallet \(error.localizedDescription)")
            return
        }
        
        guard let wallet = w else {
            XCTFail("Wallet not initialized")
            return
        }
        
        let testWalletPublicKey = "30e1dfa197794858bfdbf96cdce5dc8637d4bd1202dc694991040ddecbf42d40"
        
        let (walletPublicKey, pubKeyError) = wallet.publicKey
        if pubKeyError != nil {
            XCTFail(pubKeyError!.localizedDescription)
        }
        
        let (walletPublicKeyHex, walletPublicKeyHexError) = walletPublicKey!.hex
        if walletPublicKeyHexError != nil {
            XCTFail(walletPublicKeyHexError!.localizedDescription)
        }
        
        XCTAssertEqual(walletPublicKeyHex, testWalletPublicKey)
        
        // check wallet can sign a message and then verify the signature of the message it signed
        let msg = "Hello"
        let signature = try! wallet.signMessage(msg);
        
        do {
            let verification = try signature.isValid(wallet: wallet)
            if verification != true {
                XCTFail("Verification of message failed")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        
        //MARK: Test data
        do {
            try wallet.generateTestData()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        //MARK: Remove Alice contact
        let (contacts, contactsError) = wallet.contacts
        if contactsError != nil {
            XCTFail(contactsError!.localizedDescription)
        }
        
        do {
            let aliceContact = try contacts!.at(position: 0)
            try wallet.removeContact(aliceContact)
        }  catch {
            XCTFail(error.localizedDescription)
        }
                
        
        //MARK: Add Alice contact
        do {
            try wallet.addUpdateContact(alias: "BillyBob", publicKeyHex: "a03d9be195e40466e255bd64eb612ad41ae0010519b6cbfc7698e5d0916a1a7c")
        } catch {
            XCTFail("Failed to add contact \(error.localizedDescription)")
        }

        //MARK: Receive a test transaction
        do {
            try wallet.generateTestReceiveTransaction()
        } catch {
            XCTFail(error.localizedDescription)
        }

        //MARK: Finalize and broadcast received test transaction
        var txId: UInt64?
        do {
            let (pendingInboundTransactions, pendingInboundTransactionsError) = wallet.pendingInboundTransactions
            if pendingInboundTransactionsError != nil {
                XCTFail(pendingInboundTransactionsError!.localizedDescription)
            }
            
            let (pendingInboundTransactionsCount, pendingInboundTransactionsCountError) = pendingInboundTransactions!.count
            if pendingInboundTransactionsCountError != nil {
                XCTFail(pendingInboundTransactionsCountError!.localizedDescription)
            }
            
            var currTx = 0
            txId = 0
            var pendingInboundTransaction: PendingInboundTransaction? = nil
            while ( currTx < pendingInboundTransactionsCount)
            {
                pendingInboundTransaction = try pendingInboundTransactions!.at(position: UInt32(currTx))
                let (pendingInboundTransactionId, pendingInboundTransactionIdError) = pendingInboundTransaction!.id
                if pendingInboundTransactionIdError != nil {
                    XCTFail(pendingInboundTransactionIdError!.localizedDescription)
                }
                txId = pendingInboundTransactionId
                let (pendingInboundTransactionStatus, _) = pendingInboundTransaction!.status
                if pendingInboundTransactionStatus == TransactionStatus.pending
                {
                    break;
                }
                currTx += 1
            }
            
            try wallet.testFinalizedReceivedTransaction(pendingInboundTransaction: pendingInboundTransaction!)
            try wallet.testTransactionBroadcast(txID: txId!)
            try wallet.testTransactionMined(txID: txId!)
            let completedTx = try wallet.findCompletedTransactionBy(id: txId!)
            let (status, statusError) = completedTx.status
            if statusError != nil {
                XCTFail(statusError!.localizedDescription)
            }
        
            XCTAssertEqual(status, .mined)
        } catch {
            XCTFail(error.localizedDescription)
        }

        //MARK: Send transaction to bob
        var sendTransactionId: UInt64?
        do {
            let (contacts, contactsError) = wallet.contacts
            if contactsError != nil {
                XCTFail(contactsError!.localizedDescription)
            }
            
            let bob = try contacts!.at(position: 0)
            let (bobPublicKey, bobPublicKeyError) = bob.publicKey
            if bobPublicKeyError != nil {
                XCTFail(bobPublicKeyError!.localizedDescription)
            }
            
            try wallet.sendTransaction(destination: bobPublicKey!, amount: MicroTari(1000), fee: MicroTari(101), message: "Oh hi bob")
            let (pendingOutboundTransactions, pendingOutboundTransactionsError) = wallet.pendingOutboundTransactions
            if pendingOutboundTransactionsError != nil {
                XCTFail(pendingOutboundTransactionsError!.localizedDescription)
            }
            
            let pendingOutboundTransaction = try pendingOutboundTransactions!.at(position: 0)
            let (pendingOutboundTransactionId, pendingOutboundTransactionIdError) = pendingOutboundTransaction.id
            if pendingOutboundTransactionIdError != nil {
                XCTFail(pendingOutboundTransactionIdError!.localizedDescription)
            }
            
            sendTransactionId = pendingOutboundTransactionId
        } catch {
            XCTFail(error.localizedDescription)
        }

        //MARK: Complete sent transaction to bob
        do {
            let pendingOutboundTransaction = try wallet.findPendingOutboundTransactionBy(id: sendTransactionId!)

            try wallet.testCompleteSend(pendingOutboundTransaction: pendingOutboundTransaction!)

            try wallet.testTransactionMined(txID: sendTransactionId!)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let (availableBalance, _) = wallet.availableBalance
        let (pendingIncomingBalance, _) = wallet.pendingIncomingBalance
        let (pendingOutgoingBalance, _) = wallet.pendingOutgoingBalance
        
        XCTAssertGreaterThan(availableBalance, 0)
        XCTAssertGreaterThan(pendingIncomingBalance, 0)
        XCTAssertGreaterThan(pendingOutgoingBalance, 0)
        
        let (completedTransactions, completedTransactionsError) = wallet.completedTransactions
        guard completedTransactionsError == nil else {
            TariLogger.error("Failed to load transactions", error: completedTransactionsError)
            return
        }
        
        let (groupedTransactions, groupedTransactionsError) = completedTransactions!.groupedByDate
        guard groupedTransactionsError == nil else {
            XCTFail("Failed to load grouped transactions: /(groupedTransactionsError!.localizedDescription)")
            return
        }
                    
        XCTAssertGreaterThan(groupedTransactions.count, 0)
        XCTAssertGreaterThan(groupedTransactions[0].count, 1)
    }
    
    func testMicroTari() {
        let microTari = MicroTari(98234567)
        XCTAssert(microTari.taris == 98.234567)
        //Check 2 most common local formats
        XCTAssert(microTari.formatted == "98.23" || microTari.formatted == "98,23")
        XCTAssert(microTari.formattedWithOperator == "+ 98.23" || microTari.formattedWithOperator == "+ 98,23")
        XCTAssert(microTari.formattedWithNegativeOperator == "- 98.23" || microTari.formattedWithNegativeOperator == "- 98,23")
        XCTAssert(microTari.formattedPrecise == "98.2345657" || microTari.formattedPrecise == "98,2345657")
        XCTAssert(MicroTari.toTariNumber(NSNumber(3)) == 3000000)
        XCTAssert(MicroTari.convertToNumber("10.03") == NSNumber(10.03))
        XCTAssert(MicroTari.convertToString(NSNumber(10.03), minimumFractionDigits: 2) == "10.03")
        XCTAssert(MicroTari.convertToString(NSNumber(10), minimumFractionDigits: 1) == "10.0")
        XCTAssert(MicroTari.convertToString(NSNumber(10.0), minimumFractionDigits: 0) == "10")
    }
}
