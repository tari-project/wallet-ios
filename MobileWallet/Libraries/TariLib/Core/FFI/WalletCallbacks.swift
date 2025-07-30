//  WalletCallbacks.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 13/10/2024
	Using Swift 5.0
	Running on macOS 14.6

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
import Combine

protocol WalletCallbacksReadable: AnyObject {
    var receivedTransaction: AnyPublisher<PendingInboundTransaction, Never> { get }
    var receivedTransactionReply: AnyPublisher<CompletedTransaction, Never> { get }
    var receivedFinalizedTransaction: AnyPublisher<CompletedTransaction, Never> { get }
    var transactionBroadcast: AnyPublisher<CompletedTransaction, Never> { get }
    var transactionMined: AnyPublisher<CompletedTransaction, Never> { get }
    var unconfirmedTransactionMined: AnyPublisher<CompletedTransaction, Never> { get }
    var fauxTransactionConfirmed: AnyPublisher<CompletedTransaction, Never> { get }
    var fauxTransactionUnconfirmed: AnyPublisher<CompletedTransaction, Never> { get }
    var transactionSendResult: AnyPublisher<TransactionSendResult, Never> { get }
    var transactionCancellation: AnyPublisher<CompletedTransaction, Never> { get }
    var balanceUpdate: AnyPublisher<Balance, Never> { get }
    var scannedHeight: AnyPublisher<UInt64, Never> { get }
    var baseNodeState: AnyPublisher<BaseNodeState, Never> { get }

    var walletRecoveryStatus: AnyPublisher<RestoreWalletStatus, Never> { get }
}

final class WalletCallbacks {
    let receivedTransactionSubject = PassthroughSubject<PendingInboundTransaction, Never>()
    let receivedTransactionReplySubject = PassthroughSubject<CompletedTransaction, Never>()
    let receivedFinalizedTransactionSubject = PassthroughSubject<CompletedTransaction, Never>()
    let transactionBroadcastSubject = PassthroughSubject<CompletedTransaction, Never>()
    let transactionMinedSubject = PassthroughSubject<CompletedTransaction, Never>()
    let unconfirmedTransactionMinedSubject = PassthroughSubject<CompletedTransaction, Never>()
    let fauxTransactionConfirmedSubject = PassthroughSubject<CompletedTransaction, Never>()
    let fauxTransactionUnconfirmedSubject = PassthroughSubject<CompletedTransaction, Never>()
    let transactionSendResultSubject = PassthroughSubject<TransactionSendResult, Never>()
    let transactionCancellationSubject = PassthroughSubject<CompletedTransaction, Never>()
    let balanceUpdateSubject = PassthroughSubject<Balance, Never>()
    let scannedHeightSubject = PassthroughSubject<UInt64, Never>()
    let baseNodeStateSubject = PassthroughSubject<BaseNodeState, Never>()

    let walletRecoveryStatusSubject = PassthroughSubject<RestoreWalletStatus, Never>()

    private let callbacksQueue = DispatchQueue(label: "com.tari.events", attributes: [])
}

extension WalletCallbacks: WalletCallbacksReadable {
    var receivedTransaction: AnyPublisher<PendingInboundTransaction, Never> { receivedTransactionSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var receivedTransactionReply: AnyPublisher<CompletedTransaction, Never> { receivedTransactionReplySubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var receivedFinalizedTransaction: AnyPublisher<CompletedTransaction, Never> { receivedFinalizedTransactionSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var transactionBroadcast: AnyPublisher<CompletedTransaction, Never> { transactionBroadcastSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var transactionMined: AnyPublisher<CompletedTransaction, Never> { transactionMinedSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var unconfirmedTransactionMined: AnyPublisher<CompletedTransaction, Never> { unconfirmedTransactionMinedSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var fauxTransactionConfirmed: AnyPublisher<CompletedTransaction, Never> { fauxTransactionConfirmedSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var fauxTransactionUnconfirmed: AnyPublisher<CompletedTransaction, Never> { fauxTransactionUnconfirmedSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var transactionSendResult: AnyPublisher<TransactionSendResult, Never> { transactionSendResultSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var transactionCancellation: AnyPublisher<CompletedTransaction, Never> { transactionCancellationSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var balanceUpdate: AnyPublisher<Balance, Never> { balanceUpdateSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var scannedHeight: AnyPublisher<UInt64, Never> { scannedHeightSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
    var baseNodeState: AnyPublisher<BaseNodeState, Never> { baseNodeStateSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }

    var walletRecoveryStatus: AnyPublisher<RestoreWalletStatus, Never> { walletRecoveryStatusSubject.receive(on: callbacksQueue).eraseToAnyPublisher() }
}

extension UnsafeMutableRawPointer {
    var walletCallbacks: WalletCallbacks { object(type: WalletCallbacks.self) }
}
