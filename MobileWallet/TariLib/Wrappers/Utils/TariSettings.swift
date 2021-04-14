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

enum TariNetwork: String {
    case mainnet = "mainnet"
    case rincewind = "rincewind"
    case ridcully = "ridcully"
    case stibbons = "stibbons"

    var currencyDisplayTicker: String {
        switch self {
        case .rincewind:
            return "tXTR"
        default:
            return "XTR"
        }
    }
}

enum AppEnvironment {
    case debug
    case testflight
    case production
}

struct TariSettings {
    static let shared = TariSettings()

    let network: TariNetwork = .stibbons //TODO this will come from a build config
    let discoveryTimeoutSec: UInt64 = 20
    let safMessageDurationSec: UInt64 = 10800
    let deeplinkURI = "tari"

    let faucetServer = "https://faucet.tari.com"

    let iCloudContainerIdentifier = "iCloud.com.tari.wallet"

    let tariUrl = "https://www.tari.com/"
    let contributeUrl = "https://www.github.com/tari-project/wallet-ios/"
    let disclaimer = "https://www.tari.com/disclaimer"
    let userAgreementUrl = "https://www.tari.com/user_agreement/"
    let privacyPolicyUrl = "https://www.tari.com/privacy_policy/"
    let storeUrl = "https://store.tarilabs.com/"
    let bugReportEmail = "bug_reports@tari.com"

    let defaultBaseNodePool: [String: String] = [
        "t-tbn-ncal": "b60d073e2f2337fdd95a58065e1d0182cca1d36c20ed10b27bc1232bc2836a17::/onion3/ssiz76b33emcerusblo6wba3ejqsub6ihkabjilem6ygoldodf6aenid:18141",
        "t-tbn-oregon": "e2cef0473117da34108dd85d4425536b8a1f317478686a6d7a0bbb5c800a747d::/onion3/3eiacmnozk7rcvrx7brhlssnpueqsjdsfbfmq63d2bk7h3vtah35tcyd:18141",
        "t-tbn-london": "f606c82d23b2a2eda65156cef9efcaf77031d16a681fca99af7c08e98035f21d::/onion3/i7nsgt2p7tkvpnhygnvihpuaqlunbtw3zti3qvi3eur7obkjkwgla4id:18141",
        "t-tbn-stockholm": "d23cfeb05674d25c5b970b6bffefdc1e7c2c1f1f9c32fde04688d1b94c81705a::/onion3/obfjpoon2hm4uqerirhp4sf26bvq5ztokxhq274c2fg2uadrsu5drnqd:18141",
        "t-tbn-seoul": "9cedfc16708f857e070e32d9cc1939fd6a57b5945ee97fdc707aa2f034ba6507::/onion3/ryfa3iufgmvwmghyhamkjz5rfygde6kmy7e5jn5oc2n44cpbvey654ad:18141",
        "t-tbn-sydney": "50ee725e2c6ca8282ab62bb7aef52a9c4df283ec99e00497a358dbaf4112ff0c::/onion3/yrzdnyayg2jqym7rmeoc3lwixylasokqwkrtqyvutobllz27jdznuoyd:18141"
    ]

    var pushServerApiKey: String?
    var sentryPublicDSN: String?
    static var appleTeamID: String?
    var giphyApiKey: String?

    func getRandomBaseNode() -> String {
        let keys = defaultBaseNodePool.map { (entry) -> String in entry.key }
        return defaultBaseNodePool[keys[Int.random(in: 0 ... (defaultBaseNodePool.count-1))]]!
    }

    let pushNotificationServer = "https://push.tari.com"

    #if DEBUG
    //Used for showing a little extra detail in the UI to help debugging
    private let isDebug = true
    let maxMbLogsStorage: UInt64 = 5000 //5GB
    let txTimeToExpire: TimeInterval = 60 * 60 * 24 * 1 //1 day
    #else
    private let isDebug = false
    let maxMbLogsStorage: UInt64 = 500 //500MB
    let txTimeToExpire: TimeInterval = 60 * 60 * 24 * 3 //3 days
    #endif

    var isUnitTesting: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static let sharedKeychainGroup = KeychainWrapper(
        serviceName: "tari",
        accessGroup: "\(appleTeamID ?? "").com.tari.wallet.keychain"
    )
    static let groupIndentifier = "group.com.tari.wallet"
    static let groupUserDefaults: UserDefaults = UserDefaults(suiteName: groupIndentifier)!
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
            }
        } catch {
            TariLogger.error("Could not load env vars", error: error)
        }
    }
}
