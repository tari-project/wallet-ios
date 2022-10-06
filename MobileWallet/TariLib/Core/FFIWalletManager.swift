//  FFIWalletManager.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 07/01/2022
	Using Swift 5.0
	Running on macOS 12.1

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

import Combine

final class FFIWalletManager {
    
    private enum BaseNodeValidationType: String {
        case txo
        case tx
    }
    
    enum GeneralError: Error {
        case unableToCreateWallet
    }
    
    // MARK: - Properties
    
    @Published private(set) var baseNodeConnectionStatus: BaseNodeConnectivityStatus = .offline
    
    var isWalletConnected: Bool { wallet != nil }
    
    private var wallet: Wallet?
    
    private var exisingWallet: Wallet {
        get throws {
            guard let wallet = wallet else { throw GeneralError.unableToCreateWallet }
            return wallet
        }
    }
    
    private var cancelables = Set<AnyCancellable>()
    
    // MARK: - Initialisers
    
    init() {
        setupCallbacks()
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        WalletCallbacksManager.shared.baseNodeConnectionStatus
            .assign(to: \.baseNodeConnectionStatus, on: self)
            .store(in: &cancelables)
    }
    
    // MARK: - Actions
    
    func connectWallet(commsConfig: CommsConfig, logFilePath: String, seedWords: SeedWords?, passphrase: String?, networkName: String) throws {
        do {
            wallet = try Wallet(commsConfig: commsConfig, loggingFilePath: logFilePath, seedWords: seedWords, passphrase: passphrase, networkName: networkName)
        } catch {
            wallet = nil
            throw error
        }
    }
    
    func disconnectWallet() {
        wallet = nil
        baseNodeConnectionStatus = .offline
    }
    
    // MARK: - FFI Actions
    
    func walletPublicKey() throws -> PublicKey {
        let wallet = try exisingWallet
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        guard let result = wallet_get_public_key(wallet.pointer, errorCodePointer) else { throw WalletError(code: errorCode) }
        return PublicKey(pointer: result)
    }
    
    func walletContacts() throws -> Contacts {
        let wallet = try exisingWallet
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_contacts(wallet.pointer, errorCodePointer)
        guard let result = result else { throw WalletError(code: errorCode) }
        return Contacts(pointer: result)
    }
    
    func balance() throws -> Balance {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_balance(wallet.pointer, errorCodePointer)
    
        guard errorCode == 0, let result = result else { throw WalletError(code: errorCode) }
        return Balance(pointer: result)
    }
    
    func completedTransactions() throws -> CompletedTransactions {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_completed_transactions(wallet.pointer, errorCodePointer)
        
        guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
        return CompletedTransactions(pointer: pointer)
    }
    
    func cancelledTransactions() throws -> CompletedTransactions {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_cancelled_transactions(wallet.pointer, errorCodePointer)
        
        guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
        return CompletedTransactions(pointer: pointer)
    }
    
    func pendingInboundTransactions() throws -> PendingInboundTransactions {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_pending_inbound_transactions(wallet.pointer, errorCodePointer)
        
        guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
        return PendingInboundTransactions(pointer: pointer)
    }
    
    func pendingOutboundTransactions() throws -> PendingOutboundTransactions {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_pending_outbound_transactions(wallet.pointer, errorCodePointer)
        
        guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
        return PendingOutboundTransactions(pointer: pointer)
    }
    
    func cancelPendingTransaction(identifier: UInt64) throws -> Bool {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_cancel_pending_transaction(wallet.pointer, identifier, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func upsert(contact: Contact) throws -> Bool {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_upsert_contact(wallet.pointer, contact.pointer, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func startTransactionOutputValidation() throws -> UInt64 {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_start_txo_validation(wallet.pointer, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func startTransactionValidation() throws -> UInt64 {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_start_transaction_validation(wallet.pointer, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func feeEstimate(amount: UInt64, feePerGram: UInt64, kernelsCount: UInt64, outputsCount: UInt64) throws -> UInt64 {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_fee_estimate(wallet.pointer, amount, nil, feePerGram, kernelsCount, outputsCount, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func feePerGramStats(count: UInt32) throws -> TariFeePerGramStats {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_fee_per_gram_stats(wallet.pointer, count, errorCodePointer)
        
        guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
        return TariFeePerGramStats(pointer: pointer)
    }
    
    func addBaseNodePeer(publicKeyPointer: OpaquePointer, address: String) throws -> Bool {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_add_base_node_peer(wallet.pointer, publicKeyPointer, address, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func utxos() throws -> [TariUtxo] {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        
        let result = wallet_get_all_utxos(wallet.pointer, errorCodePointer)
        
        guard errorCode == 0, let result = result else { throw WalletError(code: errorCode) }
        return result.array()
    }
    
    func coinSplitPreview(commitments: [String], splitsCount: UInt, feePerGram: UInt64) throws -> TariCoinPreview {
        
        let wallet = try exisingWallet

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let vector = TariVectorWrapper(type: TariTypeTag(0))
        try vector.add(commitments: commitments)

        let result = wallet_preview_coin_split(wallet.pointer, vector.pointer, splitsCount, feePerGram, errorCodePointer)

        guard errorCode == 0, let result = result else { throw WalletError(code: errorCode) }
        return result.pointee
    }

    func coinsJoinPreview(commitments: [String], feePerGram: UInt64) throws -> TariCoinPreview {
        
        let wallet = try exisingWallet

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let vector = TariVectorWrapper(type: TariTypeTag(0))
        try vector.add(commitments: commitments)

        let result = wallet_preview_coin_join(wallet.pointer, vector.pointer, feePerGram, errorCodePointer)

        guard errorCode == 0, let result = result else { throw WalletError(code: errorCode) }
        return result.pointee
    }
    
    func sendTransaction(publicKey: PublicKey, amount: UInt64, feePerGram: UInt64, message: String, isOneSidedPayment: Bool) throws -> UInt64 {
        
        let wallet = try exisingWallet

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_send_transaction(wallet.pointer, publicKey.pointer, amount, nil, feePerGram, message, isOneSidedPayment, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func startRecovery(baseNodePublicKey: PublicKey, recoveredOutputMessage: String) throws -> Bool {
        
        let wallet = try exisingWallet
        
        let callback: @convention(c) (UInt8, UInt64, UInt64) -> Void = {
            let status = RestoreWalletStatus(status: $0, firstValue: $1, secondValue: $2)
            WalletCallbacksManager.shared.post(name: .walletRecoveryStatusUpdate, object: status)
        }
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        
        let result = wallet_start_recovery(wallet.pointer, baseNodePublicKey.pointer, callback, recoveredOutputMessage, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func sign(message: String) throws -> String {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        
        let result = wallet_sign_message(wallet.pointer, message, errorCodePointer)
        defer { string_destroy(result) }
        
        guard errorCode == 0, let cString = result else { throw WalletError(code: errorCode) }
        
        return String(cString: cString)
    }
    
    func importExternalUtxoAsNonRewindable(amount: UInt64, spendingKey: PrivateKey, sourcePublicKey: PublicKey, metadataSignaturePointer: OpaquePointer, senderOffsetPublicKey: PublicKey, scriptPrivateKey: PrivateKey, message: String) throws -> UInt64 {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        
        let result = wallet_import_external_utxo_as_non_rewindable(
            wallet.pointer,
            amount,
            spendingKey.pointer,
            sourcePublicKey.pointer,
            nil,
            metadataSignaturePointer,
            senderOffsetPublicKey.pointer,
            scriptPrivateKey.pointer,
            nil,
            nil,
            0,
            message,
            errorCodePointer
        )
     
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func commitmentSignatureCreateFromBytes(publicNonceBytes: ByteVector, uBytes: ByteVector, vBytes: ByteVector) throws -> OpaquePointer {
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        
        let result = commitment_signature_create_from_bytes(publicNonceBytes.pointer, uBytes.pointer, vBytes.pointer, errorCodePointer)
        
        guard errorCode == 0, let pointer = result else { throw WalletError(code: errorCode) }
        return pointer
    }
    
    func applyEncryption(passphrase: String) throws {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        
        wallet_apply_encryption(wallet.pointer, passphrase, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
    }
    
    func removeEncryption() throws {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        
        wallet_remove_encryption(wallet.pointer, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
    }
    
    func requiredConfirmationsCount() throws -> UInt64 {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        
        let result = wallet_get_num_confirmations_required(wallet.pointer, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func set(key: String, value: String) throws -> Bool {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_set_key_value(wallet.pointer, key, value, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func clear(key: String) throws -> Bool {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_clear_value(wallet.pointer, key, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func value(key: String) throws -> String {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_value(wallet.pointer, key, errorCodePointer)
        
        guard errorCode == 0, let cString = result else { throw WalletError(code: errorCode) }
        return String(cString: cString)
        
    }
    
    func seedWords() throws -> SeedWords {
        let wallet = try exisingWallet
        return try SeedWords(walletPointer: wallet.pointer)
    }
    
    func coinSplit(commitments: TariVectorWrapper, splitsCount: UInt, feePerGram: UInt64) throws -> UInt64 {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_coin_split(wallet.pointer, commitments.pointer, splitsCount, feePerGram, errorCodePointer)

        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func coinJoin(commitments: TariVectorWrapper, feePerGram: UInt64) throws -> UInt64 {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_coin_join(wallet.pointer, commitments.pointer, feePerGram, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
    
    func restartTransactionBroadcast() throws -> Bool {
        
        let wallet = try exisingWallet
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_restart_transaction_broadcast(wallet.pointer, errorCodePointer)
        
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
}
