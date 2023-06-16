//  UserSettingsManager.swift

/*
	Package MobileWallet
	Created by Browncoat on 18/12/2022
	Using Swift 5.0
	Running on macOS 13.0

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

enum UserSettingsManager {

    static var name: String? {
        get { userSettings.name }
        set {
            var userSettings = userSettings
            userSettings.name = newValue
            GroupUserDefaults.userSettings = userSettings
        }
    }

    static var colorScheme: UserSettings.ColorScheme {
        get { userSettings.colorScheme }
        set {
            var userSettings = userSettings
            userSettings.colorScheme = newValue
            GroupUserDefaults.userSettings = userSettings
        }
    }

    static var bleAdvertisementMode: UserSettings.BLEAdvertisementMode {
        get { userSettings.bleAdvertismentMode }
        set {
            var userSettings = userSettings
            userSettings.bleAdvertismentMode = newValue
            GroupUserDefaults.userSettings = userSettings
        }
    }

    static var rotaryMenuPosition: UserSettings.RotaryMenuPosition {
        get { userSettings.rotaryMenuPosition }
        set {
            var userSettings = userSettings
            userSettings.rotaryMenuPosition = newValue
            GroupUserDefaults.userSettings = userSettings
        }
    }

    private static var userSettings: UserSettings {

        guard let settings = GroupUserDefaults.userSettings else {
            let newSettings = UserSettings.default
            GroupUserDefaults.userSettings = newSettings
            return newSettings
        }

        return settings
    }
}
