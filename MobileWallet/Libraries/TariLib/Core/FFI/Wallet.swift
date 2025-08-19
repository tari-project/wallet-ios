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

    init(
        network: TariNetwork,
        commsConfig: CommsConfig,
        loggingFilePath: String,
        seedWords: SeedWords?,
        passphrase: String?,
        isDnsSecureOn: Bool,
        logVerbosity: Int32,
        isCreatedWallet: Bool,
        callbacks: WalletCallbacks
    ) throws {
        let receivedTransactionCallback: @convention(c) (UnsafeMutableRawPointer?, OpaquePointer?) -> Void = { context, pointer in
            guard let pointer else { return }
            context?.walletCallbacks.receivedTransactionSubject.send(PendingInboundTransaction(pointer: pointer))
        }

        let receivedTransactionReplyCallback: @convention(c) (UnsafeMutableRawPointer?, OpaquePointer?) -> Void = { context, pointer in
            guard let pointer else { return }
            context?.walletCallbacks.receivedTransactionReplySubject.send(CompletedTransaction(pointer: pointer, isCancelled: false))
        }

        let receivedFinalizedTransactionCallback: @convention(c) (UnsafeMutableRawPointer?, OpaquePointer?) -> Void = { context, pointer in
            guard let pointer else { return }
            context?.walletCallbacks.receivedFinalizedTransactionSubject.send(CompletedTransaction(pointer: pointer, isCancelled: false))
        }

        let transactionBroadcastCallback: @convention(c) (UnsafeMutableRawPointer?, OpaquePointer?) -> Void = { context, pointer in
            guard let pointer else { return }
            context?.walletCallbacks.transactionBroadcastSubject.send(CompletedTransaction(pointer: pointer, isCancelled: false))
        }

        let transactionMinedCallback: @convention(c) (UnsafeMutableRawPointer?, OpaquePointer?) -> Void = { context, pointer in
            guard let pointer else { return }
            context?.walletCallbacks.unconfirmedTransactionMinedSubject.send(CompletedTransaction(pointer: pointer, isCancelled: false))
        }

        let unconfirmedTransactionMinedCallback: @convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt64) -> Void = { context, pointer, _ in
            guard let pointer else { return }
            context?.walletCallbacks.unconfirmedTransactionMinedSubject.send(CompletedTransaction(pointer: pointer, isCancelled: false))
        }

        let fauxTransactionConfirmedCallback: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?) -> Void)? = { context, pointer in
            guard let pointer else { return }
            context?.walletCallbacks.fauxTransactionConfirmedSubject.send(CompletedTransaction(pointer: pointer, isCancelled: false))
        }

        let fauxTransactionUnconfirmedCallback: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt64) -> Void)? = { context, pointer, _ in
            guard let pointer else { return }
            context?.walletCallbacks.fauxTransactionUnconfirmedSubject.send(CompletedTransaction(pointer: pointer, isCancelled: false))
        }

        let transactionSendResultCallback: (@convention(c) (UnsafeMutableRawPointer?, UInt64, OpaquePointer?) -> Void) = { context, identifier, pointer in
            guard let pointer, let result = try? TransactionSendResult(identifier: identifier, pointer: pointer) else { return }
            context?.walletCallbacks.transactionSendResultSubject.send(result)
        }

        let transactionCancellationCallback: @convention(c) (UnsafeMutableRawPointer?, OpaquePointer?, UInt64) -> Void = { context, pointer, _ in
            guard let pointer else { return }
            context?.walletCallbacks.transactionCancellationSubject.send(CompletedTransaction(pointer: pointer, isCancelled: true))
        }

        let txoValidationCallback: @convention(c) (UnsafeMutableRawPointer?, UInt64, UInt64) -> Void = { context, identifier, status in
            // TODO: not used anymore, should be removed once FFI is updated
        }

        let contactsLivenessDataUpdatedCallback: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?) -> Void) = { _, _ in
        }

        let balanceUpdatedCallback: @convention(c) (UnsafeMutableRawPointer?, OpaquePointer?) -> Void = { context, pointer in
            guard let pointer else { return }
            context?.walletCallbacks.balanceUpdateSubject.send(Balance(pointer: pointer))
        }

        let trasactionValidationCompleteCallback: @convention(c) (UnsafeMutableRawPointer?, UInt64, UInt64) -> Void = { context, identifier, status in
            // TODO: not used anymore, should be removed once FFI is updated
        }

        let storedMessagesReceivedCallback: (@convention(c) (UnsafeMutableRawPointer?) -> Void) = { _ in
        }

        let connectivityStatusCallback: (@convention(c) (UnsafeMutableRawPointer?, UInt64) -> Void) = { context, status in
            // TODO: not used anymore, should be removed once FFI is updated
        }

        let walletScannedHeightCallback: (@convention(c) (UnsafeMutableRawPointer?, UInt64) -> Void) = { context, scannedHeight in
            context?.walletCallbacks.scannedHeightSubject.send(scannedHeight)
        }

        let baseNodeStateCallback: (@convention(c) (UnsafeMutableRawPointer?, OpaquePointer?) -> Void) = { context, pointer in
            guard let pointer else { return }
            context?.walletCallbacks.baseNodeStateSubject.send(BaseNodeState(pointer: pointer))
        }

        var isRecoveryInProgress = false
        var errorCode: Int32 = -1

        let callbacksPointer = PointerHandler.rawPointer(for: callbacks)
        let isRecoveryInProgressPointer = PointerHandler.pointer(for: &isRecoveryInProgress)
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        
        // On recovery or normal operation this should be like 2 days.
        // But for brand new wallets on first startup this can be set to 0, for immediate sync
        let walletBirthdayOffset: Int32 = isCreatedWallet ? 0 : 2

        Logger.log(message: "Wallet created", domain: .general, level: .info)

        let result = wallet_create(
            callbacksPointer,
            commsConfig.pointer,
            loggingFilePath,
            logVerbosity,
            Self.numberOfRollingLogFiles,
            Self.logFileSize,
            passphrase,
            nil,
            seedWords?.pointer,
            network.name,
            network.dnsPeer,
            nil,
            isDnsSecureOn,
            network.httpBaseNode,
            walletBirthdayOffset,
            receivedTransactionCallback,
            receivedTransactionReplyCallback,
            receivedFinalizedTransactionCallback,
            transactionBroadcastCallback,
            transactionMinedCallback,
            unconfirmedTransactionMinedCallback,
            fauxTransactionConfirmedCallback,
            fauxTransactionUnconfirmedCallback,
            transactionSendResultCallback,
            transactionCancellationCallback,
            txoValidationCallback, // TODO: not used anymore, should be removed once FFI is updated
            contactsLivenessDataUpdatedCallback,
            balanceUpdatedCallback,
            trasactionValidationCompleteCallback, // TODO: not used anymore, should be removed once FFI is updated
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
