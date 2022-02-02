//  KeyServer.swift

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

enum KeyServerError: Error {
    case server(_ statusCode: Int, message: String?)
    case invalidSignature
    case tooManyAllocationRequests
    case missingResponse
    case responseInvalid
    case unknown
}

struct KeyServerRequest: Encodable {
    let signature: String
    let publicNonce: String
    let network: String?
}

final class KeyServer {
    
    private static let secondUtxoStorageKey = "tari-available-utxo"
    private static var isRequestInProgress = false
    
    private let MESSAGE_PREFIX = localized("taribot.message.prefix")
    private let TARIBOT_MESSAGE1 = String(
        format: localized("taribot.message1.with_param"),
        NetworkManager.shared.selectedNetwork.tickerSymbol
    )
    private let TARIBOT_MESSAGE2 = String(
        format: localized("taribot.message2.with_params"),
        NetworkManager.shared.selectedNetwork.tickerSymbol,
        NetworkManager.shared.selectedNetwork.tickerSymbol
    )
    private let signature: Signature
    private let url: URL?
  
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    init() throws {
        guard let wallet = TariLib.shared.tariWallet else {
            throw WalletErrors.walletNotInitialized
        }

        let (publicKey, publicKeyError) = wallet.publicKey
        guard publicKeyError == nil else {
            throw publicKeyError!
        }

        let (publicKeyHex, hexError) = publicKey!.hex
        guard hexError == nil else {
            throw hexError!
        }

        let message = "\(MESSAGE_PREFIX) \(publicKeyHex)"

        self.signature = try wallet.signMessage(message)
        
        self.url = NetworkManager.shared.selectedNetwork.faucetURL?
            .appendingPathComponent("free_tari/allocate_max")
            .appendingPathComponent(publicKeyHex)
    }

    func requestDrop(onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) throws {
        
        guard let wallet = TariLib.shared.tariWallet, let url = self.url else { return }

        guard KeyServer.isRequestInProgress == false else {
            TariLogger.warn("Key server request already in progress")
            return
        }

        KeyServer.isRequestInProgress = true

        let (completedTxs, completedTxsError) = wallet.completedTxs
        guard completedTxs != nil else {
            KeyServer.isRequestInProgress = false
            throw completedTxsError!
        }

        let (completedTxsCount, completedTxsCountError) = completedTxs!.count
        guard completedTxsCountError == nil else {
            KeyServer.isRequestInProgress = false
            throw completedTxsCountError!
        }

        // If the user has a completed, just ignore this request as it's not a fresh install
        guard completedTxsCount == 0 else {
            KeyServer.isRequestInProgress = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder.encode(
            KeyServerRequest(
                signature: signature.hex,
                publicNonce: signature.nonce,
                network: NetworkManager.shared.selectedNetwork.name
            )
        )

        let onRequestError = {(error: Error) in
            onError(error)
            KeyServer.isRequestInProgress = false
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                onRequestError(error!)
                return
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                onRequestError(KeyServerError.unknown)
                return
            }

            // too many faucet requests
            if let responseBody = String(data: data, encoding: .utf8),
                response.statusCode == 403,
                responseBody.lowercased().contains("too many allocation attempts") {
                onRequestError(KeyServerError.tooManyAllocationRequests)
                return
            }

            // signature error
            guard response.statusCode != 403 else {
                onRequestError(KeyServerError.invalidSignature)
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

                onRequestError(KeyServerError.server(response.statusCode, message: message))
                return
            }

            guard let res = responseDict else {
                onRequestError(KeyServerError.missingResponse)
                return
            }

            guard let keysDict = res["keys"] as? [[String: Any]], let returnPubKeyHex = res["return_wallet_id"] as? String else {
                onRequestError(KeyServerError.responseInvalid)
                return
            }

            guard keysDict.count == 2 else {
                onRequestError(KeyServerError.responseInvalid)
                return
            }

            guard let key1 = keysDict[0]["key"] as? String, let valueString1 = keysDict[0]["value"] as? String else {
                onRequestError(KeyServerError.responseInvalid)
                return
            }

            guard let value1 = UInt64(valueString1) else {
                onRequestError(KeyServerError.responseInvalid)
                return
            }
            
            guard let output1 = keysDict[0]["output"] as? [String: Any], let metadataSignature1 = output1["metadata_signature"] as? [String: String], let senderOffsetPublicKey1 = output1["sender_offset_public_key"] as? String,
                    let rawPublicNonce1 = metadataSignature1["public_nonce"], let rawUValue1 = metadataSignature1["u"], let rawVValue1 = metadataSignature1["v"],
                    let publicNonce1 = rawPublicNonce1.hexData, let uValue1 = rawUValue1.hexData, let vValue1 = rawVValue1.hexData else {
                onRequestError(KeyServerError.responseInvalid)
                return
            }

            do {
                let utxo = UTXO(
                    privateKeyHex: key1,
                    value: value1,
                    message: self.TARIBOT_MESSAGE1,
                    sourcePublicKeyHex: returnPubKeyHex,
                    publicNonce: publicNonce1,
                    uValue: uValue1,
                    vValue: vValue1,
                    senderOffsetPublicKeyHex: senderOffsetPublicKey1
                )

                // Add TariBot as a contact
                try wallet.addUpdateContact(alias: "TariBot", publicKeyHex: utxo.sourcePublicKeyHex)
                try wallet.importUtxo(utxo)

            } catch {
                onRequestError(error)
                return
            }

            guard let key2 = keysDict[1]["key"] as? String, let valueString2 = keysDict[1]["value"] as? String else {
                onRequestError(KeyServerError.responseInvalid)
                return
            }

            guard let value2 = UInt64(valueString2) else {
                onRequestError(KeyServerError.responseInvalid)
                return
            }
            
            guard let output2 = keysDict[1]["output"] as? [String: Any], let metadataSignature2 = output2["metadata_signature"] as? [String: String], let senderOffsetPublicKey2 = output2["sender_offset_public_key"] as? String,
                  let rawPublicNonce2 = metadataSignature2["public_nonce"], let rawUValue2 = metadataSignature2["u"], let rawVValue2 = metadataSignature2["v"],
                  let publicNonce2 = rawPublicNonce2.hexData, let uValue2 = rawUValue2.hexData, let vValue2 = rawVValue2.hexData else {
                onRequestError(KeyServerError.responseInvalid)
                return
            }

            do {
                try self.storeUtxo(
                    utxo: UTXO(
                        privateKeyHex: key2,
                        value: value2,
                        message: self.TARIBOT_MESSAGE2,
                        sourcePublicKeyHex: returnPubKeyHex,
                        publicNonce: publicNonce2,
                        uValue: uValue2,
                        vValue: vValue2,
                        senderOffsetPublicKeyHex: senderOffsetPublicKey2
                    )
                )
            } catch {
                onRequestError(error)
                return
            }

            onSuccess()
            KeyServer.isRequestInProgress = false
        }

        task.resume()
    }

    private func hasSentATx() -> Bool {
        guard let wallet = TariLib.shared.tariWallet else {
            return false
        }

        guard let (pendingOutboundTxs) = wallet.pendingOutboundTxs.0 else {
            TariLogger.error("Failed to load pendingOutboundTxs")
            return false
        }

        if pendingOutboundTxs.count.0 > 0 {
            return true
        }

        guard let (completedTxs) = wallet.completedTxs.0 else {
            TariLogger.error("Failed to load completedTxs")
            return false
        }

        let completedCount = completedTxs.count.0
        guard completedCount > 0 else {
            return false
        }

        for n in 0...completedCount - 1 {
            do {
                let tx = try completedTxs.at(position: n)
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
        guard let wallet = TariLib.shared.tariWallet else {
            return
        }

        if let data = UserDefaults.standard.value(forKey: KeyServer.secondUtxoStorageKey) as? Data {
            guard hasSentATx() else {
                return
            }

            do {
                let utxo = try PropertyListDecoder().decode(UTXO.self, from: data)
                TariLogger.info("Importing stored 2nd utxo")

                try wallet.importUtxo(utxo)

                UserDefaults.standard.removeObject(forKey: KeyServer.secondUtxoStorageKey)
                onComplete()
            } catch {
                TariLogger.error("Unable to load stored UTXO", error: error)
            }
        }
    }

    private func storeUtxo(utxo: UTXO) throws {
        TariLogger.verbose("Storing UTXO for later use")
        UserDefaults.standard.set(try? PropertyListEncoder().encode(utxo), forKey: KeyServer.secondUtxoStorageKey)
    }
}
