//  AppContainerLock.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/05/22
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

enum AppContainer: String {
    case ext = "extension"
    case main = "main"
}

/// Used for coordinating tasks like tor and wallet services that need to run in both the main app and app extension containers
class AppContainerLock {
    static let shared = AppContainerLock()
    static private let storageKey = "wallet-service-lock"

    private init() {}

    func hasLock(_ container: AppContainer) -> Bool {
        let filePath = TariSettings.shared.storageDirectory.appendingPathComponent("\(container.rawValue).lock").path

        let fileExists = FileManager.default.fileExists(atPath: filePath)

        if !fileExists {
            return false
        }

        var freshness: TimeInterval = 60
        if container == .main {
            freshness = 60 * 5
        }

        //Check if a lock file is aged. In case the app crashed and it's stuck with a lock file
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            if let age = attr[FileAttributeKey.modificationDate] as? Date {
                let oldestAcceptedDate = Date() - freshness

                if age < oldestAcceptedDate {
                    TariLogger.warn("Lock file exists but older than \(freshness)")
                    return false
                }

                print(age)
            }
        } catch {
            TariLogger.error("Failed to get lock file age", error: error)
        }

        return fileExists
    }

    func setLock(_ container: AppContainer) {
        let file = TariSettings.shared.storageDirectory.appendingPathComponent("\(container.rawValue).lock")
        try? "".write(to: file, atomically: false, encoding: String.Encoding.utf8)
    }

    func removeLock(_ container: AppContainer) {
        guard hasLock(container) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: TariSettings.shared.storageDirectory.appendingPathComponent("\(container.rawValue).lock"))
        } catch {
            TariLogger.error("Failed to delete lock", error: error)
        }
    }
}
