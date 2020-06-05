//  Migrations.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/05/14
	Using Swift 5.0
	Running on macOS 10.15

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

import Foundation
import SwiftKeychainWrapper

class Migrations {
    /// Needs to be called from AppDelegate didFinishLaunchingWithOptions
    static func handle() {
        TariLogger.verbose("Checking for migrations")
        Migrations.tariDBToGroupStorage()
        Migrations.torCacheToGroupStorage()
    }

    static private func tariDBToGroupStorage() {
        let fileManager = FileManager.default
        guard let oldDbDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent("tari_wallet", isDirectory: true) else {
            return TariLogger.warn("Old tari DB storage directory not found")
        }

        let newDBDirectory = TariLib.shared.databaseDirectory

        //Has old dir but not new one
        guard directoryExists(oldDbDirectory) && !directoryExists(newDBDirectory) else {
            return
        }

        do {
            try fileManager.moveItem(at: oldDbDirectory, to: newDBDirectory)
        } catch {
            return TariLogger.error("Failed to move tari DB files", error: error)
        }

        TariLogger.verbose("Migrated tari databases to shared app group storage")
    }

    static private func torCacheToGroupStorage() {
        let fileManager = FileManager.default
        guard let oldTorDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("tor", isDirectory: true) else {
            return TariLogger.warn("Old tor cache directory not found")
        }

        let newTorDirectory = TariSettings.shared.storageDirectory.appendingPathComponent("tor", isDirectory: true)

        //Has old dir but not new one
        guard directoryExists(oldTorDirectory) && !directoryExists(newTorDirectory) else {
            return
        }

        do {
            try fileManager.moveItem(at: oldTorDirectory, to: newTorDirectory)
        } catch {
            return TariLogger.error("Failed to move tor cache", error: error)
        }

        TariLogger.verbose("Migrated Tor cache to shared app group storage")
    }

    /// Needs to be called with the comms config that is about to be used to start the wallet
    /// - Parameter comms: Comms config used for wallet service
    static func privateKeyKeychainToDB(_ comms: CommsConfig) {
        let sharedKeychainGroup = KeychainWrapper(
            serviceName: "tari",
            accessGroup: "\(TariSettings.shared.appleTeamID ?? "").com.tari.wallet.keychain"
        )

        let forKey = "privateKey"

        guard let privateKeyHex = sharedKeychainGroup.string(forKey: forKey) else {
            return
        }

        guard let privateKey = try? PrivateKey(hex: privateKeyHex) else {
            TariLogger.error("Private key not initialized with hex value")
            return
        }

        do {
            try comms.setPrivateKey(privateKey)

            TariLogger.verbose("Migrated private key from keychain to database")
            sharedKeychainGroup.removeObject(forKey: forKey)
        } catch {
            TariLogger.error("Failed to migrate private keyt from keychain to database", error: error)
        }
    }

    static private func directoryExists(_ url: URL) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }

        return isDirectory.boolValue
    }
}
