//  Send.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 22.08.2025
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

struct SendConfirmation: Hashable {
    let amount: MicroTari
    let fee: MicroTari
    let feePerGram: MicroTari
    let address: TariAddressComponents
    let note: String?
    let contact: ContactModel?
}

struct Send: View {
    @Environment(\.dismiss) var dismiss
    @State var availableBalance: MicroTari?
    @State var fee: MicroTari?
    @State var feePerGram: MicroTari?
    @State var address: String = ""
    @State var amount: String = ""
    @State var note: String = ""
    @State var addressError: String?
    @State var amountError: String?
    @State var contact: ContactModel?
    @State var isPresentingFeeInfo = false
    @State var isSelectingContact = false
    @State var presentedConfirmation: SendConfirmation?
    
    var preffiledAddress = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                addressSection
                Divider()
                amountSection
                Divider()
                noteSection
            }
            .padding(16)
        }
        .sceneBackground(.secondaryBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarTitle("Send")
            toolbarBackItem { dismiss() }
        }
        .safeAreaInset(edge: .bottom, content: {
            TariButton("Continue", style: .primary, size: .large) {
                confirmSend()
            }
            .disabled(!isContinueEnabled)
            .padding([.horizontal, .bottom], 16)
        })
        .onTapGesture { hideKeyboard() }
        .sheet(isPresented: $isPresentingFeeInfo) {
            FeeInfoSheet()
        }
        .fullScreenCover(isPresented: $isSelectingContact) {
            SelectContact {
                address = $0.name
                contact = $0
            }
        }
        .navigationDestination(item: $presentedConfirmation) {
            ConfirmSend(confirmation: $0)
        }
        .onReceive(Tari.mainWallet.walletBalance.$balance) {
            update(walletBalance: $0)
        }
        .onChange(of: amount) { updateAmount() }
        .onChange(of: address) { updateAddress() }
        .onFirstAppear {
            Task(after: 0.1) {
                address = preffiledAddress
            }
        }
    }
}

private extension Send {
    var addressSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Text("To")
                    .body()
                Spacer()
                Button(action: scanQR) {
                    Image(.scanQR)
                        .renderingMode(.template)
                }
                Button(action: selectContact) {
                    Image(.contactBook)
                        .renderingMode(.template)
                }
            }
            .foregroundStyle(.primaryText)
            
            TariTextEditor($address, placeholder: "Recipient address", error: addressError)
        }
    }
    
    var amountSection: some View {
        VStack(spacing: 16) {
            AmountField(amount: $amount, availableBalance: availableBalance, error: amountError)
            Divider()
            HStack {
                Text("Transaction Fee")
                IconButton(.helpCircle) {
                    isPresentingFeeInfo = true
                }
                Spacer()
                Text(fee?.formattedPreciseWithCurrency ?? "0 XTM")
            }
            .body()
            .foregroundStyle(.primaryText)
        }
    }
    
    var noteSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Note (Optional)")
                    .body()
                    .foregroundStyle(.primaryText)
                Spacer()
            }
            TextField(text: $note, prompt: .placeholder("Add note or payment reference")) { }
                .textFieldBorder()
        }
    }
}

#Preview {
    Send()
}
