//  AppTabs.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 08.07.2025
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

@Observable
class TabState {
    static let shared = TabState()
    var selected: Tab = .home
}

struct AppTabs: View {
    @State var state = TabState.shared
    
    let walletState: WalletState
    
    var body: some View {
        TabView(selection: $state.selected) {
            home
            profile
            settings
        }
    }
}

private extension AppTabs {
    var home: some View {
        Home(walletState: walletState)
            .environment(HomeRouter.shared)
            .tab(.home, selected: state.selected)
    }
    
    var profile: some View {
        UIProfileViewController()
            .background(Color.secondaryBackground)
            .tab(.profile, selected: state.selected)
    }
    
    var settings: some View {
        UISettingsViewController()
            .background(Color.secondaryBackground)
            .tab(.settings, selected: state.selected)
    }
}

private extension View {
    func tab(_ tab: Tab, selected: Tab) -> some View {
        tabItem {
            Image(selected == tab ? tab.selectedIcon : tab.icon)
        }
        .tag(tab)
    }
}

#Preview {
    AppTabs(walletState: .current)
}
