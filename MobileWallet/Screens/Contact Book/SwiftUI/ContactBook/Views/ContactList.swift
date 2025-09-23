//  ContactList.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 26.08.2025
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

struct ContactList: View {
    @State private var recents = [ContactModel]()
    @State private var contacts = [ContactModel]()
    @State private var searchText = ""
    
    private let contactsManager = ContactsManager()
    
    let selectAction: (ContactModel) -> Void
    
    var body: some View {
        let filteredContacts = searchFilter(contacts)
        let filteredRecents = searchFilter(recents)
        ScrollView {
            VStack(spacing: 32) {
                contactsSection(header: "Recents", contacts: filteredRecents)
                contactsSection(header: "Contacts", contacts: filteredContacts)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: Text("Find Contact"))
        .body()
        .background {
            if filteredContacts.isEmpty && filteredRecents.isEmpty {
                Text("No result")
            }
        }
        .sceneBackground(.secondaryBackground)
        .onAppear { load() }
    }
}

private extension ContactList {
    @ViewBuilder
    func contactsSection(header: String, contacts: [ContactModel]) -> some View {
        if !contacts.isEmpty {
            VStack(spacing: 16) {
                Text(header)
                    .headingLarge()
                    .foregroundStyle(.primaryText)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 4) {
                    ForEach(contacts) { contact in
                        ContactBookItem(contact: contact, action: selectAction)
                    }
                }
            }
        }
    }
    
    func searchFilter(_ contacts: [ContactModel]) -> [ContactModel] {
        searchText.isEmpty ? contacts : contacts.filter {
            $0.name.contains(search: searchText)
            || $0.address?.fullRaw.contains(search: searchText) ?? false
        }
    }
    
    func load() {
        Task {
            do {
                try await contactsManager.fetchModels()
                contacts = contactsManager.contacts()
                recents = loadRecentContacts()
            } catch {
                contacts = []
            }
        }
    }
    
    func loadRecentContacts() -> [ContactModel] {
        do {
            let recent = try contactsManager.recentAddresses(count: 3)
            return contacts.filter { contact in
                recent.contains { address in
                    (try? address.components == contact.address) ?? false
                }
            }
        } catch {
            return []
        }
    }
}

#Preview {
    ContactList { _ in }
}
