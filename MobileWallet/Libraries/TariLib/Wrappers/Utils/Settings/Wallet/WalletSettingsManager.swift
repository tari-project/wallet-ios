//  WalletSettingsManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 03/10/2021
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

final class WalletSettingsManager {

    private var settings: WalletSettings {

        guard let networkName = GroupUserDefaults.selectedNetworkName else {
            return makeWalletSettings(networkName: "")
        }

        guard let existingSettings = GroupUserDefaults.walletSettings?.first(where: { $0.networkName == networkName }) else {
            var settings = GroupUserDefaults.walletSettings ?? []
            let newSettings = makeWalletSettings(networkName: networkName)
            settings.append(newSettings)
            GroupUserDefaults.walletSettings = settings
            return newSettings
        }

        return existingSettings
    }

    var configurationState: WalletSettings.WalletConfigurationState {
        get { settings.configurationState }
        set {
            var settings = settings
            settings.configurationState = newValue
            update(settings: settings)
        }
    }

    var iCloudDocsBackupStatus: WalletSettings.BackupStatus {
        get { settings.iCloudDocsBackupStatus }
        set {
            var settings = settings
            settings.iCloudDocsBackupStatus = newValue
            update(settings: settings)
        }
    }

    var dropboxBackupStatus: WalletSettings.BackupStatus {
        get { settings.dropboxBackupStatus }
        set {
            var settings = settings
            settings.dropboxBackupStatus = newValue
            update(settings: settings)
        }
    }

    var hasVerifiedSeedPhrase: Bool {
        get { settings.hasVerifiedSeedPhrase }
        set {
            var settings = settings
            settings.hasVerifiedSeedPhrase = newValue
            update(settings: settings)
        }
    }

    var delayedWalletSecurityStagesTimestamps: [WalletSettings.WalletSecurityStage: Date] {
        get { settings.delayedWalletSecurityStagesTimestamps }
        set {
            var settings = settings
            settings.delayedWalletSecurityStagesTimestamps = newValue
            update(settings: settings)
        }
    }

    var connectedYat: String? {
        get { settings.yat }
        set {
            var settings = settings
            settings.yat = newValue
            update(settings: settings)
        }
    }

    private func makeWalletSettings(networkName: String) -> WalletSettings {
        WalletSettings(
            networkName: networkName,
            configurationState: .notConfigured,
            iCloudDocsBackupStatus: .disabled,
            dropboxBackupStatus: .disabled,
            hasVerifiedSeedPhrase: false,
            delayedWalletSecurityStagesTimestamps: [:],
            yat: nil
        )
    }

    private func update(settings: WalletSettings) {
        var allSettings = GroupUserDefaults.walletSettings ?? []
        allSettings.removeAll { $0 == settings }
        allSettings.append(settings)
        GroupUserDefaults.walletSettings = allSettings
    }
}
