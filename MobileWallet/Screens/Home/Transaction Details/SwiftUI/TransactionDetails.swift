//  TransactionDetails.swift
	
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

struct TransactionDetails: View {
    @Environment(\.dismiss) var dismiss
    @State var latestTransaction: Transaction?
    @State var title: String?
    @State var amount: String?
    @State var addressComponents: TariAddressComponents?
    @State var contact: ContactsManager.Model?
    @State var paymentReference: PaymentReference?
    @State var walletBlockHeight: UInt64 = 0
    @State var blockExplorerLink: URL?
    @State var isEmojiAddress = false
    @State var showsFullTextAddress = false
    @State var isPresentingEditName = false
    @State var isPresentingPaymentReferenceInfo = false
    
    let initialTransaction: Transaction
    
    init(_ transaction: Transaction) {
        initialTransaction = transaction
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                items.padding()
            }
            .safeAreaInset(edge: .bottom) {
                CopyRawDetailsButton {
                    copyRawDetails()
                }
                .padding(.bottom)
            }
            .navigationTitle(title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .sceneBackground(.primaryBackground)
            .toolbar {
                toolbarBackItem { dismiss() }
            }
            .sheet(isPresented: $isPresentingEditName) {
                if let address = try? transaction.address {
                    EditContactNameSheet(address: address) {
                        contact = $0
                    }
                }
            }
            .sheet(isPresented: $isPresentingPaymentReferenceInfo) {
                PaymentReferenceInfoSheet()
            }
            .onAppear { load() }
        }
        .onReceive(Tari.mainWallet.connectionCallbacks.$blockHeight) {
            walletBlockHeight = $0
            loadPaymentReference()
        }
        .onReceive(transactionUpdatePublisher) {
            latestTransaction = $0
        }
    }
}

private extension TransactionDetails {
    var items: some View {
        VStack(spacing: 0) {
            if let amount {
                TransactionDetailItem(label: isOutbound ? "Send" : "Received", value: amount)
            }
            if let address {
                TransactionDetailItem(
                    label: isOutbound ? "To" : "From",
                    value: showsFullTextAddress && !isEmojiAddress ? address : address.truncated(to: 12)
                ) {
                    HStack {
                        EmojiToggle(isOn: $isEmojiAddress)
                        copyButton(address)
                    }
                } valueAction: {
                    if !isEmojiAddress {
                        withAnimation {
                            showsFullTextAddress.toggle()
                        }
                    }
                }
            }
            if let reference = paymentReference?.paymentReference {
                if isConfirmed {
                    TransactionDetailItem(label: "Payment reference", value: reference) {
                        HStack {
                            IconButton(.helpCircle) {
                                isPresentingPaymentReferenceInfo = true
                            }
                            copyButton(reference)
                        }
                    }
                } else {
                    TransactionDetailItem(label: "Payment reference", value: "Waiting for \(requiredConfirmationCount) block confirmations (\(confirmationCount) of \(requiredConfirmationCount))")
                }
            }
            TransactionDetailItem(
                label: "Contact name",
                value: alias ?? "Add contact name...",
                valueColor: alias != nil ? .primaryText : .secondaryText // TODO: Placeholder colour?
            ) {
                IconButton(.editContact) {
                    isPresentingEditName = true
                }
            }
            if let date {
                TransactionDetailItem(label: "Date", value: date)
            }
            TransactionDetailItem(label: "Mined in Block Height", value: "\(minedBlockHeight)") {
                if let blockExplorerLink {
                    IconButton(.openExplorer) {
                        UIApplication.shared.open(blockExplorerLink)
                    }
                }
            }
            if let status {
                TransactionDetailItem(label: "Status", value: status.0, valueColor: status.1)
            }
            if let transactionMessage {
                TransactionDetailItem(label: "Note", value: transactionMessage) {
                    copyButton(transactionMessage)
                }
            }
        }
    }
    
    @ViewBuilder
    func copyButton(_ value: String?) -> some View {
        if let value, !value.isEmpty {
            CopyButton(value: value)
        }
    }
}

extension String {
    func truncated(to length: Int) -> String {
        guard count > length else { return self }
        return "\(prefix(length / 2))...\(suffix(length / 2))"
    }
}

// TODO: setup mocked data
//#Preview {
//    TransactionDetails(transaction: .mock)
//}
