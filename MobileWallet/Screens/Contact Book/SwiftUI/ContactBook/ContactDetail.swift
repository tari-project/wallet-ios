//  ContactDetail.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 24.09.2025
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

struct ContactDetail: View {
    @Environment(HomeRouter.self) var router
    @Environment(\.dismiss) var dismiss
    @State var transactions = [FormattedTransaction]()
    @State var presentedTransaction: FormattedTransaction?
    @State var isEditingName = false
    @State var contactName: String = ""
    @FocusState var isFocused: Bool
    
    let contacts = ContactsManager()
    let contact: ContactModel
    
    var body: some View {
        @Bindable var router = router
        ScrollView {
            VStack(spacing: 16) {
                name
                if let addressComponents = contact.address {
                    address(addressComponents)
                }
                sendButton
                Divider()
                transactionHistory
                deleteButton
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .toolbar {
            toolbarTitle("Contact Detail")
        }
        .sceneBackground(.secondaryBackground)
        .onAppear { load() }
        .navigationDestination(item: $presentedTransaction) {
            if let transaction = Tari.mainWallet.transaction(id: $0.id) {
                TransactionDetails(transaction)
            }
        }
        .fullScreenCover(isPresented: $router.isContactsSendPresented) {
            NavigationStack {
                Send(preffiledAddress: contact.address?.fullRaw ?? "")
            }
        }
        .onReceive(Tari.mainWallet.transactions.$all) {
            update(transactions: $0)
        }
    }
}

private extension ContactDetail {
    @ViewBuilder
    var name: some View {
        if isEditingName {
            HStack {
                TextField("", text: $contactName, prompt: Text("Add contact name..."))
                    .focused($isFocused)
                    .body()
                Button(action: saveEdit) {
                    Text("Done")
                        .buttonMedium()
                        .foregroundStyle(contactName.isEmpty ? .disabled : .primaryText)
                }
                .disabled(contactName.isEmpty)
            }
        } else {
            Button(action: edit) {
                ZStack {
                    Text(contactName.isEmpty ? "Add contact name..." : contactName)
                        .headingXL()
                        .foregroundStyle(contactName.isEmpty ? .disabledText : .primaryText)
                    HStack {
                        Spacer()
                        Image(.editContact)
                            .padding(4)
                    }
                }
            }
        }
    }
    
    func address(_ address: TariAddressComponents) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Address")
                .foregroundStyle(.secondaryText)
            addressItem(address.fullEmoji, truncatedTo: 6)
            Divider()
            addressItem(address.fullRaw, truncatedTo: 12)
        }
        .padding(16)
        .foregroundStyle(.primaryText)
        .body()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.accentBackground)
        }
    }
    
    func addressItem(_ address: String, truncatedTo: Int) -> some View {
        HStack {
            Text(address.truncated(to: truncatedTo))
            Spacer()
            TariButton("Copy", style: .primary, size: .small) {
                UIPasteboard.general.string = address
            }
        }
    }
    
    var sendButton: some View {
        TariButton("Send", style: .label, size: .large) {
            router.isContactsSendPresented = true
        }
    }
    
    var transactionHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your transaction history with \(contactName)")
                .headingLarge()
                .foregroundStyle(.primaryText)
            VStack(spacing: 8) {
                ForEach(transactions) { transaction in
                    Button(action: { presentedTransaction = transaction }) {
                        TransactionItem(transaction: transaction, isBalanceHidden: false)
                    }
                }
            }
        }
    }
    
    var deleteButton: some View {
        Button(action: delete) {
            Text("Delete Contact")
                .buttonMedium()
                .foregroundStyle(.errorMain)
        }
        .padding(.bottom)
    }
}
