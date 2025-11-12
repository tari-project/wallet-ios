//  TariTextEditor.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 29.09.2025
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

struct TariTextEditor<Item: View>: View {
    @Binding var value: String
    let placeholder: String
    let error: String?
    let trailingItem: Item?
    
    init(_ value: Binding<String>, placeholder: String, error: String? = nil, trailingItem: () -> Item) {
        self._value = value
        self.placeholder = placeholder
        self.error = error
        self.trailingItem = trailingItem()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextEditor(text: $value)
                    .scrollContentBackground(.hidden)
                    .padding(.vertical, -6)
                    .padding(.horizontal, -5)
                    .frame(minHeight: 24)
                    .overlay(alignment: .leading) {
                        if value.isEmpty {
                            Text(placeholder)
                                .body2()
                                .foregroundStyle(.secondaryText)
                                .allowsHitTesting(false)
                        }
                    }
                if let trailingItem {
                    trailingItem
                }
            }
            .textFieldBorder(isValid: error == nil)
            
            if let error {
                Text(error)
                    .body2()
                    .foregroundStyle(.errorMain)
            }
        }
    }
}

extension TariTextEditor where Item == EmptyView {
    init(_ value: Binding<String>, placeholder: String, error: String? = nil) {
        self._value = value
        self.placeholder = placeholder
        self.error = error
        self.trailingItem = nil
    }
}

extension View {
    func textFieldBorder(isValid: Bool = true) -> some View {
        self.body2()
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.primaryBackground, stroke: isValid ? .outlined : .errorMain)
            }
    }
}

#Preview {
    TariTextEditor(.constant("Text"), placeholder: "", error: nil)
}
