//  SwapProgress.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 29.10.2025
	Using Swift 6.0
	Running on macOS 26.0

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

struct SwapProgress: View {
    @CodableStorage("swapTransactions", defaultValue: SwapTransactionList()) var swapTransactions
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @Environment(SheetRouter.self) var router
    @State var exolix = Exolix.shared
    
    let initialTransaction: ExolixTransactionResponse
    
    var transaction: ExolixTransactionResponse {
        latestTransaction(id: initialTransaction.id) ?? initialTransaction
    }
    
    init(transaction: ExolixTransactionResponse) {
        self.initialTransaction = transaction
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                processingInfo
                if (transaction.status == .wait && transaction.coinFrom.coinCode != "XTM") || transaction.status == .overdue {
                    TariButton("Cancel transaction", style: .destructiveText, size: .medium) {
                        cancelTransaction()
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
        }
        .background(Color.secondaryBackground)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarTitle("Exchange status")
            toolbarBackItem {
                router.isSwapPresented = false
                dismiss()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if transaction.isProcessed {
                TariButton("Done", style: .secondary, size: .large) {
                    router.isSwapPresented = false
                    dismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .task { await monitorTransactionStatus() }
        .onChange(of: scenePhase) {
            Task {
                if scenePhase == .active {
                    await monitorTransactionStatus()
                } else {
                    await exolix.stopMonitoringTransactions()
                }
            }
        }
    }
}

private extension SwapProgress {
    var header: some View {
        VStack(spacing: 8) {
            Image(icon)
            Text(title)
                .headingLarge()
                .foregroundStyle(.primaryText)
            Text(subtitle)
                .body()
                .foregroundStyle(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primaryBackground)
        }
    }
    
    var processingInfo: some View {
        VStack(spacing: 10) {
            amountItem
            SwapItem(label: "Destination address (\(transaction.coinTo.coinCode))", value: transaction.depositAddress)
            if let depositId = transaction.depositExtraId, !depositId.isEmpty {
                SwapItem(label: "Deposit id", value: depositId)
            }
            SwapItem(label: "Transaction id", value: transaction.id)
            if let createdAt = transaction.createdAtDate {
                SwapItem(label: "Created", value: createdAt.formatted(), isCoppiable: false)
            }
            SwapItem(label: "Exchange rate", value: "1 \(transaction.coinFrom.coinCode) = \(transaction.rate.formatted()) \(transaction.coinTo.coinCode)", isCoppiable: false)
            if let comment = transaction.comment, !comment.isEmpty {
                SwapItem(label: "Comment", value: comment)
            }
            if let refundAddress = transaction.refundAddress, !refundAddress.isEmpty {
                SwapItem(label: "Refund address \(transaction.coinFrom.coinName)", value: refundAddress)
            }
            if let refundId = transaction.refundExtraId, !refundId.isEmpty {
                SwapItem(label: "Refund extra id", value: refundId)
            }
        }
    }
    
    @ViewBuilder
    var amountItem: some View {
        switch transaction.status {
        case .none, .wait, .confirmation, .confirmed, .exchanging, .sending:
            SwapItem(label: "You will receive", value: "\(transaction.amountTo) \(transaction.coinTo.coinCode)", isCoppiable: false)
        case .success:
            SwapItem(label: "Amount received", value: "\(transaction.amountTo) \(transaction.coinTo.coinCode)", isCoppiable: false)
        case .overdue:
            SwapItem(label: "Amount overdue", value: "\(transaction.amount) \(transaction.coinFrom.coinCode)", isCoppiable: false)
        case .refunded:
            SwapItem(label: "Amount refunded", value: "\(transaction.amount) \(transaction.coinFrom.coinCode)", isCoppiable: false)
        }
    }
    
    var icon: ImageResource {
        switch transaction.status {
        case .wait, .confirmation, .confirmed, .exchanging, .sending, .none:
            .swapProcessing
        case .success:
            .swapSuccess
        case .overdue, .refunded:
            .swapError
        }
    }
    
    var title: String {
        switch transaction.status {
        case .wait, .none:
            "Waiting for deposit"
        case .confirmation, .confirmed, .exchanging:
            "Funds Received"
        case .sending:
            "Sending Your \(transaction.coinTo.coinCode)"
        case .success:
            "Exchange Complete"
        case .overdue:
            "Transaction Expired"
        case .refunded:
            "Transaction Refunded"
        }
    }
    
    var subtitle: String {
        switch transaction.status {
        case .wait, .none:
            "We have not received your \(transaction.coinFrom.coinCode) yet."
        case .confirmation, .confirmed:
            "We have received your \(transaction.coinFrom.coinCode)."
        case .exchanging:
            "We have received your \(transaction.coinFrom.coinCode). Your exchange is processing."
        case .sending:
            "The exchange is complete. Your \(transaction.coinTo.coinCode) is on its way to your wallet."
        case .success:
            "The exchange is complete. Your \(transaction.coinTo.coinCode) is on its way to your wallet."
        case .overdue:
            "We did not receive your deposit within the time limit. Please start a new transaction."
        case .refunded:
            "Your exchange could not be completed. We have returned your original \(transaction.coinFrom.coinCode) to your wallet."
        }
    }
}

private extension ExolixTransactionStatus {
    var isCancellable: Bool {
        switch self {
        case .wait, .overdue: true
        default: false
        }
    }
}
