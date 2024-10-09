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
import UIKit

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
    @Published private(set) var scannedHeight: UInt64 = 0

    @Published private(set) var isWalletConnected: Bool = false {
        didSet { Logger.log(message: "isWalletConnected: \(isWalletConnected)", domain: .general, level: .info) }
    }

    private var wallet: Wallet? {
        didSet { isWalletConnected = wallet != nil }
    }

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

        WalletCallbacksManager.shared.walletScannedHeight
            .assign(to: \.scannedHeight, on: self)
            .store(in: &cancelables)
    }

    // MARK: - Actions

    func connectWallet(commsConfig: CommsConfig, logFilePath: String, seedWords: SeedWords?, passphrase: String?, networkName: String, dnsPeer: String, isDnsSecureOn: Bool, logVerbosity: Int32) throws {
        do {
            let beforeWalletCreationDate = Date()
            Logger.log(message: "Wallet will be created", domain: .general, level: .info)
            wallet = try Wallet(
                commsConfig: commsConfig,
                loggingFilePath: logFilePath,
                seedWords: seedWords,
                passphrase: passphrase,
                networkName: networkName,
                dnsPeer: dnsPeer,
                isDnsSecureOn: isDnsSecureOn,
                logVerbosity: logVerbosity
            )
            Logger.log(message: "Wallet created after \(-beforeWalletCreationDate.timeIntervalSinceNow) seconds", domain: .general, level: .info)
        } catch {
            Logger.log(message: "Wallet wasn't created: \(error)", domain: .general, level: .info)
            destroyWallet()
            throw error
        }
    }

    func disconnectWallet() {
        let taskID = UIApplication.shared.beginBackgroundTask()
        Logger.log(message: "disconnectWallet Start: \(taskID)", domain: .general, level: .info)
        destroyWallet()
        baseNodeConnectionStatus = .offline
        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
            Logger.log(message: "disconnectWallet: End: \(taskID)", domain: .general, level: .info)
            UIApplication.shared.endBackgroundTask(taskID)
        }
    }

    private func destroyWallet() {
        guard let wallet else { return }
        let beforeWalletDestroyDate = Date()
        Logger.log(message: "Wallet will be destroyed", domain: .general, level: .info)
        wallet.destroy()
        Logger.log(message: "Wallet destroyed after \(-beforeWalletDestroyDate.timeIntervalSinceNow) seconds", domain: .general, level: .info)
        self.wallet = nil
    }

    // MARK: - FFI Actions

    func walletAddress() throws -> TariAddress {
        let wallet = try exisingWallet
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_tari_interactive_address(wallet.pointer, errorCodePointer)
        guard errorCode == 0, let result else { throw WalletError(code: errorCode) }
        return TariAddress(pointer: result)
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

    func remove(contact: Contact) throws -> Bool {

        let wallet = try exisingWallet

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_remove_contact(wallet.pointer, contact.pointer, errorCodePointer)

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

    func feeEstimate(amount: UInt64, feePerGram: UInt64, kernelsCount: UInt32, outputsCount: UInt32) throws -> UInt64 {

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

    func set(baseNodePeer: PublicKey, address: String?) throws -> Bool {

        let wallet = try exisingWallet

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_set_base_node_peer(wallet.pointer, baseNodePeer.pointer, address, errorCodePointer)

        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }

    func seedPeers() throws -> PublicKeys {

        let wallet = try exisingWallet

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_seed_peers(wallet.pointer, errorCodePointer)

        guard errorCode == 0, let result else { throw WalletError(code: errorCode) }
        return PublicKeys(pointer: result)
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

    func sendTransaction(address: TariAddress, amount: UInt64, feePerGram: UInt64, message: String, isOneSidedPayment: Bool, paymentID: String) throws -> UInt64 {

        let wallet = try exisingWallet

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_send_transaction(wallet.pointer, address.pointer, amount, nil, feePerGram, message, isOneSidedPayment, paymentID, errorCodePointer)

        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }

    func startRecovery(baseNodePublicKey: PublicKey, recoveredOutputMessage: String) throws -> Bool {

        let wallet = try exisingWallet

        let callback: @convention(c) (UnsafeMutableRawPointer?, UInt8, UInt64, UInt64) -> Void = {
            let status = RestoreWalletStatus(status: $1, firstValue: $2, secondValue: $3)
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

    func walletVersion(commsConfig: CommsConfig) throws -> String? {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_last_version(commsConfig.pointer, errorCodePointer)
        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        guard let result else { return nil }
        return String(cString: result)
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

    func log(message: String) throws {

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        log_debug_message(message, errorCodePointer)

        guard errorCode == 0 else { throw WalletError(code: errorCode) }
    }

    func unspentOutputs() throws -> UnblindedOutputs {

        let wallet = try exisingWallet

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let result = wallet_get_unspent_outputs(wallet.pointer, errorCodePointer)

        guard let result else { throw WalletError(code: errorCode) }
        return UnblindedOutputs(pointer: result)
    }

    func importExternalUtxoAnNonRewindable(output: UnblindedOutput, sourceAddress: TariAddress, message: String) throws -> UInt64 {

        let wallet = try exisingWallet

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let result = wallet_import_external_utxo_as_non_rewindable(wallet.pointer, output.pointer, sourceAddress.pointer, message, errorCodePointer)

        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        return result
    }
}
