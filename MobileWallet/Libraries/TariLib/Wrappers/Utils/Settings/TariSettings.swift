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

import SwiftKeychainWrapper

enum AppEnvironment {
    case debug
    case testflight
    case production
}

extension AppEnvironment {

    var name: String {
        switch self {
        case .debug:
            return "development"
        case .testflight:
            return "rc"
        case .production:
            return "production"
        }
    }
}

struct TariSettings {

    static let shared = TariSettings()
    static var showDisabledFeatures = false

    let walletSettings = WalletSettingsManager()

    let iCloudContainerIdentifier = "iCloud.com.tari.wallet"

    let tariUrl = "https://www.tari.com/"
    let contributeUrl = "https://www.github.com/tari-project/wallet-ios/"
    let disclaimer = "https://www.tari.com/disclaimer"
    let userAgreementUrl = "https://www.tari.com/user_agreement/"
    let privacyPolicyUrl = "https://www.tari.com/privacy_policy/"
    let storeUrl = "https://store.tarilabs.com/"
    let tariLabsUniversityUrl = "https://tlu.tarilabs.com/"
    let torBridgesUrl = "https://bridges.torproject.org/bridges?transport=obfs4"

    var pushServerApiKey: String?
    var sentryPublicDSN: String?
    static var appleTeamID: String?
    var giphyApiKey: String?
    var yatReturnLink: String?
    var yatOrganizationName: String?
    var yatOrganizationKey: String?
    var yatWebServiceURL: URL?
    var yatApiURL: URL?
    var dropboxApiKey: String?

    let pushNotificationServer = "https://push.tari.com"

    #if DEBUG
    // Used for showing a little extra detail in the UI to help debugging
    private let isDebug = true
    #else
    private let isDebug = false
    #endif

    static let sharedKeychainGroup = KeychainWrapper(
        serviceName: "tari",
        accessGroup: "\(appleTeamID ?? "").com.tari.wallet.keychain"
    )
    static let groupIndentifier = "group.com.tari.wallet"
    static let storageDirectory: URL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: groupIndentifier
    )!

    var environment: AppEnvironment {
        if isDebug {
            return .debug
        } else if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return .testflight
        }

        return .production
    }

    private init() {
        Logger.log(message: "Init settings...", domain: .general, level: .info)
        Logger.log(message: "Environment: \(environment)", domain: .general, level: .info)

        guard let envPath = Bundle.main.path(forResource: "env", ofType: "json") else {
            Logger.log(message: "Could not find envrionment file", domain: .general, level: .error)
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: envPath), options: .mappedIfSafe)
            guard let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: AnyObject] else { return }

            pushServerApiKey = jsonResult["pushServerApiKey"] as? String
            sentryPublicDSN = jsonResult["sentryPublicDSN"] as? String
            giphyApiKey = jsonResult["giphyApiKey"] as? String
            TariSettings.appleTeamID = jsonResult["appleTeamID"] as? String
            yatReturnLink = jsonResult["yatReturnLink"] as? String
            yatOrganizationName = jsonResult["yatOrganizationName"] as? String
            yatOrganizationKey = jsonResult["yatOrganizationKey"] as? String

            if let yatWebServiceRawURL = jsonResult["yatWebServiceURL"] as? String, !yatWebServiceRawURL.isEmpty, let url = URL(string: yatWebServiceRawURL) {
                yatWebServiceURL = url
            }

            if let yatApiRawURL = jsonResult["yatApiURL"] as? String, !yatApiRawURL.isEmpty, let url = URL(string: yatApiRawURL) {
                self.yatApiURL = url
            }

            dropboxApiKey = jsonResult["dropboxApiKey"] as? String
        } catch {
            Logger.log(message: "Could not load env vars: \(error)", domain: .general, level: .error)
        }
    }
}
