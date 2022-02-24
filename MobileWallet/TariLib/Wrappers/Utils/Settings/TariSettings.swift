//  TariSettings.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/03/14
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

enum AppEnvironment {
    case debug
    case testflight
    case production
}

struct TariSettings {

    static let shared = TariSettings()

    let walletSettings = WalletSettingsManager()

    let discoveryTimeoutSec: UInt64 = 20
    let safMessageDurationSec: UInt64 = 10800
    let deeplinkURI = "tari"

    let iCloudContainerIdentifier = "iCloud.com.tari.wallet"

    let tariUrl = "https://www.tari.com/"
    let contributeUrl = "https://www.github.com/tari-project/wallet-ios/"
    let disclaimer = "https://www.tari.com/disclaimer"
    let userAgreementUrl = "https://www.tari.com/user_agreement/"
    let privacyPolicyUrl = "https://www.tari.com/privacy_policy/"
    let storeUrl = "https://store.tarilabs.com/"
    let bugReportEmail = "bug_reports@tari.com"
    let tariLabsUniversityUrl = "https://tlu.tarilabs.com/"
    let blockExplorerUrl = "https://explore.tari.com/"

    var pushServerApiKey: String?
    var sentryPublicDSN: String?
    static var appleTeamID: String?
    var giphyApiKey: String?
    var yatReturnLink: String?
    var yatOrganizationName: String?
    var yatOrganizationKey: String?
    var yatWebServiceURL: URL?
    var yatApiURL: URL?

    let pushNotificationServer = "https://push.tari.com"

    #if DEBUG
    // Used for showing a little extra detail in the UI to help debugging
    private let isDebug = true
    let txTimeToExpire: TimeInterval = 60 * 60 * 24 * 1 // 1 day
    #else
    private let isDebug = false
    let txTimeToExpire: TimeInterval = 60 * 60 * 24 * 3 // 3 days
    #endif

    var isUnitTesting: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static let sharedKeychainGroup = KeychainWrapper(
        serviceName: "tari",
        accessGroup: "\(appleTeamID ?? "").com.tari.wallet.keychain"
    )
    static let groupIndentifier = "group.com.tari.wallet"
    static let storageDirectory: URL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: groupIndentifier
    )!
    static let testStoragePath: String = {
        let folderPath = storageDirectory.appendingPathComponent("test_tari_wallet").path
        if FileManager.default.fileExists(atPath: folderPath) {
            try? FileManager.default.removeItem(atPath: folderPath)
        }
        return folderPath
    }()

    var environment: AppEnvironment {
        if isDebug {
            return .debug
        } else if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return .testflight
        }

        return .production
    }

    private init() {
        TariLogger.info("Init settings...")
        TariLogger.warn("Environment: \(environment)")

        guard let envPath = Bundle.main.path(forResource: "env", ofType: "json") else {
            TariLogger.error("Could not find envrionment file")
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: envPath), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)

            if let jsonResult = jsonResult as? [String: AnyObject] {
                if let pushServerApiKey = jsonResult["pushServerApiKey"] as? String, !pushServerApiKey.isEmpty {
                    self.pushServerApiKey = pushServerApiKey
                } else {
                    TariLogger.warn("pushServerApiKey not set in env.json. Sending push notifications will be disabled.")
                }
                if let sentryPublicDSN = jsonResult["sentryPublicDSN"] as? String, !sentryPublicDSN.isEmpty {
                    self.sentryPublicDSN = sentryPublicDSN
                } else {
                    TariLogger.warn("sentryPublicDSN not set in env.json. Crash reporting will not work.")
                }

                if let giphyApiKey = jsonResult["giphyApiKey"] as? String, !giphyApiKey.isEmpty {
                    self.giphyApiKey = giphyApiKey
                } else {
                    TariLogger.warn("giphyApiKey not set in env.json. Appending gifs to transaction notes will not work.")
                }

                if let appleTeamID = jsonResult["appleTeamID"] as? String, !appleTeamID.isEmpty {
                    TariSettings.appleTeamID = appleTeamID
                } else {
                    fatalError("appleTeamID not set in env.json. Shared keychain will not work.")
                }
                if let yatReturnLink = jsonResult["yatReturnLink"] as? String, !yatReturnLink.isEmpty {
                    self.yatReturnLink = yatReturnLink
                } else {
                    fatalError("yatReturnLink not set in env.json. Yat related funtionalities will not work.")
                }
                if let yatOrganizationName = jsonResult["yatOrganizationName"] as? String, !yatOrganizationName.isEmpty {
                    self.yatOrganizationName = yatOrganizationName
                } else {
                    fatalError("yatOrganizationName not set in env.json. Yat related funtionalities will not work.")
                }
                if let yatOrganizationKey = jsonResult["yatOrganizationKey"] as? String, !yatOrganizationKey.isEmpty {
                    self.yatOrganizationKey = yatOrganizationKey
                } else {
                    fatalError("yatOrganizationKey not set in env.json. Yat related funtionalities will not work.")
                }
                if let yatWebServiceURL = jsonResult["yatWebServiceURL"] as? String, !yatWebServiceURL.isEmpty, let url = URL(string: yatWebServiceURL) {
                    self.yatWebServiceURL = url
                }
                if let yatApiURL = jsonResult["yatApiURL"] as? String, !yatApiURL.isEmpty, let url = URL(string: yatApiURL) {
                    self.yatApiURL = url
                }
            }
        } catch {
            TariLogger.error("Could not load env vars", error: error)
        }
    }
}
