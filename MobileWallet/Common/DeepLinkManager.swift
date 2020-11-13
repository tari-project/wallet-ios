//  DeepLinkManager.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/03/18
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

import UIKit

enum DeeplinkType {
   case send(deeplink: String?)
   case showQR
}

let deepLinker = DeepLinkManager()

class DeepLinkManager {
    fileprivate init() {}

    private var deeplinkType: DeeplinkType?

    // check existing deepling and perform action
    func checkDeepLink() {
        //No deep link to see here
        guard let deeplinkType = deeplinkType else {
            return
        }

        if let tabBar = UIApplication.shared.menuTabBarController {
            //Slight delay so the home view finishes loading. Else next view ends up without a navbar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DeeplinkNavigator.shared.proceedToDeeplink(deeplinkType, tabBar: tabBar)
            }

            self.deeplinkType = nil
        }
    }

    @discardableResult
    func handleShortcut(item: UIApplicationShortcutItem) -> Bool {
        deeplinkType = ShortcutParser.shared.handleShortcut(item)
        return deeplinkType != nil
    }

    func handleShortcut(type: DeeplinkType) {
        deeplinkType = type
    }
}

class DeeplinkNavigator {
    static let shared = DeeplinkNavigator()
    private init() {}

    func proceedToDeeplink(_ type: DeeplinkType, tabBar: MenuTabBarController) {
        let homeVC = tabBar.homeViewController
        switch type {
        case .send(deeplink: let link):
            if let deeplink = link {
                do {
                    let pubKey = try PublicKey(deeplink: deeplink)
                    let params = try DeepLinkParams(deeplink: deeplink)
                    homeVC.onSend(pubKey: pubKey, deepLinkParams: params)
                } catch {
                    UserFeedback.shared.error(
                        title: localized("deep_link.error.title"),
                        description: localized("deep_link.error.emoji_from_link"),
                        error: error
                    )
                }
            } else {
                homeVC.onSend()
            }
        case .showQR:
            tabBar.setTab(.profile)
        }
    }
}

enum ShortcutKey: String {
    case showQR = "show-qr"
    case send = "send"
}

class ShortcutParser {
    static let shared = ShortcutParser()
    private init() { }

    func registerShortcuts() {
        let showQRShortcutItem = UIApplicationShortcutItem(
            type: ShortcutKey.showQR.rawValue,
            localizedTitle: NSLocalizedString(
                "shortcut.show_my_qr",
                comment: "Home screen shortcut"
            ),
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(templateImageName: "qr"),
            userInfo: nil
        )

        let sendShortcutItem = UIApplicationShortcutItem(
            type: ShortcutKey.send.rawValue,
            localizedTitle: String(
                format: NSLocalizedString(
                    "common.send.with_param",
                    comment: "Common"
                ),
                TariSettings.shared.network.currencyDisplayTicker
            ),
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(templateImageName: "Gem"),
            userInfo: nil
        )

        UIApplication.shared.shortcutItems = [showQRShortcutItem, sendShortcutItem]
    }

    func handleShortcut(_ shortcut: UIApplicationShortcutItem) -> DeeplinkType? {
       switch shortcut.type {
       case ShortcutKey.showQR.rawValue:
          return .showQR
       case ShortcutKey.send.rawValue:
          return .send(deeplink: nil)
       default:
          return nil
       }
    }
}
