//  TestnetKeyServer.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/02/07
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

enum TestnetKeyServerError: Error {
    case server(_ statusCode: Int, message: String?)
    case invalidSignature
    case allCoinsAllAllocated
    case missingResponse
    case responseInvalid
    case unknown
}

struct TestnetServerRequest: Codable {
    let signature: String
    let public_nonce: String
}

class TestnetKeyServer {
    private let MESSAGE_PREFIX = "Hello Tari from"
    private let SERVER = "https://faucet.tari.com" //TODO store in config
    private let TARIBOT_MESSAGE1 = String(
        format: NSLocalizedString(
            "💸 Here’s some %@!",
            comment: "TariBot transaction"
        ),
        TariSettings.shared.network.currencyDisplayName
    )
    private let TARIBOT_MESSAGE2 = String(
        format: NSLocalizedString(
            "Nice work! Here's more Tari to fill your coffers. Be sure to hit the Store icon to see real, "
            + "exclusive items you can redeem with your \"hard-earned\" testnet Tari.",
            comment: "TariBot transaction"
        ),
        TariSettings.shared.network.currencyDisplayName
    )
    private let signature: Signature
    private let url: URL
    private let wallet: Wallet
    static var isRequestInProgress = false
    private static let secondUtxoStorageKey = "tari-available-utxo"

    init(wallet: Wallet) throws {
        let (publicKey, publicKeyError) = wallet.publicKey
        guard publicKeyError == nil else {
            throw publicKeyError!
        }

        let (publicKeyHex, hexError) = publicKey!.hex
        guard hexError == nil else {
            throw hexError!
        }

        let message = "\(MESSAGE_PREFIX) \(publicKeyHex)"

        self.wallet = wallet
        self.signature = try wallet.signMessage(message)
        self.url = URL(string: "\(SERVER)/free_tari/allocate_max/\(publicKeyHex)")!
    }

    func requestDrop(onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) throws {
        guard TestnetKeyServer.isRequestInProgress == false else {
            TariLogger.warn("Key server request already in progress")
            return
        }

        TestnetKeyServer.isRequestInProgress = true

        let (completedTransactions, completedTransactionsError) = wallet.completedTransactions
        guard let completedTxs = completedTransactions else {
            TestnetKeyServer.isRequestInProgress = false
            throw completedTransactionsError!
        }

        let (completedTransactionsCount, completedTransactionsCountError) = completedTxs.count
        guard completedTransactionsCountError == nil else {
            TestnetKeyServer.isRequestInProgress = false
            throw completedTransactionsCountError!
        }

        //If the user has a completed, just ignore this request as it's not a fresh install
        guard completedTransactionsCount == 0 else {
            TestnetKeyServer.isRequestInProgress = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            TestnetServerRequest(
                signature: signature.hex,
                public_nonce: signature.nonce
            )
        )

        let onRequestError = {(error: Error) in
            onError(error)
            TestnetKeyServer.isRequestInProgress = false
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                onRequestError(error!)
                return
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                onRequestError(TestnetKeyServerError.unknown)
                return
            }

            guard response.statusCode != 403 else {
                onRequestError(TestnetKeyServerError.invalidSignature)
                return
            }

            var responseDict: [String: Any]?
            if let responseString = String(data: data, encoding: .utf8) {
                if let data = responseString.data(using: .utf8) {
                    do {
                        responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        onRequestError(error)
                        return
                    }
                }
            }

            guard (200 ... 299) ~= response.statusCode else {
                var message: String?
                if let res = responseDict {
                    message = res["error"] as? String
                }

                onRequestError(TestnetKeyServerError.server(response.statusCode, message: message))
                return
            }

            guard let res = responseDict else {
                onRequestError(TestnetKeyServerError.missingResponse)
                return
            }

            guard let keysDict = res["keys"] as? [[String: String]], let returnPubKeyHex = res["return_wallet_id"] as? String else {
                onRequestError(TestnetKeyServerError.responseInvalid)
                return
            }

            guard keysDict.count == 2 else {
                onRequestError(TestnetKeyServerError.responseInvalid)
                return
            }

            guard let key1 = keysDict[0]["key"], let valueString1 = keysDict[0]["value"] else {
                onRequestError(TestnetKeyServerError.responseInvalid)
                return
            }

            guard let value1 = UInt64(valueString1) else {
                onRequestError(TestnetKeyServerError.responseInvalid)
                return
            }

            do {
                let utxo = UTXO(
                    privateKeyHex: key1,
                    value: value1,
                    message: self.TARIBOT_MESSAGE1,
                    sourcePublicKeyHex: returnPubKeyHex
                )

                //Add TariBot as a contact
                try self.wallet.addUpdateContact(alias: "TariBot", publicKeyHex: utxo.sourcePublicKeyHex)
                try self.wallet.importUtxo(utxo)

            } catch {
                onRequestError(error)
                return
            }

            guard let key2 = keysDict[1]["key"], let valueString2 = keysDict[1]["value"] else {
                onRequestError(TestnetKeyServerError.responseInvalid)
                return
            }

            guard let value2 = UInt64(valueString2) else {
                onRequestError(TestnetKeyServerError.responseInvalid)
                return
            }

            do {
                try self.storeUtxo(
                    utxo: UTXO(
                        privateKeyHex: key2,
                        value: value2,
                        message: self.TARIBOT_MESSAGE2,
                        sourcePublicKeyHex: returnPubKeyHex)
                )
            } catch {
                onRequestError(error)
                return
            }

            onSuccess()
            TestnetKeyServer.isRequestInProgress = false
        }

        task.resume()
    }

    private func hasSentATransaction() -> Bool {
        guard let (pendingOutboundTransactions) = wallet.pendingOutboundTransactions.0 else {
            TariLogger.error("Failed to load pendingOutboundTransactions")
            return false
        }

        if pendingOutboundTransactions.count.0 > 0 {
            return true
        }

        guard let (completedTransactions) = wallet.completedTransactions.0 else {
            TariLogger.error("Failed to load completedTransactions")
            return false
        }

        let completedCount = completedTransactions.count.0
        guard completedCount > 0 else {
            return false
        }

        for n in 0...completedCount - 1 {
            do {
                let tx = try completedTransactions.at(position: n)
                if tx.direction == .outbound {
                    return true
                }
            } catch {
                TariLogger.error("Failed to load completed tx", error: error)
            }
        }

        return false
    }

    func importSecondUtxo(onComplete: @escaping (() -> Void)) throws {
        if let data = UserDefaults.standard.value(forKey: TestnetKeyServer.secondUtxoStorageKey) as? Data {
            guard hasSentATransaction() else {
                return
            }

            do {
                let utxo = try PropertyListDecoder().decode(UTXO.self, from: data)
                TariLogger.info("Importing stored 2nd utxo")

                try self.wallet.importUtxo(utxo)

                UserDefaults.standard.removeObject(forKey: TestnetKeyServer.secondUtxoStorageKey)
                onComplete()
            } catch {
                TariLogger.error("Unable to load stored UTXO", error: error)
            }
        }
    }

    private func storeUtxo(utxo: UTXO) throws {
        TariLogger.verbose("Storing UTXO for later use")
        UserDefaults.standard.set(try? PropertyListEncoder().encode(utxo), forKey: TestnetKeyServer.secondUtxoStorageKey)
    }
}
