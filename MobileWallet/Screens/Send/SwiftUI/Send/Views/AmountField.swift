//  AmountField.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 15.10.2025
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

struct AmountField: View {
    @Binding var amount: String
    var label = "Amount"
    let availableBalance: MicroTari?
    let error: String?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(label)
                    .foregroundStyle(.primaryText)
                Spacer()
                if let formattedAvailableBalance {
                    Text("Available: \(formattedAvailableBalance)")
                        .foregroundStyle(.secondaryText)
                }
            }
            .body()
            
            VStack(alignment: .leading, spacing: 8) {
                TextField(text: $amount, prompt: .placeholder("Enter XTM amount to send")) { }
                    .keyboardType(.decimalPad)
                    .textFieldBorder()
                if let error {
                    Text(error)
                        .body2()
                        .foregroundStyle(.errorMain)
                }
            }
        }
    }
    
    var formattedAvailableBalance: String? {
        availableBalance?.formattedWithCurrency
    }
}

extension Text {
    static func placeholder(_ text: String) -> Text {
        Text(text)
            .body2()
            .foregroundStyle(.secondaryText)
    }
}

#Preview {
    AmountField(amount: .constant(""), availableBalance: .zero, error: nil)
}
