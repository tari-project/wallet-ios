//  Wallet.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 09/11/2021
	Using Swift 5.0
	Running on macOS 12.0

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

final class Wallet {

    // MARK: - Constants

    private static let numberOfRollingLogFiles: UInt32 = 2
    private static let logFileSize: UInt32 = 10 * 1024 * 1024
    private static let isRecoveryInProgress: Bool = false

    // MARK: - Properties

    let pointer: OpaquePointer

    // MARK: - Initialisers

    init(commsConfig: CommsConfig, loggingFilePath: String, seedWords: SeedWords?, passphrase: String?, networkName: String, dnsPeer: String, isDnsSecureOn: Bool, logVerbosity: Int32) throws {

        let receivedTransactionCallback: @convention(c) (OpaquePointer?) -> Void = { pointer in
            WalletCallbacksManager.shared.post(name: .receivedTransaction, object: pointer)
        }

        let receivedTransactionReplyCallback: @convention(c) (OpaquePointer?) -> Void = { pointer in
            WalletCallbacksManager.shared.post(name: .receivedTransactionReply, object: pointer)
        }

        let receivedFinalizedTransactionCallback: @convention(c) (OpaquePointer?) -> Void = { pointer in
            WalletCallbacksManager.shared.post(name: .receivedFinalizedTransaction, object: pointer)
        }

        let fauxTransactionConfirmedCallback: (@convention(c) (OpaquePointer?) -> Void)? = { pointer in
            WalletCallbacksManager.shared.post(name: .fauxTransactionConfirmed, object: pointer)
        }

        let fauxTransactionUncorfirmedCallback: (@convention(c) (OpaquePointer?, UInt64) -> Void)? = { pointer, _ in
            WalletCallbacksManager.shared.post(name: .fauxTransactionUnconfirmed, object: pointer)
        }

        let transactionSendResultCallback: (@convention(c) (UInt64, OpaquePointer?) -> Void) = { identifier, pointer in
            guard let pointer, let data = try? TransactionSendResult(identifier: identifier, pointer: pointer) else { return }
            WalletCallbacksManager.shared.post(name: .transactionSendResult, object: data)
        }

        let transactionBroadcastCallback: @convention(c) (OpaquePointer?) -> Void = { pointer in
            WalletCallbacksManager.shared.post(name: .transactionBroadcast, object: pointer)
        }

        let transactionMinedCallback: @convention(c) (OpaquePointer?) -> Void = { pointer in
            WalletCallbacksManager.shared.post(name: .transactionMined, object: pointer)
        }

        let unconfirmedTransactionMinedCallback: @convention(c) (OpaquePointer?, UInt64) -> Void = { pointer, _ in
            WalletCallbacksManager.shared.post(name: .unconfirmedTransactionMined, object: pointer)
        }

        let transactionCancellationCallback: @convention(c) (OpaquePointer?, UInt64) -> Void = { pointer, _ in
            WalletCallbacksManager.shared.post(name: .transactionCancellation, object: pointer)
        }

        let txoValidationCallback: @convention(c) (UInt64, UInt64) -> Void = { responseId, status in
            guard let status = TransactionValidationStatus(rawValue: status) else { return }
            WalletCallbacksManager.shared.post(name: .transactionOutputValidation, object: TransactionValidationData(identifier: responseId, status: status))
        }

        let contactsLivenessDataUpdatedCallback: (@convention(c) (OpaquePointer?) -> Void) = { _ in
        }

        let balanceUpdatedCallback: @convention(c) (OpaquePointer?) -> Void = { pointer in
            WalletCallbacksManager.shared.post(name: .walletBalanceUpdate, object: pointer)
        }

        let trasactionValidationCompleteCallback: @convention(c) (UInt64, UInt64) -> Void = { responseId, status in
            guard let status = TransactionValidationStatus(rawValue: status) else { return }
            WalletCallbacksManager.shared.post(name: .transactionValidation, object: TransactionValidationData(identifier: responseId, status: status))
        }

        let storedMessagesReceivedCallback: (@convention(c) () -> Void) = {
        }

        let connectivityStatusCallback: (@convention(c) (UInt64) -> Void) = { status in
            WalletCallbacksManager.shared.post(name: .baseNodeConnectionStatusUpdate, object: status)
        }

        let walletScannedHeightCallback: (@convention(c) (UInt64) -> Void) = {
            WalletCallbacksManager.shared.post(name: .walletScannedHeight, object: $0)
        }

        let baseNodeStateCallback: (@convention(c) (OpaquePointer?) -> Void) = { pointer in
            WalletCallbacksManager.shared.post(name: .baseNodeStateUpdate, object: pointer)
        }

        var isRecoveryInProgress = false
        var errorCode: Int32 = -1

        let isRecoveryInProgressPointer = PointerHandler.pointer(for: &isRecoveryInProgress)
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        Logger.log(message: "Wallet created", domain: .general, level: .info)

        let result = wallet_create(
            commsConfig.pointer,
            loggingFilePath,
            logVerbosity,
            Self.numberOfRollingLogFiles,
            Self.logFileSize,
            passphrase,
            seedWords?.pointer,
            networkName,
            dnsPeer,
            isDnsSecureOn,
            receivedTransactionCallback,
            receivedTransactionReplyCallback,
            receivedFinalizedTransactionCallback,
            transactionBroadcastCallback,
            transactionMinedCallback,
            unconfirmedTransactionMinedCallback,
            fauxTransactionConfirmedCallback,
            fauxTransactionUncorfirmedCallback,
            transactionSendResultCallback,
            transactionCancellationCallback,
            txoValidationCallback,
            contactsLivenessDataUpdatedCallback,
            balanceUpdatedCallback,
            trasactionValidationCompleteCallback,
            storedMessagesReceivedCallback,
            connectivityStatusCallback,
            walletScannedHeightCallback,
            baseNodeStateCallback,
            isRecoveryInProgressPointer,
            errorCodePointer
        )

        guard errorCode == 0, let result else { throw WalletError(code: errorCode) }
        pointer = result
    }

    // MARK: - Deinitialiser

    func destroy() {
        wallet_destroy(pointer)
        Logger.log(message: "Wallet destroyed", domain: .general, level: .info)
    }
}
