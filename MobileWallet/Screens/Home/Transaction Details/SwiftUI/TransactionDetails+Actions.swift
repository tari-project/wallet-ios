//  TransactionDetails+Actions.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 20.06.2025
	Using Swift 6.0
	Running on macOS 15.5

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

import SwiftUI

extension TransactionDetails {
    var isOutbound: Bool {
        (try? transaction.isOutboundTransaction) ?? false
    }
    
    var hasContact: Bool {
        contact?.isFFIContact == true
    }
    
    var alias: String? {
        contact?.alias
    }
    
    var address: String? {
        guard let addressComponents else { return nil }
        return isEmojiAddress ? addressComponents.fullEmoji : addressComponents.fullRaw
    }
    
    var date: String? {
        guard let timestamp = try? transaction.timestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
            .formattedDisplay()
    }
    
    var minedBlockHeight: UInt64 {
        (try? (transaction as? CompletedTransaction)?.minedBlockHeight) ?? 0
    }
    
    var isConfirmed: Bool {
        requiredConfirmationCount <= confirmationCount
    }
    
    var requiredConfirmationCount: UInt64 {
        5
    }
    
    var confirmationCount: UInt64 {
        guard let paymentReference else { return 0 }
        return UInt64(max(0, Int64(walletBlockHeight) - Int64(paymentReference.blockHeight)))
    }
    
    var transactionMessage: String? {
        guard let message = try? transaction.message else { return nil }
        // If note is "None", show empty string
        return message == "None" ? "" : message.hex()
    }
    
    var status: (String, Color)? {
        if transaction.isCancelled {
            if let transaction = transaction as? CompletedTransaction, let reason = try? transaction.rejectionReason {
                let value = switch reason {
                case .unknown: "The transaction failed for an unknown reason."
                case .userCancelled: "The transaction was canceled by the sender."
                case .timeout: "The transaction failed due to timeout"
                case .doubleSpend: "The transaction was cancelled as it is spending funds that have already been spent."
                case .orphan: "The transaction was cancelled due to some funds being spent no longer being present in the chain."
                case .timeLocked: "This transaction was cancelled due to the funds not having reached their time-lock period yet."
                case .invalidTransaction:
                    "The transaction failed to the invalid input data. This situation shouldn\'t happen. Please send a bug report or contact us directly."
                case .abandonedCoinbase: "The coinbase was abandoned."
                case .notCancelled: "The transaction was not cancelled, but for some reason looks like cancelled. Please, contact us directly if you see this message."
                }
                return (value, .errorMain)
            }
            return ("Payment Cancelled", .errorMain)
        }
        do {
            return switch try transaction.status {
            case .pending: (
                try transaction.isOutboundTransaction
                    ? "Waiting for recipient to come online"
                    : "Waiting for sender to complete transaction",
                .primaryText
            )
            case .broadcast, .completed, .minedUnconfirmed:
                ("In progress", .warningMain)
            default:
                ("Completed", .successMain)
            }
        } catch {
            return nil
        }
    }
    
    func load() {
        title = try? fetchTitle()
        amount = try? fetchAmount()
        addressComponents = try? fetchAddressComponents()
        loadPaymentReference()
        loadTransactionLink()
        Task {
            contact = try? await fetchContact()
        }
    }
    
    func loadPaymentReference() {
        if let reference = try? transactions().paymentReference(transaction: transaction) {
            paymentReference = reference
        }
    }
    
    func copyRawDetails() {
        UIPasteboard.general.string = """
            {
            "id": "\((try? transaction.identifier) ?? 0)",
            "direction": "\(isOutbound ? "OUTBOUND" : "INBOUND")",
            "amount": "\(amount ?? "-")",
            "timestamp": "\((try? transaction.timestamp) ?? 0)",
            "status": "\(status?.0 ?? "-")",
            "paymentID": "\(transactionMessage ?? "-")"
            "confirmationCount": "\(transactionConfirmationCount ?? 0)",
            "minedHeight": "\(walletBlockHeight)"
            }
            """
    }
}

private extension TransactionDetails {
    var transactionConfirmationCount: UInt64? {
        try? (transaction as? CompletedTransaction)?.confirmationCount
    }
    
    func transactions() -> TariTransactionsService {
        Tari.shared.wallet(.main).transactions
    }

    func fetchTitle() throws -> String {
        if transaction.isCancelled {
            localized("tx_detail.payment_cancelled")
        } else if try transaction.isCoinbase {
            "Mining Reward"
        } else {
            isOutbound
                ? localized("tx_detail.payment_sent")
                : localized("tx_detail.payment_received")
        }
    }
    
    func fetchAmount() throws -> String {
        MicroTari(try transaction.amount).formattedPrecise
            + " \(NetworkManager.shared.currencySymbol)"
    }
    
    func fetchAddressComponents() throws -> TariAddressComponents {
        try TariAddressComponents(address: transaction.address)
    }
    
    func fetchContact() async throws -> ContactsManager.Model? {
        let contacts = ContactsManager()
        return try await contacts.contact(for: transaction.address)
    }
    
    func loadTransactionLink() {
        guard let kernel = try? (transaction as? CompletedTransaction)?.transactionKernel,
              let transactionNounce = try? kernel.excessPublicNonceHex,
              let transactionSignature = try? kernel.excessSignatureHex
        else {
            blockExplorerLink = nil
            return
        }
        blockExplorerLink = NetworkManager.shared.selectedNetwork.blockExplorerKernelURL(nounce: transactionNounce, signature: transactionSignature)
    }
}
