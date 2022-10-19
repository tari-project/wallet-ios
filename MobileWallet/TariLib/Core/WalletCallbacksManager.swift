//  WalletCallbacksManager.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 02/10/2022
	Using Swift 5.0
	Running on macOS 12.4

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
import Foundation

final class WalletCallbacksManager {
    
    // MARK: - Wallet Callbacks
    
    let receivedTransaction: AnyPublisher<PendingInboundTransaction, Never> = {
        NotificationCenter.default
            .publisher(for: .receivedTransaction)
            .compactMap { $0.object as? OpaquePointer }
            .map { PendingInboundTransaction(pointer: $0) }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let receivedTransactionReply: AnyPublisher<CompletedTransaction, Never> = {
        NotificationCenter.default
            .publisher(for: .receivedTransactionReply)
            .compactMap { $0.object as? OpaquePointer }
            .map { CompletedTransaction(pointer: $0, isCancelled: false) }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let receivedFinalizedTransaction: AnyPublisher<CompletedTransaction, Never> = {
        NotificationCenter.default
            .publisher(for: .receivedFinalizedTransaction)
            .compactMap { $0.object as? OpaquePointer }
            .map { CompletedTransaction(pointer: $0, isCancelled: false) }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let transactionBroadcast: AnyPublisher<CompletedTransaction, Never> = {
        NotificationCenter.default
            .publisher(for: .transactionBroadcast)
            .compactMap { $0.object as? OpaquePointer }
            .map { CompletedTransaction(pointer: $0, isCancelled: false) }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let transactionMined: AnyPublisher<CompletedTransaction, Never> = {
        NotificationCenter.default
            .publisher(for: .transactionMined)
            .compactMap { $0.object as? OpaquePointer }
            .map { CompletedTransaction(pointer: $0, isCancelled: false) }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let unconfirmedTransactionMined: AnyPublisher<CompletedTransaction, Never> = {
        NotificationCenter.default
            .publisher(for: .unconfirmedTransactionMined)
            .compactMap { $0.object as? OpaquePointer }
            .map { CompletedTransaction(pointer: $0, isCancelled: false) }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let fauxTransactionConfirmed: AnyPublisher<CompletedTransaction, Never> = {
        NotificationCenter.default
            .publisher(for: .fauxTransactionConfirmed)
            .compactMap { $0.object as? OpaquePointer }
            .map { CompletedTransaction(pointer: $0, isCancelled: false) }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let fauxTransactionUnconfirmed: AnyPublisher<CompletedTransaction, Never> = {
        NotificationCenter.default
            .publisher(for: .fauxTransactionUnconfirmed)
            .compactMap { $0.object as? OpaquePointer }
            .map { CompletedTransaction(pointer: $0, isCancelled: false) }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let transactionSendResult: AnyPublisher<TransactionSendResult, Never> = {
        NotificationCenter.default
            .publisher(for: .transactionSendResult)
            .compactMap { $0.object as? TransactionSendResult }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let transactionCancellation: AnyPublisher<CompletedTransaction, Never> = {
        NotificationCenter.default
            .publisher(for: .transactionCancellation)
            .compactMap { $0.object as? OpaquePointer }
            .map { CompletedTransaction(pointer: $0, isCancelled: true) }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let transactionOutputValidation: AnyPublisher<TransactionOutputValidationData, Never> = {
        NotificationCenter.default
            .publisher(for: .transactionOutputValidation)
            .compactMap { $0.object as? TransactionOutputValidationData }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let walletBalanceUpdatePublisher: AnyPublisher<Balance, Never> = {
        NotificationCenter.default
            .publisher(for: .walletBalanceUpdate)
            .compactMap { $0.object as? Balance }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let transactionValidation: AnyPublisher<TransactionValidationData, Never> = {
        NotificationCenter.default
            .publisher(for: .transactionValidation)
            .compactMap { $0.object as? TransactionValidationData }
            .share()
            .eraseToAnyPublisher()
    }()
    
    let baseNodeConnectionStatus: AnyPublisher<BaseNodeConnectivityStatus, Never> = {
        NotificationCenter.default
            .publisher(for: .baseNodeConnectionStatusUpdate)
            .compactMap { $0.object as? BaseNodeConnectivityStatus }
            .share()
            .eraseToAnyPublisher()
    }()
    
    // MARK: - Recovery Callbacks
    
    let walletRecoveryStatusUpdate: AnyPublisher<RestoreWalletStatus, Never> = {
        NotificationCenter.default
            .publisher(for: .walletRecoveryStatusUpdate)
            .compactMap { $0.object as? RestoreWalletStatus }
            .share()
            .eraseToAnyPublisher()
    }()
    
    // MARK: - Properties
    
    static let shared: WalletCallbacksManager = WalletCallbacksManager()
    private let queue = DispatchQueue(label: "com.tari.events", attributes: [])
    
    // MARK: - Initialisers
    
    private init() {}
    
    // MARK: - Actions
    
    func post(name: Notification.Name, object: Any?) {
        queue.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }
}

extension Notification.Name {
    
    // MARK: - Wallet Callbacks
    
    static let receivedTransaction = Self(rawValue: "com.tari.wallet.received_transaction")
    static let receivedTransactionReply = Self(rawValue: "com.tari.wallet.received_transaction_replay")
    static let receivedFinalizedTransaction = Self(rawValue: "com.tari.wallet.received_finalized_transaction")
    static let transactionBroadcast = Self(rawValue: "com.tari.wallet.transaction_broadcast")
    static let transactionMined = Self(rawValue: "com.tari.wallet.transaction_mined")
    static let unconfirmedTransactionMined = Self(rawValue: "com.tari.wallet.unconfirmed_transaction_mined")
    static let fauxTransactionConfirmed = Self(rawValue: "com.tari.wallet.faux_transaction_confirmed")
    static let fauxTransactionUnconfirmed = Self(rawValue: "com.tari.wallet.faux_transaction_unconfirmed")
    static let transactionSendResult = Self(rawValue: "com.tari.wallet.transaction_send_result")
    static let transactionCancellation = Self(rawValue: "com.tari.wallet.transaction_cancellation")
    static let transactionOutputValidation = Self(rawValue: "com.tari.wallet.transaction_output_validation")
    static let walletBalanceUpdate = Self(rawValue: "com.tari.wallet.balance_update")
    static let transactionValidation = Self(rawValue: "com.tari.wallet.transaction_validation")
    static let baseNodeConnectionStatusUpdate = Self(rawValue: "com.tari.wallet.base_node_connection_status_update")
    
    // MARK: - Recovery Callbacks
    
    static let walletRecoveryStatusUpdate = Self(rawValue: "com.tari.recovery.status_update")
}
