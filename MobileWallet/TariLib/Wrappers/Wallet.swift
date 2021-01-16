//  Wallet.swift

/*
	Package MobileWallet
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

import Foundation

enum WalletErrors: Error {
    case generic(_ errorCode: Int32)
    case insufficientFunds(microTariSpendable: MicroTari)
    case addUpdateContact
    case removeContact
    case addOwnContact
    case invalidPublicKeyHex
    case generateTestData
    case generateTestReceiveTx
    case sendingTx
    case testTxBroadcast
    case testTxMined
    case testSendCompleteTx
    case completedTxById
    case cancelledTxById
    case walletNotInitialized
    case invalidSignatureAndNonceString
    case cancelNonPendingTx
    case txToCancel
}

struct CallbackTxResult {
    let id: UInt64
    let success: Bool
}

class Wallet {
    private var ptr: OpaquePointer

    var dbPath: String
    var dbName: String
    var logPath: String

    var pointer: OpaquePointer {
        return ptr
    }

    var contacts: (Contacts?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            Contacts(contactsPointer: wallet_get_contacts(ptr, error))

        })
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var availableBalance: (UInt64, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_available_balance(ptr, error)})
        return (result, errorCode != 0 ? WalletErrors.generic(errorCode) : nil)
    }

    var pendingIncomingBalance: (UInt64, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_pending_incoming_balance(ptr, error)})
        return (result, errorCode != 0 ? WalletErrors.generic(errorCode) : nil)
    }

    var pendingOutgoingBalance: (UInt64, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_pending_outgoing_balance(ptr, error)})
        return (result, errorCode != 0 ? WalletErrors.generic(errorCode) : nil)
    }

    var totalMicroTari: (MicroTari?, Error?) {
        let (availableBalance, availableBalanceError) = self.availableBalance
        if availableBalanceError != nil {
            return (nil, availableBalanceError)
        }

        let (pendingIncomingBalance, pendingIncomingBalanceError) = self.pendingIncomingBalance
        if pendingIncomingBalanceError != nil {
            return (nil, pendingIncomingBalanceError)
        }

        let (_, pendingOutgoingBalanceError) = self.pendingOutgoingBalance
        if pendingOutgoingBalanceError != nil {
            return (nil, pendingOutgoingBalanceError)
        }

        return (MicroTari(availableBalance + pendingIncomingBalance), nil)
    }

    var publicKey: (PublicKey?, Error?) {
        var errorCode: Int32 = -1
        let result = PublicKey(pointer: withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_public_key(ptr, error)}))
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }

        return (result, nil)
    }

    var torPrivateKey: (ByteVector?, Error?) {
        var errorCode: Int32 = -1
        let resultPtr = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_tor_identity(ptr, error)})
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (ByteVector(pointer: resultPtr!), nil)
    }

    init(commsConfig: CommsConfig, loggingFilePath: String) throws {
        let loggingFilePathPointer = UnsafeMutablePointer<Int8>(mutating: (loggingFilePath as NSString).utf8String)!

        let receivedTxCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let pendingInbound = PendingInboundTx(pendingInboundTxPointer: valuePointer!)
            TariEventBus.postToMainThread(.receivedTx, sender: pendingInbound)
            TariEventBus.postToMainThread(.txListUpdate)
            TariEventBus.postToMainThread(.requiresBackup)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Receive transaction lib callback")
        }

        let receivedTxReplyCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTx(completedTxPointer: valuePointer!)
            TariEventBus.postToMainThread(.receievedTxReply, sender: completed)
            TariEventBus.postToMainThread(.txListUpdate)
            TariEventBus.postToMainThread(.requiresBackup)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Receive transaction reply lib callback")
        }

        let receivedFinalizedTxCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTx(completedTxPointer: valuePointer!)
            TariEventBus.postToMainThread(.receivedFinalizedTx, sender: completed)
            TariEventBus.postToMainThread(.requiresBackup)
            TariEventBus.postToMainThread(.txListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Receive finalized transaction lib callback")
        }

        let txBroadcastCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTx(completedTxPointer: valuePointer!)
            TariEventBus.postToMainThread(.txBroadcast, sender: completed)
            TariEventBus.postToMainThread(.requiresBackup)
            TariEventBus.postToMainThread(.txListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Transaction broadcast lib callback")
        }

        let txMinedCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTx(completedTxPointer: valuePointer!)
            TariEventBus.postToMainThread(.txMined, sender: completed)
            TariEventBus.postToMainThread(.requiresBackup)
            TariEventBus.postToMainThread(.txListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Transaction mined lib callback")
        }

        let directSendResultCallback: (@convention(c) (UInt64, Bool) -> Void)? = { txID, success in
            TariEventBus.postToMainThread(.directSend, sender: CallbackTxResult(id: txID, success: success))
            let message = "Direct send lib callback. txID=\(txID)"
            if success {
                TariLogger.verbose("\(message) ✅")
                TariEventBus.postToMainThread(.txListUpdate)
                TariEventBus.postToMainThread(.balanceUpdate)
                TariEventBus.postToMainThread(.requiresBackup)
            } else {
                TariLogger.error("\(message) failure")
            }
        }

        let storeAndForwardSendResultCallback: (@convention(c) (UInt64, Bool) -> Void)? = { txID, success in
            TariEventBus.postToMainThread(.storeAndForwardSend, sender: CallbackTxResult(id: txID, success: success))
            let message = "Store and forward lib callback. txID=\(txID)"
            if success {
                TariLogger.verbose("\(message) ✅")
                TariEventBus.postToMainThread(.txListUpdate)
                TariEventBus.postToMainThread(.balanceUpdate)
                TariEventBus.postToMainThread(.requiresBackup)
            } else {
                TariLogger.error("\(message) failure")
            }
        }

        let txCancellationCallback: (@convention(c) (OpaquePointer?) -> Void)? = { valuePointer in
            let cancelledTxId = CompletedTx(completedTxPointer: valuePointer!).id
            TariEventBus.postToMainThread(.txListUpdate)
            TariEventBus.postToMainThread(.txCancellation)
            TariEventBus.postToMainThread(.requiresBackup)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Transaction cancelled callback. txID=\(cancelledTxId) ✅")
        }

        let baseNodeSyncCompleteCallback: (@convention(c) (UInt64, Bool) -> Void)? = {
            requestId, success in
            let result: [String: Any] = ["requestId": requestId, "success": success]
            TariEventBus.postToMainThread(.baseNodeSyncComplete, sender: result)
            let message = "Base node sync lib callback. requestID=\(requestId)"
            if success {
                TariLogger.verbose("\(message) ✅")
            } else {
                TariLogger.error("\(message) failure")
            }
        }

        let storedMessagesReceivedCallback: (@convention(c) () -> Void)? = {
            TariEventBus.postToMainThread(.storedMessagesReceived, sender: nil)
            TariLogger.verbose("Stored messages receieved ✅")
        }

        dbPath = commsConfig.dbPath
        dbName = commsConfig.dbName
        logPath = loggingFilePath

        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_create(
            commsConfig.pointer,
            loggingFilePathPointer,
            0, //num_rolling_log_files
            0, //size_per_log_file_bytes
            nil, //TODO use passphrase when ready to implement
            receivedTxCallback,
            receivedTxReplyCallback,
            receivedFinalizedTxCallback,
            txBroadcastCallback,
            txMinedCallback,
            directSendResultCallback,
            storeAndForwardSendResultCallback,
            txCancellationCallback,
            baseNodeSyncCompleteCallback,
            storedMessagesReceivedCallback,
            error)}
        )
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        ptr = result!
    }

    func removeContact(_ contact: Contact) throws {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_remove_contact(ptr, contact.pointer, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        if !result {
            throw WalletErrors.removeContact
        }
    }

    func addUpdateContact(alias: String, publicKeyHex: String) throws {
        let publicKey = try PublicKey(hex: publicKeyHex)
        try addUpdateContact(alias: alias, publicKey: publicKey)
    }

    func addUpdateContact(alias: String, publicKey: PublicKey) throws {
        let (currentWalletPublicKey, publicKeyError) = self.publicKey
        if publicKeyError != nil {
            throw publicKeyError!
        }

        let (currentWalletPublicKeyHex, currentWalletPublicKeyHexError) = currentWalletPublicKey!.hex
        if currentWalletPublicKeyHexError != nil {
            throw currentWalletPublicKeyHexError!
        }

        if publicKey.hex.0 == currentWalletPublicKeyHex {
            throw WalletErrors.addOwnContact
        }

        let newContact = try Contact(alias: alias, publicKey: publicKey)
        var errorCode: Int32 = -1
        let contactAdded = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_upsert_contact(ptr, newContact.pointer, error)})

        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        if !contactAdded {
            throw WalletErrors.addUpdateContact
        }

        TariEventBus.postToMainThread(.txListUpdate)
    }

    func estimateTxFee(amount: MicroTari, gramFee: MicroTari, kernelCount: UInt64, outputCount: UInt64) throws -> MicroTari {
        var errorCode: Int32 = -1

        let fee = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_fee_estimate(ptr, amount.rawValue, gramFee.rawValue, kernelCount, outputCount, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        return MicroTari(fee)
    }

    func sendTx(destination: PublicKey, amount: MicroTari, fee: MicroTari, message: String) throws -> UInt64 {
        let total = fee.rawValue + amount.rawValue
        let (availableBalance, error) = self.availableBalance
        if error != nil {
            throw error!
        }

        if total > availableBalance {
            throw WalletErrors.insufficientFunds(microTariSpendable: MicroTari(availableBalance))
        }

        let messagePointer = UnsafeMutablePointer<Int8>(mutating: (message as NSString).utf8String)
        var errorCode: Int32 = -1

        let txId = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_send_transaction(ptr, destination.pointer, amount.rawValue, fee.rawValue, messagePointer, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        if txId == 0 {
            throw WalletErrors.sendingTx
        }

        return txId
    }

    func findPendingOutboundTxBy(id: UInt64) throws -> PendingOutboundTx? {
        var errorCode: Int32 = -1
        let pendingOutboundTxPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_pending_outbound_transaction_by_id(ptr, id, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        if let txPointer = pendingOutboundTxPointer {
            return PendingOutboundTx(pendingOutboundTxPointer: txPointer)
        }
        return nil
    }

    func findPendingInboundTxBy(id: UInt64) throws -> PendingInboundTx? {
         var errorCode: Int32 = -1
         let pendingInboundTxPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_pending_inbound_transaction_by_id(ptr, id, error)})
         guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
         }
         if let txPointer = pendingInboundTxPointer {
             return PendingInboundTx(pendingInboundTxPointer: txPointer)
         }
         return nil
     }

    func findCompletedTxBy(id: UInt64) throws -> CompletedTx {
        var errorCode: Int32 = -1
        let completedTxPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_completed_transaction_by_id(ptr, id, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        guard completedTxPointer != nil else {
            throw WalletErrors.completedTxById
        }

        return CompletedTx(completedTxPointer: completedTxPointer!)
    }

    func findCancelledTxBy(id: UInt64) throws -> CompletedTx {
        var errorCode: Int32 = -1
        let completedTxPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_cancelled_transaction_by_id(ptr, id, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        guard completedTxPointer != nil else {
            throw WalletErrors.cancelledTxById
        }

        return CompletedTx(completedTxPointer: completedTxPointer!, isCancelled: true)
    }

    func signMessage(_ message: String) throws -> Signature {
        var errorCode: Int32 = -1
        let messagePointer = (message as NSString).utf8String
        let resultPtr = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_sign_message(ptr, messagePointer, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        let result = String(cString: resultPtr!)

        let mutable = UnsafeMutablePointer<Int8>(mutating: resultPtr!)
        string_destroy(mutable)

        let (walletPubKey, publicKeyError) = self.publicKey
        guard publicKeyError == nil else {
            throw publicKeyError!
        }

        let splitResult = result.components(separatedBy: "|")
        guard splitResult.count == 2 else {
            throw WalletErrors.invalidSignatureAndNonceString
        }

        return Signature(hex: splitResult[0], nonce: splitResult[1], message: message, publicKey: walletPubKey!)
    }

    func verifyMessageSignature(publicKey: PublicKey, signature: String, nonce: String, message: String) throws -> Bool {
        var errorCode: Int32 = -1
        let messagePointer = (message as NSString).utf8String
        let hexSigNoncePointer = ("\(signature)|\(nonce)" as NSString).utf8String
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_verify_message_signature(ptr, publicKey.pointer, hexSigNoncePointer, messagePointer, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        return result
    }

    func importUtxo(_ utxo: UTXO) throws {
        let privateKey = try utxo.getPrivateKey()
        let sourcePublicKey = try utxo.getSourcePublicKey()

        var errorCode: Int32 = -1
        let messagePointer = (utxo.message as NSString).utf8String
        _ = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_import_utxo(ptr, utxo.value, privateKey.pointer, sourcePublicKey.pointer, messagePointer, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        TariEventBus.postToMainThread(.requiresBackup)
        TariEventBus.postToMainThread(.balanceUpdate)
        TariEventBus.postToMainThread(.txListUpdate)

        try syncBaseNode()
    }

    func addBaseNodePeer(_ basenode: BaseNode) throws {
        var errorCode: Int32 = -1
        let addressPointer = (basenode.address as NSString).utf8String

        _ = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_add_base_node_peer(ptr, basenode.publicKey.pointer, addressPointer, error)})

        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
    }

    func syncBaseNode() throws -> UInt64 {
        var errorCode: Int32 = -1
        let requestId = withUnsafeMutablePointer(
            to: &errorCode
        ) {
            error in
            wallet_sync_with_base_node(ptr, error)
        }
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        return requestId
    }

    /// Cancel all pending transactions after a certain amount of time has passed.
    /// - Parameter after: Amount of time after a transaction was created
    func cancelAllExpiredPendingTx(after: TimeInterval = TariSettings.shared.txTimeToExpire) throws {
        guard let outboundList = pendingOutboundTxs.0?.list.0, let inboundList = pendingInboundTxs.0?.list.0 else {
            throw WalletErrors.txToCancel
        }

        let list: [TxProtocol] = outboundList + inboundList

        try list.forEach({ (tx) in
            guard tx.status.0 == .pending, let date = tx.date.0 else {
                return
            }

            if date.distance(to: Date()) > after {
                try cancelPendingTx(tx)
            }
        })
    }

    /// Cancels a transaction that's currently pending.
    /// Helpful for expiring transactions where the other party has failed to sign their part after a certain amount of time.
    /// - Parameter tx: Pending transaction to be cancelled
    func cancelPendingTx(_ tx: TxProtocol) throws {
        guard tx.status.0 == .pending else {
            throw WalletErrors.cancelNonPendingTx
        }

        try cancelPendingTx(tx.id.0)
    }

    /// Cancels a transaction that's currently pending.
    /// Helpful for expiring transactions where the other party has failed to sign their part after a certain amount of time.
    /// - Parameter txId: ID of pending incoming or outgoing transaction
    private func cancelPendingTx(_ txId: UInt64) throws {
        var errorCode: Int32 = -1
        _ = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_cancel_pending_transaction(ptr, txId, error)
        })

        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
    }

    func recentPublicKeys(limit: Int) throws -> [PublicKey] {
        let completedPublicKeys = try txsPublicKeys(completedTxs, limit: limit)
        let pendingInboundPublicKeys = try txsPublicKeys(pendingInboundTxs, limit: limit)
        let pendingOutboundPublicKeys = try txsPublicKeys(pendingOutboundTxs, limit: limit)

        return completedPublicKeys.union(pendingInboundPublicKeys).union(pendingOutboundPublicKeys).suffix(limit)
    }

    private func txsPublicKeys<Txs: TxsProtocol>(_ transactions: (txs: Txs?, txsError: Error?), limit: Int) throws -> Set<PublicKey> {
        guard let txs = transactions.txs else { throw transactions.txsError! }

        let (txsCount, txsCountError) = txs.count
        guard txsCountError == nil else { throw txsCountError! }

        var publicKeys: Set<PublicKey> = []

        if txsCount > 0 {
            for n in 0...txsCount - 1 {
                if publicKeys.count >= limit {
                    return publicKeys
                }
                let tx = try txs.at(position: UInt32(n))
                let (publicKey, pubKeyError) = tx.direction == .inbound ? tx.sourcePublicKey : tx.destinationPublicKey
                guard let pubKey = publicKey, pubKeyError == nil else {
                    throw pubKeyError!
                }
                publicKeys.insert(pubKey)
            }
        }

        return publicKeys
    }

    func coinSplit(amount: UInt64, splitCount: UInt64, fee: UInt64, message: String, lockHeight: UInt64) throws -> UInt64 {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            message.withCString({ cstr in
                wallet_coin_split(ptr, amount, splitCount, fee, cstr, lockHeight, error)
            })
            })

        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        return result
    }

    func setKeyValue(key: String, value: String) throws -> Bool {
        var errorCode: Int32 = -1
        let keyPointer = (key as NSString).utf8String
        let valuePointer = (value as NSString).utf8String

        let result = withUnsafeMutablePointer(to: &errorCode) {
            error in
            wallet_set_key_value(ptr, keyPointer, valuePointer, error)
        }
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        return result
    }

    func getKeyValue(key: String) throws -> String {
        var errorCode: Int32 = -1
        let keyPointer = (key as NSString).utf8String
        let resultPtr = withUnsafeMutablePointer(to: &errorCode) {
            error in
            wallet_get_value(ptr, keyPointer, error)
        }
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        let result = String(cString: resultPtr!)
        let mutable = UnsafeMutablePointer<Int8>(mutating: resultPtr!)
        string_destroy(mutable)

        return result
    }

    func removeKeyValue(key: String) throws -> Bool {
        var errorCode: Int32 = -1
        let keyPointer = (key as NSString).utf8String

        let result = withUnsafeMutablePointer(to: &errorCode) {
            error in
            wallet_clear_value(ptr, keyPointer, error)
        }
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        return result
    }

    deinit {
        TariLogger.warn("Wallet destroy")
        wallet_destroy(ptr)
    }
}
