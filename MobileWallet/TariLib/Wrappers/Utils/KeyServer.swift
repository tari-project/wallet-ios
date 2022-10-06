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
    private let messageMetadata: MessageMetadata
    private let url: URL?
  
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    init() throws {

        let publicKeyHex = try Tari.shared.walletPublicKey.byteVector.hex
        let message = "\(MESSAGE_PREFIX) \(publicKeyHex)"
        
        messageMetadata = try Tari.shared.faucet.sign(message: message)
        
        self.url = NetworkManager.shared.selectedNetwork.faucetURL?
            .appendingPathComponent("free_tari/allocate_max")
            .appendingPathComponent(publicKeyHex)
    }

    func requestDrop(onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) throws {
        
        guard let url = url else { return }

        guard KeyServer.isRequestInProgress == false else {
            TariLogger.warn("Key server request already in progress")
            return
        }

        KeyServer.isRequestInProgress = true
        
        let completedTxsCount = Tari.shared.transactions.completed.count

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
                signature: messageMetadata.hex,
                publicNonce: messageMetadata.nonce,
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
                try self.importUtxo(sourcePublicKeyHex: returnPubKeyHex, spendingKeyHex: key1, nonce: publicNonce1, uData: uValue1, vData: vValue1, senderOffsetPublicKeyHex: senderOffsetPublicKey1, amount: value1, message: self.TARIBOT_MESSAGE1)
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
    
    private func importUtxo(sourcePublicKeyHex: String, spendingKeyHex: String, nonce: Data, uData: Data, vData: Data, senderOffsetPublicKeyHex: String, amount: UInt64, message: String) throws {
        
        let sourcePublicKey = try PublicKey(hex: sourcePublicKeyHex)
        let contact = try Contact(alias: "TariBot", publicKeyPointer: sourcePublicKey.pointer)
        try Tari.shared.contacts.upsert(contact: contact)
        
        let spendingKey = try PrivateKey(hex: spendingKeyHex)
        let signaturePointer = try Tari.shared.faucet.commitmentSignature(publicNonce: nonce, u: uData, v: vData)
        let senderOffsetPublicKey = try PublicKey(hex: senderOffsetPublicKeyHex)
        
        try Tari.shared.faucet.importUtxo(
            amount: amount,
            spendingKey: spendingKey,
            sourcePublicKey: sourcePublicKey,
            metadataSignaturePointer: signaturePointer,
            senderOffsetPublicKey: senderOffsetPublicKey,
            scriptPrivateKey: spendingKey,
            message: message
        )
    }

    private func hasSentATx() -> Bool {
        
        guard Tari.shared.transactions.pendingOutbound.isEmpty else { return true }
        
        do {
            return try Tari.shared.transactions.completed.contains { try $0.isOutboundTransaction }
        } catch {
            TariLogger.error("Failed to load completed tx", error: error)
        }
        
        return false
    }

    func importSecondUtxo(onComplete: @escaping (() -> Void)) throws {
        
        guard let data = UserDefaults.standard.value(forKey: KeyServer.secondUtxoStorageKey) as? Data, hasSentATx() else { return }
        
        do {
            let utxo = try PropertyListDecoder().decode(UTXO.self, from: data)
            TariLogger.info("Importing stored 2nd utxo")
            
            try importUtxo(
                sourcePublicKeyHex: utxo.sourcePublicKeyHex,
                spendingKeyHex: utxo.privateKeyHex,
                nonce: utxo.publicNonce,
                uData: utxo.uValue,
                vData: utxo.vValue,
                senderOffsetPublicKeyHex: utxo.senderOffsetPublicKeyHex,
                amount: utxo.value,
                message: utxo.message
            )
            
            UserDefaults.standard.removeObject(forKey: KeyServer.secondUtxoStorageKey)
            onComplete()
        } catch {
            TariLogger.error("Unable to load stored UTXO", error: error)
        }
    }

    private func storeUtxo(utxo: UTXO) throws {
        TariLogger.verbose("Storing UTXO for later use")
        UserDefaults.standard.set(try? PropertyListEncoder().encode(utxo), forKey: KeyServer.secondUtxoStorageKey)
    }
}

extension KeyServerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .server(let statusCode, let message):
            if message != nil {
                return message
            }

            return localized("key_server.error.server") + " \(statusCode)."
        case .unknown:
            return localized("key_server.error.unknown")
        case .invalidSignature:
            return localized("key_server.error.invalid_signature")
        case .tooManyAllocationRequests:
            return localized("key_server.error.too_many_allocation_requests")
        case .missingResponse:
            return localized("key_server.error.missing_response")
        case .responseInvalid:
            return localized("key_server.error.response_invalid")
        }
    }
}
