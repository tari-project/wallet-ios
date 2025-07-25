//  TransactionItem.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 26.06.2025
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

struct TransactionItem: View {
    let transaction: FormattedTransaction
    let isBalanceHidden: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(.primaryText)
                    .frame(width: 34, height: 34)
                Image(.gemBlackSmall)
                    .resizable()
                    .templateStyle(.primaryBackground)
                    .frame(width: 16, height: 15)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(transaction.title)
                    .body()
                    .foregroundStyle(.primaryText)
                    .multilineTextAlignment(.leading)
                Text(transaction.formattedTimestamp)
                    .body2()
                    .foregroundStyle(.secondaryText)
            }
            Spacer(minLength: 4)
            Group {
                if isBalanceHidden {
                    Text("****** XTM")
                } else {
                    Text(.init(transaction.formattedAmount))
                }
            }
            .headingLarge()
            .foregroundStyle(.primaryText)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 16)
        .frame(height: 80)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.primaryBackground, stroke: .outlined)
        }
    }
}

// TODO: setup mocks
//#Preview {
//    TransactionItem(transaction: .mock)
//}
