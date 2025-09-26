//  Settings.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 16.09.2025
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

struct Settings: View {
    @State private var presentedItem: Item?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // TODO: Find profile
//                    item(.profile)
                    item(.contacts)
                    item(.walletSettings)
                    item(.support)
                    item(.legal)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
            }
            .background(Color.secondaryBackground)
            .toolbar { toolbarTitle("Settings") }
            .safeAreaInset(edge: .bottom) { appVersion }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $presentedItem) {
                destination(for: $0)
            }
        }
    }
}

extension Settings {
    enum Item {
        case profile, contacts, walletSettings, support, legal
    }
}

private extension Settings {
    func item(_ item: Item) -> some View {
        SettingsItem(image: item.icon, title: item.title) {
            presentedItem = item
        }
    }
    
    @ViewBuilder
    func destination(for item: Item) -> some View {
        switch item {
        case .profile: ProfileSettings()
        case .contacts: ContactBook()
        case .walletSettings: WalletUserSettings()
        case .support: SupportSettings()
        case .legal: LegalSettings()
        }
    }
    
    @ViewBuilder
    var appVersion: some View {
        if let version = AppVersionFormatter.version {
            Text(version)
                .headingSmall()
                .foregroundStyle(.secondaryText)
                .padding(.bottom, 20)
        }
    }
}

private extension Settings.Item {
    var title: String {
        switch self {
        case .profile: "Profile"
        case .contacts: "Contacts"
        case .walletSettings: "Wallet Settings"
        case .support: "Support & Resources"
        case .legal: "Legal"
        }
    }
    
    var icon: ImageResource {
        switch self {
        case .profile: .settingsProfile
        case .contacts: .settingsContacts
        case .walletSettings: .settingsWallet
        case .support: .settingsSupport
        case .legal: .settingsLegal
        }
    }
}

#Preview {
    Settings()
}
