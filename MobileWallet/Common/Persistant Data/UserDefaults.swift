//  UserDefaults.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 16/07/2021
	Using Swift 5.0
	Running on macOS 12.0

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

// MARK: - Generic User Defaults

private enum UserDefaultName: String, CaseIterable {
    case selectedNetworkName
    case networksSettings
    case walletSettings
    case userSettings
    case isTrackingEnabled
}

enum GroupUserDefaults {
    @UserDefault(key: UserDefaultName.selectedNetworkName.rawValue, suiteName: TariSettings.groupIndentifier) static var selectedNetworkName: String?
    @UserDefault(key: UserDefaultName.networksSettings.rawValue, suiteName: TariSettings.groupIndentifier) static var networksSettings: [NetworkSettings]?
    @UserDefault(key: UserDefaultName.walletSettings.rawValue, suiteName: TariSettings.groupIndentifier) static var walletSettings: [WalletSettings]?
    @UserDefault(key: UserDefaultName.userSettings.rawValue, suiteName: TariSettings.groupIndentifier) static var userSettings: UserSettings?
    @UserDefault(key: UserDefaultName.isTrackingEnabled.rawValue, suiteName: TariSettings.groupIndentifier) static var isTrackingEnabled: Bool?
}

// MARK: - Tor Manager User Defaults

enum TorManagerUserDefaults {

    private enum Name: String, CaseIterable {
        case isUsingCustomBridges
        case torBridges
    }

    @UserDefault(key: Name.isUsingCustomBridges.rawValue) static var isUsingCustomBridges: Bool?
    @UserDefault(key: Name.torBridges.rawValue) static var torBridges: String?

    static func removeAll() {
        Name.allCases.forEach { UserDefaults.standard.removeObject(forKey: $0.rawValue) }
    }
}

// MARK: - Extensions

extension UserDefaults {
    func removeAll() {
        UserDefaultName.allCases.forEach { UserDefaults.standard.removeObject(forKey: $0.rawValue) }
        TorManagerUserDefaults.removeAll()
    }
}
