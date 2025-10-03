//  WalletSettings.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 18.09.2025
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
import LocalAuthentication

struct WalletUserSettings: View {
    @State private var presentedItem: Item?
    
    private let localAuth = LAContext()
    
    var body: some View {
        SettingsDetail(title: "Wallet Settings") {
            item(.backup)
            Divider()
            item(.security)
            Divider()
            item(.selectNetwork)
            Divider()
            item(.screenRecording)
            Divider()
            item(.about)
            Divider()
            item(.selectTheme)
            Divider()
            item(.deleteWallet)
        }
        .navigationDestination(item: $presentedItem) {
            destination(for: $0)
                .navigationBarBackButtonHidden()
                .ignoresSafeArea()
        }
    }
}

private extension WalletUserSettings {
    enum Item {
        case backup, security, selectNetwork, screenRecording, about, selectTheme, deleteWallet
    }
    
    @ViewBuilder
    func destination(for item: Item) -> some View {
        switch item {
        case .backup: UIBackupWalletSettings()
        case .security: UIDataCollection()
        case .selectNetwork: UISelectNetwork()
        case .screenRecording: UIScreenRecording()
        case .about: UIAbout()
        case .selectTheme: UIThemeSettings()
        case .deleteWallet: UIDeleteWallet()
        }
    }
    
    func item(_ item: Item) -> some View {
        SettingsDetailItem(title: item.title, isCritical: item.isCritical) {
            select(item: item)
        }
    }
    
    func select(item: Item) {
        switch item {
        case .backup:
            localAuth.authenticateUser(reason: .userVerification, showFailedDialog: false) {
                presentedItem = .backup
            }
        case .security, .selectNetwork, .screenRecording, .about, .selectTheme, .deleteWallet:
            presentedItem = item
        }
    }
}

private extension WalletUserSettings.Item {
    var title: String {
        switch self {
        case .backup: "Wallet Backups"
        case .security: "Privacy & Security"
        case .selectNetwork: "Select Network"
        case .screenRecording: "Screen Recording"
        case .about: "About"
        case .selectTheme: "Select Theme"
        case .deleteWallet: "Delete Your Wallet"
        }
    }
    
    var isCritical: Bool {
        self == .deleteWallet
    }
}

#Preview {
    WalletUserSettings()
}
