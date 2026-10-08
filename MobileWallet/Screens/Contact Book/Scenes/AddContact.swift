//  AddContact.swift
	
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

struct AddContact: View {
    @Environment(\.dismiss) var dismiss
    @State var name = ""
    @State var nameError: String?
    @State var address = ""
    @State var addressError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    nameField
                    Divider()
                    addressField
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarTitle("Add Cotact")
                toolbarBackItem {
                    dismiss()
                }
            }
            .sceneBackground(.secondaryBackground)
        }
        .onChange(of: address) {
            validateAddress()
        }
    }
}

extension AddContact: QRScaner {
    func scanQR() {
        scanQRAddress { address in
            self.address = (try? address?.components.fullRaw) ?? ""
        }
    }
}

private extension AddContact {
    var nameField: some View {
        field(label: "Name *", error: nameError) {
            TariTextEditor($name, placeholder: "Enter contact name", error: nameError)
        }
    }
    
    var addressField: some View {
        field(label: "Address *", error: addressError) {
            TariTextEditor($address, placeholder: "Recipient address", error: addressError) {
                Button(action: scanQR) {
                    Image(.scanQR)
                        .renderingMode(.template)
                        .foregroundStyle(.primaryText)
                }
            }
        }
    }
    
    func field<Content: View>(label: String, error: String?, content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .body()
                .foregroundStyle(error == nil ? .primaryText : .errorMain)
            content()
        }
    }
    
    var saveButton: some View {
        TariButton("Save Contact", style: .primary, size: .large) {
            save()
        }
        .disabled(isSaveDisabled)
    }
    
    var isSaveDisabled: Bool {
        name.isEmpty || address.isEmpty || nameError != nil || addressError != nil
    }
    
    func validateAddress() {
        let isAddressValid = (try? TariAddress(base58: address)) != nil || (try? TariAddress(emojiID: address)) != nil
        withAnimation {
            addressError = !address.isEmpty && !isAddressValid  ? "Invalid address" : nil
        }
    }
    
    func save() {
        guard let address = (try? TariAddress(base58: address)) ?? (try? TariAddress(emojiID: address)) else {
            return
        }
        UIApplication.shared.hideKeyboard()
        Task {
            do {
                let contacts = ContactsManager()
                try await contacts.update(alias: name, for: address.components) { _ in
                    dismiss()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

#Preview {
    AddContact()
}
