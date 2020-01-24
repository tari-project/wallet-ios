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
    case insufficientFunds(microTariRequired: UInt64)
    case addContact
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
        let result = Contacts(contactsPointer: wallet_get_contacts(ptr, UnsafeMutablePointer<Int32>(&errorCode)))
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var completedTransactions: (CompletedTransactions?, Error?) {
        var errorCode: Int32 = -1
        let result = CompletedTransactions(completedTransactionsPointer: wallet_get_completed_transactions(ptr, UnsafeMutablePointer<Int32>(&errorCode)))
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var pendingOutboundTransactions: (PendingOutboundTransactions?, Error?) {
        var errorCode: Int32 = -1
        let result = PendingOutboundTransactions(
            pendingOutboundTransactionsPointer: wallet_get_pending_outbound_transactions(ptr, UnsafeMutablePointer<Int32>(&errorCode))
        )
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var pendingInboundTransactions: (PendingInboundTransactions?, Error?) {
        var errorCode: Int32 = -1
        let result = PendingInboundTransactions(
            pendingInboundTransactionsPointer: wallet_get_pending_inbound_transactions(ptr, UnsafeMutablePointer<Int32>(&errorCode))
        )
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var availableBalance: (UInt64, Error?) {
        var errorCode: Int32 = -1
        let result = wallet_get_available_balance(ptr, UnsafeMutablePointer<Int32>(&errorCode))
        return (result, errorCode != 0 ? WalletErrors.generic(errorCode) : nil)
    }

    var pendingIncomingBalance: (UInt64, Error?) {
        var errorCode: Int32 = -1
        let result = wallet_get_pending_incoming_balance(ptr, UnsafeMutablePointer<Int32>(&errorCode))
        return (result, errorCode != 0 ? WalletErrors.generic(errorCode) : nil)
    }

    var pendingOutgoingBalance: (UInt64, Error?) {
        var errorCode: Int32 = -1
        let result = wallet_get_pending_outgoing_balance(ptr, UnsafeMutablePointer<Int32>(&errorCode))
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

        return (MicroTari(availableBalance + pendingIncomingBalance - pendingOutgoingBalance), nil)
    }

    var publicKey: (PublicKey?, Error?) {
        var errorCode: Int32 = -1
        let result = PublicKey(pointer: wallet_get_public_key(ptr, UnsafeMutablePointer<Int32>(&errorCode)))
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }

        return (result, nil)
    }

    init(commsConfig: CommsConfig, loggingFilePath: String) throws {
        let loggingFilePathPointer = UnsafeMutablePointer<Int8>(mutating: (loggingFilePath as NSString).utf8String)!

        let receivedTransactionCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let pendingInbound = PendingInboundTransaction.init(pendingInboundTransactionPointer: valuePointer!)
            TariEventBus.postToMainThread(.receievedTransaction, sender: pendingInbound)
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            print("receivedTransactionCallback")
        }

        let receivedTransactionReplyCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTransaction.init(completedTransactionPointer: valuePointer!)
            TariEventBus.postToMainThread(.receievedTransactionReply, sender: completed)
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            print("receivedTransactionReply")
        }

        let receivedFinalizedTransactionCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTransaction.init(completedTransactionPointer: valuePointer!)
            TariEventBus.postToMainThread(.receivedFinalizedTransaction, sender: completed)
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            print("receivedFinalizedTransaction")
        }

        let transactionBroadcastCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTransaction.init(completedTransactionPointer: valuePointer!)
            TariEventBus.postToMainThread(.transactionBroadcast, sender: completed)
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            print("transactionBroadcast")
        }

        let transactionMinedCallback: (@convention(c) (OpaquePointer?) -> Void)? = {
            valuePointer in
            let completed = CompletedTransaction.init(completedTransactionPointer: valuePointer!)
            TariEventBus.postToMainThread(.transactionMined, sender: completed)
            TariEventBus.postToMainThread(.transactionListUpdate)
            TariEventBus.postToMainThread(.balanceUpdate)
            print("callbackTransactionMined")
        }

        let discoveryProcessCompleteCallback: (@convention(c) (UInt64, Bool) -> Void)? = { txID, success in
            print("discoveryProcessCompleteCallback: \(txID) Success: \(success)")
        }

        dbPath = commsConfig.dbPath
        dbName = commsConfig.dbName
        logPath = loggingFilePath

        var errorCode: Int32 = -1
        let result = wallet_create(
            commsConfig.pointer,
            loggingFilePathPointer,
            receivedTransactionCallback,
            receivedTransactionReplyCallback,
            receivedFinalizedTransactionCallback,
            transactionBroadcastCallback,
            transactionMinedCallback,
            discoveryProcessCompleteCallback,
            UnsafeMutablePointer<Int32>(&errorCode)
        )
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        ptr = result!
    }

    func removeContact(_ contact: Contact) throws {
        var errorCode: Int32 = -1
        let result = wallet_remove_contact(ptr, contact.pointer, UnsafeMutablePointer<Int32>(&errorCode))
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        if !result {
            throw WalletErrors.removeContact
        }
    }

    func addContact(alias: String, publicKeyHex: String) throws {
        let publicKey = try PublicKey(hex: publicKeyHex)
        let (currentWalletPublicKey, publicKeyError) = self.publicKey
        if publicKeyError != nil {
            throw publicKeyError!
        }

        let (currentWalletPublicKeyHex, currentWalletPublicKeyHexError) = currentWalletPublicKey!.hex
        if currentWalletPublicKeyHexError != nil {
            throw currentWalletPublicKeyHexError!
        }

        if (publicKeyHex == currentWalletPublicKeyHex) {
            throw WalletErrors.addOwnContact
        }

        let newContact = try Contact(alias: alias, publicKey: publicKey)
        var errorCode: Int32 = -1
        let contactAdded = wallet_add_contact(ptr, newContact.pointer, UnsafeMutablePointer<Int32>(&errorCode))

        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        if !contactAdded {
            throw WalletErrors.addContact
        }
    }

    func sendTransaction(destination: PublicKey, amount: UInt64, fee: UInt64, message: String) throws {
        let total = fee + amount
        let (availableBalance, error) = self.availableBalance
        if error != nil {
            throw error!
        }

        if total > availableBalance {
            throw WalletErrors.insufficientFunds(microTariRequired: total)
        }

        let messagePointer = UnsafeMutablePointer<Int8>(mutating: (message as NSString).utf8String)
        var errorCode: Int32 = -1
        let sendResult = wallet_send_transaction(ptr, destination.pointer, amount, fee, messagePointer, UnsafeMutablePointer<Int32>(&errorCode))
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        if !sendResult {
            throw WalletErrors.sendingTransaction
        }
    }

    func findPendingOutboundTransactionBy(id: UInt64) throws -> PendingOutboundTransaction? {
        var errorCode: Int32 = -1
        let pendingOutboundTransactionPointer = wallet_get_pending_outbound_transaction_by_id(ptr, id, UnsafeMutablePointer<Int32>(&errorCode))
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
         let pendingInboundTransactionPointer = wallet_get_pending_inbound_transaction_by_id(ptr, id, UnsafeMutablePointer<Int32>(&errorCode))
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
        let completedTransactionPointer = wallet_get_completed_transaction_by_id(ptr, id, UnsafeMutablePointer<Int32>(&errorCode))
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
        let result = wallet_is_completed_transaction_outbound(ptr, tx.pointer, UnsafeMutablePointer<Int32>(&errorCode))
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        
        return result
    }

    deinit {
        wallet_destroy(ptr)
    }
}
