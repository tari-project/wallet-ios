//  TransactionDetailItem.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 19.06.2025
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

struct TransactionDetailItem<Actions: View>: View {
    let label: String
    let value: String
    var valueColor: Color = .primaryText
    @ViewBuilder let actions: Actions?
    var valueAction: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .body2()
                .foregroundStyle(.secondaryText)
            HStack(spacing: 8) {
                Text(value)
                    .body()
                    .foregroundStyle(valueColor)
                    .onTapGesture { valueAction?() }
                Spacer()
                if let actions {
                    actions
                }
            }
            .padding(.bottom, 10)
            
            Divider()
        }
        .padding(.top, 10)
    }
}

extension TransactionDetailItem where Actions == EmptyView {
    init(label: String, value: String, valueColor: Color = .primaryText) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.actions = nil
    }
}

#Preview {
    VStack {
        TransactionDetailItem(label: "Paid", value: "150 XTM") {
            Circle().frame(width: 20, height: 20)
        }
        TransactionDetailItem(label: "Status", value: "In progress", valueColor: .warningMain)
    }
    .padding()
}
