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
        XCTAssertNoThrow(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(NetworkManager.shared.selectedNetwork)/eid/🎳🐍💸🐼🐷💍🍔💤💘🔫😻💨🎩😱💭🎒🚧🐵🏉🔦🍴🎺🍺🐪🍕👔🍄🐍😇🌂🐑🍭😇")
        )
        XCTAssertNoThrow(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(NetworkManager.shared.selectedNetwork)/eid/🎳🐍💸🐼🐷💍🍔💤💘🔫😻💨🎩😱💭🎒🚧🐵🏉🔦🍴🎺🍺🐪🍕👔🍄🐍😇🌂🐑🍭😇?amount=32.1&note=hi%20there")
        )
        XCTAssertNoThrow(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(NetworkManager.shared.selectedNetwork)/pubkey/70350e09c474809209824c6e6888707b7dd09959aa227343b5106382b856f73a"))
        XCTAssertNoThrow(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(NetworkManager.shared.selectedNetwork)/pubkey/70350e09c474809209824c6e6888707b7dd09959aa227343b5106382b856f73a?amount=32.1note=hi%20there"))
        //Derive a deep link from random pubkey, then init a pubkey using that deep link
        XCTAssertNoThrow(try PublicKey(deeplink: PublicKey(privateKey: PrivateKey()).emojiDeeplink.0))
        XCTAssertNoThrow(try PublicKey(deeplink: PublicKey(privateKey: PrivateKey()).hexDeeplink.0))

        //Invalid deep links
        XCTAssertThrowsError(try PublicKey(deeplink: "bla bla bla"))
        XCTAssertThrowsError(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(NetworkManager.shared.selectedNetwork)/eid/🖖🥴😍🙃💦🤘🤜👁🙃🙌😱"))
        XCTAssertThrowsError(try PublicKey(deeplink: "\(TariSettings.shared.deeplinkURI)://\(NetworkManager.shared.selectedNetwork)/pubkey/invalid"))
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
            let params = try DeepLinkParams(deeplink: "\(TariSettings.shared.deeplinkURI)://\(NetworkManager.shared.selectedNetwork.name)/pubkey/70350e09c474809209824c6e6888707b7dd09959aa227343b5106382b856f73a?amount=60.50&note=hi%20there")

            XCTAssertEqual(60500000, params.amount.rawValue)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testBaseNode() {
        //Invalid peers
        XCTAssertThrowsError(try BaseNode(name: "Test1", peer: "bla bla bla"))
        XCTAssertThrowsError(try BaseNode(name: "Test2", peer: "5edb022af1c21d644dfceeea2fcc7d3fac7a57ab44cf775b9a6f692cb75ed767::/onion3/vjkj44zpriqzrlve2qbiasrluaaxagrb6iuavzaascbujri6gw3rcmyd"))
        XCTAssertThrowsError(try BaseNode(name: "Test3", peer: "5edb022af1c21d644dfceeea2fcc7d3fac7a57ab44cf775b9a6f692cb75ed767::vjkj44zpriqzrlve2qbiasrluaaxagrb6iuavzaascbujri6gw3rcmyd:18141"))

        //Valid peer
        XCTAssertNoThrow(try BaseNode(name: "Test4", peer:"2e93c460df49d8cfbbf7a06dd9004c25a84f92584f7d0ac5e30bd8e0beee9a43::/onion3/nuuq3e2olck22rudimovhmrdwkmjncxvwdgbvfxhz6myzcnx2j4rssyd:18141"))
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
            microTari.formattedWithOperator == "+ 98.234567"
                || microTari.formattedWithOperator == "+ 98,234567"
        )
        XCTAssert(
            microTari.formattedWithNegativeOperator == "- 98.234567"
                || microTari.formattedWithNegativeOperator == "- 98,234567"
        )
        XCTAssert(
            microTari.formattedPrecise == "98.234567"
                || microTari.formattedPrecise == "98,234567"
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
                    safMessageDurationSec: TariSettings.shared.safMessageDurationSec,
                    networkName: TariNetwork.weatherwax.name
                )
            } catch {
                completion(nil, error)
                return
            }
            
            do {
                let wallet = try Wallet(commsConfig: commsConfig!, loggingFilePath: self.loggingTestPath(TariSettings.testStoragePath), seedWords: nil)
                completion(wallet, error)
            } catch {
                completion(nil, error)
                return
            }
        })
    }
}
