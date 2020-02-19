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
    private let TARIBOT_MESSAGE = "Some Tari to get you started."
    private let signature: Signature
    private let url: URL
    private let wallet: Wallet
    static var isRequestInProgress = false

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
        self.url = URL(string: "\(SERVER)/free_tari/allocate/\(publicKeyHex)")!
    }

    func requestDrop(onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) throws {
        guard TestnetKeyServer.isRequestInProgress == false else {
            print("Request in progress")
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

        //If the user has a spendable balance, just ignore this request
        guard completedTransactionsCount == 0 else {
            print("Wallet already has funds")
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

            var responseDict: [String: String]?
            if let responseString = String(data: data, encoding: .utf8) {
                if let data = responseString.data(using: .utf8) {
                    do {
                        responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
                    } catch {
                        onRequestError(error)
                    }
                }
            }

            guard (200 ... 299) ~= response.statusCode else {
                var message: String?
                if let res = responseDict {
                    message = res["error"]
                }

                onRequestError(TestnetKeyServerError.server(response.statusCode, message: message))
                return
            }

            guard let res = responseDict else {
                onRequestError(TestnetKeyServerError.missingResponse)
                return
            }

            guard let key = res["key"], let valueString = res["value"], let returnPubKeyHex = res["return_wallet_id"] else {
                onRequestError(TestnetKeyServerError.responseInvalid)
                return
            }

            guard let value = UInt64(valueString) else {
                onRequestError(TestnetKeyServerError.responseInvalid)
                return
            }

            do {
                try self.importKey(key: key, value: value, message: self.TARIBOT_MESSAGE, returnPubKeyHex: returnPubKeyHex)
            } catch {
                onRequestError(error)
                return
            }

            onSuccess()
            TestnetKeyServer.isRequestInProgress = false
        }

        task.resume()
    }

    private func importKey(key: String, value: UInt64, message: String, returnPubKeyHex: String) throws {
        //Add TariBot as a contact
        try wallet.addUpdateContact(alias: "TariBot", publicKeyHex: returnPubKeyHex)
        try wallet.importUtxo(value: value, message: message, privateKey: PrivateKey(hex: key), sourcePublicKey: PublicKey(hex: returnPubKeyHex))

        TariEventBus.postToMainThread(.balanceUpdate)
        TariEventBus.postToMainThread(.transactionListUpdate)
    }
}
