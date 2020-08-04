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

enum TariNetwork: String {
    case mainnet = "mainnet"
    case rincewind = "rincewind"

    var currencyDisplayTicker: String {
        switch self {
        case .rincewind:
            return "tXTR"
        default:
            return "XTR"
        }
    }

    var networkDisplayName: String {
        switch self {
        case .rincewind:
            return "testnet"
        default:
            return "mainnet"
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

    let network: TariNetwork = .rincewind //TODO this will come from a build config
    let discoveryTimeoutSec: UInt64 = 20
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
        "faucet": "2e93c460df49d8cfbbf7a06dd9004c25a84f92584f7d0ac5e30bd8e0beee9a43::/onion3/nuuq3e2olck22rudimovhmrdwkmjncxvwdgbvfxhz6myzcnx2j4rssyd:18141",
        "t-tbn-nvir": "06e98e9c5eb52bd504836edec1878eccf12eb9f26a5fe5ec0e279423156e657a::/onion3/bsmuof2cn4y2ysz253gzsvg3s72fcgh4f3qcm3hdlxdtcwe6al2dicyd:18141",
        "t-tbn-ncal": "3a5081a0c9ff72b2d5cf52f8d78cc5a206d643259cdeb7d934512f519e090e6c::/onion3/gfynjxfm7rcxcekhu6jwuhvyyfdjvmruvvehurmlte565v74oinv2lad:18141",
        "t-tbn-oregon": "e6f3c83dc592af45ede5424974f52c776e9e6859e530066e57c1b0dd59d9b61c::/onion3/ixihtmcbvr2q53bj23bsla5hi7ek37odnsxzkapr7znyfneqxzhq7zad:18141",
        "t-tbn-london": "ce2254825d0e0294d31a86c6aac18f83c9a7b3d01d9cdb6866b4b2af8fd3fd17::/onion3/gm7kxmr4cyjg5fhcw4onav2ofa3flscrocfxiiohdcys3kshdhcjeuyd:18141",
        "t-tbn-stockholm": "461d4d7be657521969896f90e3f611f0c4e902ca33d3b808c03357ad86fd7801::/onion3/4me2aw6auq2ucql34uuvsegtjxmvsmcyk55qprtrpqxvu3whxajvb5ad:18141",
        "t-tbn-seoul": "d440b328e69b20dd8ee6c4a61aeb18888939f0f67cf96668840b7f72055d834c::/onion3/j5x7xkcxnrich5lcwibwszd5kylclbf6a5unert5sy6ykio2kphnopad:18141",
        "t-tbn-sydney": "b81b4071f72418cc410166d9baf0c6ef7a8c309e64671fafbbed88f7e1ee7709::/onion3/lwwcv4nq7epgem5vdcawom4mquqsw2odbwfcjzv3j6sksx4gr24e52ad:18141"
    ]

    var pushServerApiKey: String?
    var sentryPublicDSN: String?
    var appleTeamID: String?
    var giphyApiKey: String?

    func getRandomBaseNode() -> String {
        let keys = defaultBaseNodePool.map { (entry) -> String in entry.key }
        return defaultBaseNodePool[keys[Int.random(in: 0 ... (defaultBaseNodePool.count-1))]]!
    }

    let pushNotificationServer = "https://push.tari.com"

    #if DEBUG
    let torEnabled = true //If just working on UI updates, this can be made false
    //Used for showing a little extra detail in the UI to help debugging
    private let isDebug = true
    let maxMbLogsStorage: UInt64 = 5000 //5GB
    let expirePendingTransactionsAfter: TimeInterval = 60 * 60 * 24 * 1 //1 day
    #else
    let torEnabled = true
    private let isDebug = false
    let maxMbLogsStorage: UInt64 = 500 //500MB
    let expirePendingTransactionsAfter: TimeInterval = 60 * 60 * 24 * 3 //3 days
    #endif

    var isUnitTesting: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static let groupIndentifier = "group.com.tari.wallet"
    static let groupUserDefaults: UserDefaults = UserDefaults(suiteName: groupIndentifier)!
    static let storageDirectory: URL = FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: groupIndentifier)!
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
                    self.appleTeamID = appleTeamID
                } else {
                    fatalError("appleTeamID not set in env.json. Shared keychain will not work.")
                }
            }
        } catch {
            TariLogger.error("Could not load env vars", error: error)
        }
    }
}
