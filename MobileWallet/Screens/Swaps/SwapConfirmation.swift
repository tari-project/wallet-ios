//  SwapConfirmation.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 11.11.2025
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

struct SwapConfirmation: View {
    @AppStorage("swapInProgressId") var swapInProgressId: String?
    @Environment(\.dismiss) var dismiss
    @State var transaction: ExolixTransactionResponse?
    @State var presentedTransactionProgress: ExolixTransactionResponse?
    @State var errorMessage: String?
    
    let exolix: Exolix
    var sellRequest: ExolixConfirmation
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let transaction {
                    header(for: transaction)
                    transactionInfo(for: transaction)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
        }
        .background(Color.secondaryBackground)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarTitle("Review swap")
            toolbarBackItem { dismiss() }
        }
        .overlay(alignment: .bottom) {
            ExolixLogo()
                .padding(.bottom, 80)
        }
        .safeAreaInset(edge: .bottom) {
            TariButton("Confirm", style: .primary, size: .large) {
                depositXtm()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .alert(title: "Exolix error", message: $errorMessage)
        .navigationDestination(item: $presentedTransactionProgress) {
            SwapProgress(exolix: exolix, transaction: $0)
        }
        .onAppear { load() }
    }
}

private extension SwapConfirmation {
    func header(for transaction: ExolixTransactionResponse) -> some View {
        VStack(spacing: 6) {
            headerItem(label: "You send", amount: transaction.amount, coin: transaction.coinFrom)
            headerItem(label: "You receive", amount: transaction.amountTo, coin: transaction.coinTo)
        }
    }
    
    func transactionInfo(for transaction: ExolixTransactionResponse) -> some View {
        VStack(spacing: 0) {
            if let fee = try? TransactionFeesManager().fee(for: MicroTari(decimalValue: transaction.amount)).formattedWithCurrency {
                SwapItem(label: "Network cost", value: fee)
            }
            SwapItem(label: "Rate", value: "1 \(transaction.coinFrom.coinCode) = \(transaction.rate.formatted()) \(transaction.coinTo.coinCode)")
        }
    }
    
    func headerItem(label: String, amount: Double, coin: ExolixTransactionCoin) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .headingSmall()
                    .foregroundStyle(.secondaryText)
                Text(amount.formatted())
                    .heading2XL()
                    .foregroundStyle(.primaryText)
            }
            Spacer()
            TokenPicker(icon: coin.icon, code: coin.coinCode, network: nil, action: nil)
        }
        .padding(.horizontal, 20)
        .frame(height: 100)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.primaryBackground)
        }
    }
}
