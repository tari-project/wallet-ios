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
    case generateTestReceiveTransaction
    case sendingTransaction
    case testTransactionBroadcast
    case testTransactionMined
    case testSendCompleteTransaction
    case completedTransactionById
    case walletNotInitialized
    case invalidSignatureAndNonceString
    case cancelNonPendingTransaction
    case transactionsToCancel
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

    var completedTransactions: (CompletedTransactions?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            CompletedTransactions(completedTransactionsPointer: wallet_get_completed_transactions(ptr, error))

        })
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var pendingOutboundTransactions: (PendingOutboundTransactions?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            PendingOutboundTransactions(
            pendingOutboundTransactionsPointer: wallet_get_pending_outbound_transactions(ptr, error))

        })
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var pendingInboundTransactions: (PendingInboundTransactions?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            PendingInboundTransactions(
            pendingInboundTransactionsPointer: wallet_get_pending_inbound_transactions(ptr, error))

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

        let (pendingOutgoingBalance, pendingOutgoingBalanceError) = self.pendingOutgoingBalance
        if pendingOutgoingBalanceError != nil {
            return (nil, pendingOutgoingBalanceError)
        }

        TariLogger.verbose("\n🤑availableBalance: \(availableBalance)\n🤑pendingIncomingBalance: \(pendingIncomingBalance)\n🤑pendingOutgoingBalance: \(pendingOutgoingBalance)")

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

        let receivedTransactionCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let pendingInbound = PendingInboundTransaction(pendingInboundTransactionPointer: valuePointer!)
            TariEventBus.postToMainThread(.receievedTransaction, sender: pendingInbound)
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Receive transaction lib callback")
        }

        let receivedTransactionReplyCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTransaction(completedTransactionPointer: valuePointer!)
            TariEventBus.postToMainThread(.receievedTransactionReply, sender: completed)
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Receive transaction reply lib callback")
        }

        let receivedFinalizedTransactionCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTransaction(completedTransactionPointer: valuePointer!)
            TariEventBus.postToMainThread(.receivedFinalizedTransaction, sender: completed)
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Receive finalized transaction lib callback")
        }

        let transactionBroadcastCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTransaction(completedTransactionPointer: valuePointer!)
            TariEventBus.postToMainThread(.transactionBroadcast, sender: completed)
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Transaction broadcast lib callback")
        }

        let transactionMinedCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTransaction(completedTransactionPointer: valuePointer!)
            TariEventBus.postToMainThread(.transactionMined, sender: completed)
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Transaction mined lib callback")
        }

        let directSendResultCallback: (@convention(c) (UInt64, Bool) -> Void)? = { txID, success in
            TariEventBus.postToMainThread(.directSend, sender: CallbackTxResult(id: txID, success: success))
            let message = "Direct send lib callback. txID=\(txID)"
            if success {
                TariLogger.verbose("\(message) ✅")
            } else {
                TariLogger.error("\(message) failure")
            }
        }

        let storeAndForwardSendResultCallback: (@convention(c) (UInt64, Bool) -> Void)? = { txID, success in
            TariEventBus.postToMainThread(.storeAndForwardSend, sender: CallbackTxResult(id: txID, success: success))
            let message = "Store and forward lib callback. txID=\(txID)"
            if success {
                TariLogger.verbose("\(message) ✅")
            } else {
                TariLogger.error("\(message) failure")
            }
        }

        let transactionCancellationCallback: (@convention(c) (UInt64) -> Void)? = { txID in
            TariEventBus.postToMainThread(.storeAndForwardSend, sender: CallbackTxResult(id: txID, success: true))
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            TariLogger.verbose("Transaction cancelled callback. txID=\(txID) ✅")
        }

        let baseNodeSyncCompleteCallback: (@convention(c) (UInt64, Bool) -> Void)? = { requestID, success in
            TariEventBus.postToMainThread(.baseNodeSyncComplete, sender: success)
            let message = "Base node sync lib callback. requestID=\(requestID)"
            if success {
                TariLogger.verbose("\(message) ✅")
            } else {
                TariLogger.error("\(message) failure")
            }
        }

        dbPath = commsConfig.dbPath
        dbName = commsConfig.dbName
        logPath = loggingFilePath

        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_create(
            commsConfig.pointer,
            loggingFilePathPointer,
            receivedTransactionCallback,
            receivedTransactionReplyCallback,
            receivedFinalizedTransactionCallback,
            transactionBroadcastCallback,
            transactionMinedCallback,
            directSendResultCallback,
            storeAndForwardSendResultCallback,
            transactionCancellationCallback,
            baseNodeSyncCompleteCallback,
            error)}
        )
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        ptr = result!
    }

    func logMessage(message: String) {
        message.withCString({ cstr in
            log_debug_message(cstr)
            })
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

        TariEventBus.postToMainThread(.transactionListUpdate)
    }

    func calculateTransactionFee(_ amount: MicroTari) -> MicroTari {
        //TODO when preflight function is ready, use that instead of assuming inputs and outputs

        let baseCost: UInt64 = 500
        let numInputs: UInt64 = 3
        let numOutputs: UInt64 = 2
        let r: UInt64 = 250

        let fee = baseCost + (numInputs + 4 * numOutputs) * r

        return MicroTari(fee)
    }

    func sendTransaction(destination: PublicKey, amount: MicroTari, fee: MicroTari, message: String) throws -> UInt64 {
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
            throw WalletErrors.sendingTransaction
        }

        return txId
    }

    func findPendingOutboundTransactionBy(id: UInt64) throws -> PendingOutboundTransaction? {
        var errorCode: Int32 = -1
        let pendingOutboundTransactionPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_pending_outbound_transaction_by_id(ptr, id, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        if let txPointer = pendingOutboundTransactionPointer {
            return PendingOutboundTransaction(pendingOutboundTransactionPointer: txPointer)
        }
        return nil
    }

    func findPendingInboundTransactionBy(id: UInt64) throws -> PendingInboundTransaction? {
         var errorCode: Int32 = -1
         let pendingInboundTransactionPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_pending_inbound_transaction_by_id(ptr, id, error)})
         guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
         }
         if let txPointer = pendingInboundTransactionPointer {
             return PendingInboundTransaction(pendingInboundTransactionPointer: txPointer)
         }
         return nil
     }

    func findCompletedTransactionBy(id: UInt64) throws -> CompletedTransaction {
        var errorCode: Int32 = -1
        let completedTransactionPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_get_completed_transaction_by_id(ptr, id, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        guard completedTransactionPointer != nil else {
            throw WalletErrors.completedTransactionById
        }

        return CompletedTransaction(completedTransactionPointer: completedTransactionPointer!)
    }

    func isCompletedTransactionOutbound(tx: CompletedTransaction) throws -> Bool {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_is_completed_transaction_outbound(ptr, tx.pointer, error)})
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        return result
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

        TariEventBus.postToMainThread(.balanceUpdate)
        TariEventBus.postToMainThread(.transactionListUpdate)

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

    func syncBaseNode() throws {
        var errorCode: Int32 = -1
        _ = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_sync_with_base_node(ptr, error)})

        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
    }

    /// Cancel all pending transactions after a certain amount of time has passed.
    /// - Parameter after: Amount of time after a transaction was created
    func cancelExpiredPendingTransactions(after: TimeInterval = TariSettings.shared.expirePendingTransactionsAfter) throws {
        guard let outboundList = pendingOutboundTransactions.0?.list.0, let inboundList = pendingInboundTransactions.0?.list.0 else {
            throw WalletErrors.transactionsToCancel
        }

        let list: [TransactionProtocol] = outboundList + inboundList

        try list.forEach({ (tx) in
            guard tx.status.0 == .pending, let date = tx.date.0 else {
                return
            }

            if date.distance(to: Date()) > after {
                try cancelPendingTransaction(tx)
            }
        })
    }

    /// Cancels a transaction that's currently pending.
    /// Helpful for expiring transactions where the other party has failed to sign their part after a certain amount of time.
    /// - Parameter tx: Pending transaction to be cancelled
    func cancelPendingTransaction(_ tx: TransactionProtocol) throws {
        guard tx.status.0 == .pending else {
            throw WalletErrors.cancelNonPendingTransaction
        }

        try cancelPendingTransaction(tx.id.0)
    }

    /// Cancels a transaction that's currently pending.
    /// Helpful for expiring transactions where the other party has failed to sign their part after a certain amount of time.
    /// - Parameter txId: ID of pending incoming or outgoing transaction
    private func cancelPendingTransaction(_ txId: UInt64) throws {
        var errorCode: Int32 = -1
        _ = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_cancel_pending_transaction(ptr, txId, error)
        })

        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
    }

    deinit {
        wallet_destroy(ptr)
    }
}
