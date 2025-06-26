//  EditContactSheet.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 23.06.2025
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

struct EditContactNameSheet: View {
    @Environment(\.dismiss) var dismiss
    @FocusState var isFocused: Bool
    @State var alias = ""
    let contacts = ContactsManager()
    let address: TariAddress
    let onContactUpdate: (ContactsManager.Model) -> Void
    
    var body: some View {
        VStack {
            Text("Edit contact")
                .headingLarge()
                .foregroundStyle(.primaryText)
            
            VStack(spacing: 4) {
                TextField("", text: $alias, prompt: Text("Add Name"))
                    .body()
                    .focused($isFocused)
                Divider()
                Spacer()
            }
            .padding(.vertical)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: save) {
                Text("Done")
                    .buttonMedium()
                    .foregroundStyle(alias.isEmpty ? .disabled : .primaryText)
            }
            .disabled(alias.isEmpty)
        }
        .padding(.vertical)
        .padding()
        .presentationDetents([.height(128)])
        .onAppear {
            isFocused = true
            load()
        }
    }
}

private extension EditContactNameSheet {
    func load() {
        Task { // TODO: sync contact access with actor
            try await contacts.fetchModels()
            if let contact = try await contacts.contact(for: address) {
                alias = contact.alias ?? ""
            }
        }
    }
    
    func save() {
        Task { // TODO: sync contact access with actor
            // TODO: Setup contact service and move contact manipulation there
            do {
                if let contact = try await contacts.contact(for: address) {
                    try contacts.update(alias: alias, isFavorite: contact.isFavorite, contact: contact)
                    if let contact = try await contacts.contact(for: address) {
                        onContactUpdate(contact)
                    }
                } else {
                    let contact = try contacts.createInternalModel(name: alias, isFavorite: false, address: address)
                    onContactUpdate(contact)
                }
                dismiss()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
