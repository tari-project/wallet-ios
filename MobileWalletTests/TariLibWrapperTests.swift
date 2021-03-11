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
    private let dbName = "test_db"
    private let backupPassword = "coolpassword"
    private let privateKeyHex = "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"
    private let testWalletPublicKey = "30e1dfa197794858bfdbf96cdce5dc8637d4bd1202dc694991040ddecbf42d40"
    
    private func backupPath(_ storagePath: String) -> String {
        return "\(storagePath)/partial_backup_\(dbName).sqlite3"
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
        do {
            let privateKey = try PrivateKey(hex: privateKeyHex)
            let (hex, hexError) = privateKey.hex
            if hexError != nil {
                XCTFail(hexError!.localizedDescription)
            }
            
            XCTAssertEqual(hex, privateKeyHex)
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
        XCTAssertNoThrow(try PublicKey(emojis: "🎳🐍💸🐼🐷💍🍔💤💘🔫😻💨🎩😱💭🎒🚧🐵🏉🔦🍴🎺🍺🐪🍕👔🍄🐍😇🌂🐑🍭😇"))
        XCTAssertNoThrow(try PublicKey(emojis: "🐘💉🔨🍆💈🏆💀🎩🍼🐍💀🎂🔱🐻🐑🔪🐖😹😻🚜🐭🎁🔔💩🚂🌠📡👅🏁🏭💔🎻🌊"))

        //Invalid emoji ID
        XCTAssertThrowsError(try PublicKey(emojis: "🐒🐑🍔🔧❌👂🦒💇🔋💥🍷🍺👔😷🐶🧢🤩💥🎾🎲🏀🤠💪👮🤯🎁💉🌞🍉🤷🍦👽👽"))

        //Valid deep links
        XCTAssertNoThrow(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/eid/🎳🐍💸🐼🐷💍🍔💤💘🔫😻💨🎩😱💭🎒🚧🐵🏉🔦🍴🎺🍺🐪🍕👔🍄🐍😇🌂🐑🍭😇")
        )
        XCTAssertNoThrow(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/eid/🎳🐍💸🐼🐷💍🍔💤💘🔫😻💨🎩😱💭🎒🚧🐵🏉🔦🍴🎺🍺🐪🍕👔🍄🐍😇🌂🐑🍭😇?amount=32.1&note=hi%20there")
        )
        XCTAssertNoThrow(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/pubkey/70350e09c474809209824c6e6888707b7dd09959aa227343b5106382b856f73a"))
        XCTAssertNoThrow(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/pubkey/70350e09c474809209824c6e6888707b7dd09959aa227343b5106382b856f73a?amount=32.1note=hi%20there"))
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
        XCTAssertNoThrow(try PublicKey(any: "🎳🐍 | 💸🐼🐷 | 💍🍔💤 | 💘🔫😻 | 💨🎩😱 | 💭🎒🚧 | 🐵🏉🔦 | 🍴🎺🍺 | 🐪🍕👔 | 🍄🐍😇 | 🌂🐑🍭 | 😇"))
        XCTAssertNoThrow(try PublicKey(any: "copy this: 🐘💉🔨🍆💈🏆💀🎩🍼🐍💀🎂🔱🐻🐑🔪🐖😹😻🚜🐭🎁🔔💩🚂🌠📡👅🏁🏭💔🎻🌊 please"))
        XCTAssertNoThrow(try PublicKey(any: "My emojis are \"🐘💉🔨🍆💈🏆💀🎩🍼🐍💀🎂🔱🐻🐑🔪🐖😹😻🚜🐭🎁🔔💩🚂🌠📡👅🏁🏭💔🎻🌊\""))
        XCTAssertNoThrow(try PublicKey(any: "🐘💉🔨🍆💈🏆💀🎩🍼🐍💀🎂🔱🐻🐑🔪🐖😹 bla bla bla 😻🚜🐭🎁🔔💩🚂🌠📡👅🏁🏭💔🎻🌊"))
        XCTAssertNoThrow(try PublicKey(any: "Please send me 1234. My emojis are 🎳🐍💸🐼🐷💍🍔💤💘 and here are the rest 🔫😻💨🎩😱💭🎒🚧🐵🏉🔦🍴🎺🍺🐪🍕👔🍄🐍😇🌂🐑🍭😇"))
    }
    
    func testOldEmojiSet() {
        do {
            _ = try PublicKey(any: "⚽🧣👂🤝🏧🐳🦄🎣😛🎻🏄🚧⛺🧠🔔🧢🍄💉🕙🐔🚪🧤🍪🚒🍌👊🥜👶🤪📎🐚🦀🍎")
        } catch {
            if case PublicKeyError.invalidEmojiSet = error {
                //Correct error
            } else {
                XCTFail("Invalid emoji set should throw error")
            }
        }
        
        do {
            _ = try PublicKey(any: "send me 12 ⚽🧣👂🤝🏧🐳🦄🎣😛🎻🏄🚧⛺🧠🔔🧢🍄💉🕙🐔🚪🧤🍪🚒🍌👊🥜👶🤪📎🐚🦀🍎")
        } catch {
            if case PublicKeyError.invalidEmojiSet = error {
                //Correct error

            } else {
                XCTFail("Invalid emoji set should throw error")
            }
        }
    }
    
    func testDeepLink() {
        do {
           let params = try DeepLinkParams(deeplink: "\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/pubkey/70350e09c474809209824c6e6888707b7dd09959aa227343b5106382b856f73a?amount=60.50&note=hi%20there")

            XCTAssertEqual(60500000, params.amount.rawValue)
        } catch {
            XCTFail(error.localizedDescription)
        }
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
        let (wallet, _) = createWallet(privateHex: privateKeyHex)
            
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
        let signature = try! wallet.signMessage(msg)
        
        do {
            let verification = try signature.isValid(wallet: wallet)
            if verification != true {
                XCTFail("Verification of message failed")
            }
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
        
        receiveTestTx(wallet: wallet)
        sendTxToBob(wallet: wallet)

        let (availableBalance, _) = wallet.availableBalance
        let (pendingIncomingBalance, _) = wallet.pendingIncomingBalance
        let (pendingOutgoingBalance, _) = wallet.pendingOutgoingBalance
        
        XCTAssertGreaterThan(availableBalance, 0)
        XCTAssertGreaterThan(pendingIncomingBalance, 0)
        XCTAssertGreaterThan(pendingOutgoingBalance, 0)
    
        let (allTxs, allTxsError) = wallet.allTxs
        guard allTxsError == nil else {
            XCTFail("Failed to load all transactions: \(allTxsError!.localizedDescription)")
            return
        }
        
        let totalTxsBeforeCancelling = allTxs.count
        
        XCTAssertGreaterThan(totalTxsBeforeCancelling, 0)
        
        //Test cancel function when a pending tx has aged for 2 seconds
        sleep(2)
        XCTAssertNoThrow(try wallet.cancelAllExpiredPendingTx(after: 1))
        
        let (allTxsWithCancelled, allTxsWithCancelledError) = wallet.allTxs
        guard allTxsWithCancelledError == nil else {
            XCTFail("Failed to load all (including cancelled) transactions: \(allTxsWithCancelledError!.localizedDescription)")
            return
        }
        
        //Cancelled transactions are still in the list
        XCTAssertEqual(allTxsWithCancelled.count, totalTxsBeforeCancelling)
    }
    
    func testBackupAndRestoreWallet() {
        XCTAssertNoThrow(try ICloudServiceMock.removeBackups())
        let (wallet, _) = createWallet(privateHex: nil)
        receiveTestTx(wallet: wallet)
        sendTxToBob(wallet: wallet)

        TariLib.shared.walletPublicKeyHex = wallet.publicKey.0?.hex.0

        XCTAssertNoThrow(try ICloudBackup.shared.createWalletBackup(password: backupPassword))
        restoreWallet { backupWallet, error in
            if error != nil {
                XCTFail("Failed to restore wallet backup \(error!.localizedDescription)")
            } else {
                if backupWallet != nil {
                    self.compareWallets(w1: wallet, w2: backupWallet!)
                } else {
                    XCTFail("Failed to restore wallet backup")
                }
            }
        }
    }
    
    func testPartialBackups() {
        let (_, dbURL) = createWallet(privateHex: nil)
        let partialBackupPath = backupPath(TariSettings.testStoragePath)
        XCTAssertNoThrow(try WalletBackups.partialBackup(orginalFilePath: dbURL.path, backupFilePathWithFilename: partialBackupPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: partialBackupPath))
    }
    
    func testMicroTari() {
        let microTari = MicroTari(98234567)
        XCTAssert(microTari.taris == 98.234567)
        XCTAssert(MicroTari.toTariNumber(NSNumber(3)) == 3000000)
        //Check 2 most common local formats
        XCTAssert(
            microTari.formatted == "98.23"
                || microTari.formatted == "98,23"
        )
        XCTAssert(
            microTari.formattedWithOperator == "+ 98.23"
                || microTari.formattedWithOperator == "+ 98,23"
        )
        XCTAssert(
            microTari.formattedWithNegativeOperator == "- 98.23"
                || microTari.formattedWithNegativeOperator == "- 98,23"
        )
        XCTAssert(
            microTari.formattedPrecise == "98.2345657"
                || microTari.formattedPrecise == "98,2345657"
        )
        XCTAssert(
            MicroTari.convertToNumber("10.03") == NSNumber(10.03)
                || MicroTari.convertToNumber("10,03") == NSNumber(10.03)
        )
        XCTAssert(
            MicroTari.convertToString(NSNumber(10.03), minimumFractionDigits: 2) == "10.03"
                || MicroTari.convertToString(NSNumber(10.03), minimumFractionDigits: 2) == "10,03"
        )
        XCTAssert(
            MicroTari.convertToString(NSNumber(10), minimumFractionDigits: 1) == "10.0"
                || MicroTari.convertToString(NSNumber(10), minimumFractionDigits: 1) == "10,0"
        )
        XCTAssert(MicroTari.convertToString(NSNumber(10.0), minimumFractionDigits: 0) == "10")
        XCTAssertNoThrow(try MicroTari(tariValue: "1234567898"))
        XCTAssertThrowsError(try MicroTari(tariValue: "1234567898765432123567")) //Too large to be converted to uint64 in micro tari
        XCTAssertNoThrow(try MicroTari(decimalValue: 2))
        XCTAssertNoThrow(try MicroTari(decimalValue: 1.1234))
        XCTAssertThrowsError(try MicroTari(decimalValue: 0.123456789))
    }
    
    func testKeyValueStorage() {
        TariLogger.info("TEST KEY VALUE STORAGE")
        let (wallet, _) = createWallet(privateHex: nil)
        // random key
        let key = "7SXVVFERUP"
        let value = "DQORS7M0EO_⚽🧣👂🤝🏧_X6IZFL5OG3"
        // store value
        XCTAssert(try wallet.setKeyValue(key: key, value: value))
        // get value
        XCTAssertEqual(value, try wallet.getKeyValue(key: key))
        // clear value
        XCTAssert(try wallet.removeKeyValue(key: key))
        // value cleared, "get" should throw error
        XCTAssertThrowsError(try wallet.getKeyValue(key: key))
    }
    
    func restoreWallet(completion: @escaping ((_ wallet: Wallet?, _ error: Error?) -> Void)) {
        ICloudBackup.shared.restoreWallet(password: backupPassword, completion: { error in
            var commsConfig: CommsConfig?
            do {
                let transport = TransportType()
                let address = transport.address.0
                commsConfig = try CommsConfig(
                    transport: transport,
                    databaseFolderPath: TariSettings.testStoragePath,
                    databaseName: self.dbName,
                    publicAddress: address,
                    discoveryTimeoutSec: TariSettings.shared.discoveryTimeoutSec,
                    safMessageDurationSec: TariSettings.shared.safMessageDurationSec
                )
            } catch {
                completion(nil, error)
                return
            }
            
            do {
                let wallet = try Wallet(commsConfig: commsConfig!, loggingFilePath: self.loggingTestPath(TariSettings.testStoragePath))
                completion(wallet, error)
            } catch {
                completion(nil, error)
                return
            }
        })
    }
    
    func compareWallets(w1: Wallet, w2: Wallet) {
        let (walletPublicKey, pubKeyErrorW1) = w1.publicKey
        let (backupWalletPublicKey, pubKeyErrorW2) = w2.publicKey
        
        if pubKeyErrorW1 != nil {
            XCTFail(pubKeyErrorW1!.localizedDescription)
        }
        if pubKeyErrorW2 != nil {
            XCTFail(pubKeyErrorW2!.localizedDescription)
        }
        
        XCTAssertEqual(walletPublicKey, backupWalletPublicKey)

        XCTAssertEqual(w1.availableBalance.0, w2.availableBalance.0)
        XCTAssertEqual(w1.pendingIncomingBalance.0, w2.pendingIncomingBalance.0)
        XCTAssertEqual(w1.pendingOutgoingBalance.0, w2.pendingOutgoingBalance.0)

        XCTAssertEqual(w1.completedTxs.0?.count.0, w2.completedTxs.0?.count.0)
        XCTAssertEqual(w1.cancelledTxs.0?.count.0, w2.cancelledTxs.0?.count.0)
        XCTAssertEqual(w1.pendingInboundTxs.0?.count.0, w2.pendingInboundTxs.0?.count.0)
        XCTAssertEqual(w1.pendingOutboundTxs.0?.count.0, w2.pendingOutboundTxs.0?.count.0)
    }
    
    //MARK: Create new wallet
    func createWallet(privateHex: String?) -> (Wallet, URL) {
        var wallet: Wallet?
        
        let fileManager = FileManager.default
        let databaseFolderPath = TariSettings.testStoragePath
        let loggingFilePath = loggingTestPath(databaseFolderPath)
        
        do {
            if fileManager.fileExists(atPath: databaseFolderPath) {
                try fileManager.removeItem(atPath: databaseFolderPath)
            }
            try fileManager.createDirectory(atPath: databaseFolderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Unable to create directory \(error.localizedDescription)")
        }
                
        var commsConfig: CommsConfig?
        do {
            let transport = TransportType()
            let address = transport.address.0
            commsConfig = try CommsConfig(
                transport: transport,
                databaseFolderPath: databaseFolderPath,
                databaseName: dbName,
                publicAddress: address,
                discoveryTimeoutSec: TariSettings.shared.discoveryTimeoutSec,
                safMessageDurationSec: TariSettings.shared.safMessageDurationSec
            )
            
            if privateHex != nil {
                let privateKey = try PrivateKey(hex: privateHex!)
                try commsConfig?.setPrivateKey(privateKey)
            }

            TariLogger.verbose("TariLib Logging path: \(loggingFilePath)")
        } catch {
            XCTFail("Unable to create comms config \(error.localizedDescription)")
        }
        
        do {
            wallet = try Wallet(commsConfig: commsConfig!, loggingFilePath: loggingFilePath)
        } catch {
            XCTFail("Unable to create wallet \(error.localizedDescription)")
        }
        
        XCTAssertNoThrow(try wallet!.generateTestData())
        
        return (wallet!, URL(fileURLWithPath: databaseFolderPath).appendingPathComponent(dbName + ".sqlite3"))
    }
    
    //MARK: Receive a test transaction
    func receiveTestTx(wallet: Wallet) {
        do {
            try wallet.generateTestReceiveTx()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        //MARK: Finalize and broadcast received test transaction
        var txId: UInt64?
        do {
            let (pendingInboundTxs, pendingInboundTxsError) = wallet.pendingInboundTxs
            if pendingInboundTxsError != nil {
                XCTFail(pendingInboundTxsError!.localizedDescription)
            }
            
            let (pendingInboundTxsCount, pendingInboundTxsCountError) = pendingInboundTxs!.count
            if pendingInboundTxsCountError != nil {
                XCTFail(pendingInboundTxsCountError!.localizedDescription)
            }
            
            var currTx = 0
            txId = 0
            var pendingInboundTx: PendingInboundTx? = nil
            while (currTx < pendingInboundTxsCount) {
                pendingInboundTx = try pendingInboundTxs!.at(position: UInt32(currTx))
                let (pendingInboundTxId, pendingInboundTxIdError) = pendingInboundTx!.id
                if pendingInboundTxIdError != nil {
                    XCTFail(pendingInboundTxIdError!.localizedDescription)
                }
                txId = pendingInboundTxId
                let (pendingInboundTxStatus, _) = pendingInboundTx!.status
                if pendingInboundTxStatus == TxStatus.pending
                {
                    break;
                }
                currTx += 1
            }
            
            try wallet.testFinalizedReceivedTx(pendingInboundTx: pendingInboundTx!)
            try wallet.testTxBroadcast(txID: txId!)
            try wallet.testTxMined(txID: txId!)
            let completedTx = try wallet.findCompletedTxBy(id: txId!)
            let (status, statusError) = completedTx.status
            if statusError != nil {
                XCTFail(statusError!.localizedDescription)
            }
        
            XCTAssertEqual(status, .minedConfirmed)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    //MARK: Send transaction to bob
    func sendTxToBob(wallet: Wallet) {
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
            
            _ = try wallet.sendTx(destination: bobPublicKey!, amount: MicroTari(1000), feePerGram: MicroTari(101), message: "Oh hi bob")
            let (pendingOutboundTxs, pendingOutboundTxsError) = wallet.pendingOutboundTxs
            if pendingOutboundTxsError != nil {
                XCTFail(pendingOutboundTxsError!.localizedDescription)
            }
            
            let pendingOutboundTx = try pendingOutboundTxs!.at(position: 0)
            let (pendingOutboundTxId, pendingOutboundTxIdError) = pendingOutboundTx.id
            if pendingOutboundTxIdError != nil {
                XCTFail(pendingOutboundTxIdError!.localizedDescription)
            }
            
            sendTransactionId = pendingOutboundTxId
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        //MARK: Complete sent transaction to bob
        XCTAssertNoThrow( _ = try wallet.findPendingOutboundTxBy(id: sendTransactionId!))
        XCTAssertNoThrow(try wallet.testTxMined(txID: sendTransactionId!))
    }
}
