//  TransactionHistory.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 18.07.2025
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

struct TransactionHistory: View {
    @Environment(\.dismiss) var dismiss
    @State var searchText = ""
    @State var presentedTransaction: FormattedTransaction?

    let transactions: [FormattedTransaction]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(filteredTransactions) { transaction in
                    Button(action: { presentedTransaction = transaction }) {
                        TransactionItem(transaction: transaction, isBalanceHidden: false)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
        }
        .searchable(text: $searchText, placement: .toolbar)
        .sceneBackground(.secondaryBackground)
        .navigationBarBackButtonHidden()
        .toolbar { toolbar }
        .navigationDestination(item: $presentedTransaction) {
            if let transaction = Tari.mainWallet.transaction(id: $0.id) {
                TransactionDetails(transaction)
            }
        }
    }
}

private extension TransactionHistory {
    var toolbar: some ToolbarContent {
        Group {
            toolbarBackItem { dismiss() }
            ToolbarItem(placement: .principal) {
                Text("Transaction History")
                    .headingLarge()
                    .foregroundStyle(.primaryText)
            }
        }
    }
    
    var filteredTransactions: [FormattedTransaction] {
        searchText.isEmpty ? transactions : transactions.filter {
            searchContains($0.title)
            || searchContains($0.emojiId)
            || searchContains($0.formattedTimestamp)
            || searchContains($0.formattedAmount.string)
            || $0.note != nil && searchContains($0.note ?? "")
        }
    }
    
    func searchContains(_ value: String) -> Bool {
        value.lowercased()
            .components(separatedBy: " ")
            .contains { $0.contains(searchText.lowercased()) }
    }
}
