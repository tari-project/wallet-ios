//  ConfirmSend.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 28.08.2025
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

struct ConfirmSend: View {
    @Environment(\.dismiss) var dismiss
    @State var isPresentingFeeInfo = false
    @State var isEmojiAddress = false
    @State var sendingTransaction: SendConfirmation?

    let confirmation: SendConfirmation
    
    var body: some View {
        VStack(spacing: 8) {
            Text("You are about to send")
                .headingLarge()
                .foregroundStyle(.primaryText)
            sendToHeader
            transactionDetails
            Spacer()
        }
        .padding(24)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            actions
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .sceneBackground(.secondaryBackground)
        .navigationBarBackButtonHidden()
        .toolbar {
            toolbarTitle("Send")
            toolbarBackItem { dismiss() }
        }
        .sheet(isPresented: $isPresentingFeeInfo) {
            FeeInfoSheet()
        }
        .navigationDestination(item: $sendingTransaction) {
            SendingTransaction(confirmation: $0)
        }
    }
}

private extension ConfirmSend {
    var sendToHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text(confirmation.amount.formattedWithCurrency)
                    .headingXL()
                    .foregroundStyle(.primaryText)
                Spacer()
                Image(.sendTariIcon)
            }
            .frame(height: 44)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.primaryBackground, stroke: .outlined, lineWidth: 2)
            }
            HStack {
                Text(confirmation.contact?.name ?? confirmation.address.fullEmoji.truncatedAddress)
                    .headingXL()
                    .foregroundStyle(.primaryText)
                Spacer()
                Image(.sendTariIcon)
            }
            .frame(height: 44)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.primaryBackground, stroke: .outlined, lineWidth: 2)
            }
        }
        .overlay {
            Image(.sendFundsSeparator)
        }
    }
    
    var transactionDetails: some View {
        VStack(spacing: 0) {
            TransactionDetailItem(label: "Transaction Fee", value: confirmation.fee.formattedPreciseWithCurrency) {
                IconButton(.helpCircle) {
                    isPresentingFeeInfo = true
                }
            }
            TransactionDetailItem(label: "Recipient Address", value: address.truncatedAddress) {
                HStack(spacing: 12) {
                    EmojiToggle(isOn: $isEmojiAddress)
                    CopyButton(value: address)
                }
            }
            if let note = confirmation.note {
                TransactionDetailItem(label: "Note", value: note)
            }
            TransactionDetailTotal(value: total)
        }
    }
    
    var actions: some View {
        VStack(spacing: 16) {
            TariButton("Confirm & Send", style: .primary, size: .large) {
                sendingTransaction = confirmation
            }
            TariButton("Cancel", style: .text, size: .medium) {
                HomeRouter.shared.dismissSendPresentation()
            }
        }
    }
    
    var address: String {
        isEmojiAddress ? confirmation.address.fullEmoji : confirmation.address.fullRaw
    }
    
    var total: String {
        (confirmation.amount + confirmation.fee).formattedPreciseWithCurrency
    }
}

// TODO: Setup mocks
#Preview {
    try? ConfirmSend(confirmation: SendConfirmation(
        amount: MicroTari(10),
        fee: MicroTari(1),
        feePerGram: MicroTari(1),
        address: TariAddressComponents(address: TariAddress(base58: "BB2384F5793C8D8D4E08A9FA7380DBC249A48181F21DAD3EF46DBFE504400C7C")),
        note: nil,
        contact: nil
    ))
}
