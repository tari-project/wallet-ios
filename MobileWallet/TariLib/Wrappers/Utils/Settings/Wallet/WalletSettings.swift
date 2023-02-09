//  WalletSettings.swift

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

struct WalletSettings: Codable, Equatable {

    enum  WalletConfigurationState: Codable {
        /// Wallet wasn't configured
        case notConfigured
        /// Walet was created
        case initialized
        /// User finished authorisation flow
        case authorized
        /// Wallet screen was presented to the user
        case ready
    }

    enum BackupStatus: Codable {

        case disabled
        case enabled(syncDate: Date?)

        static var enabled: Self { .enabled(syncDate: nil) }

        var isEnabled: Bool {
            switch self {
            case .enabled:
                return true
            case .disabled:
                return false
            }
        }
    }

    enum WalletSecurityStage: Codable {
        /// Seed Phrase Validated
        case stage1A
        /// Cloud Backup Enabled
        case stage1B
        /// Cloud Backup Encrypted
        case stage2
        /// Tokens Moved to Cold Wallet
        case stage3
    }

    let networkName: String
    var configurationState: WalletConfigurationState
    var iCloudDocsBackupStatus: BackupStatus
    var dropboxBackupStatus: BackupStatus
    var hasVerifiedSeedPhrase: Bool
    var delayedWalletSecurityStagesTimestamps: [WalletSecurityStage: Date]
    var yat: String?

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.networkName == rhs.networkName }
}

extension WalletSettings.BackupStatus {

    var isOn: Bool {
        switch self {
        case .enabled:
            return true
        case .disabled:
            return false
        }
    }
}
