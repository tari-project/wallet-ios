//  ShortcutsManager.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 02/03/2022
	Using Swift 5.0
	Running on macOS 12.1

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

final class ShortcutsManager {
    
    private enum ShortcutType: String {
        case showQR = "show-qr"
        case send = "send"
    }
    
    private static var queuedShortcut: UIApplicationShortcutItem?
    
    private init() {}
    
    static func configureShortcuts() {
        
        let qrCodeShortcutItem = UIApplicationShortcutItem(
            type: ShortcutType.showQR.rawValue,
            localizedTitle: localized("shortcut.show_my_qr"),
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(templateImageName: "qr"),
            userInfo: nil
        )
        
        let sendShortcutItem = UIApplicationShortcutItem(
            type: ShortcutType.send.rawValue,
            localizedTitle: localized("common.send.with_param", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol),
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(templateImageName: "Gem"),
            userInfo: nil
        )
        
        UIApplication.shared.shortcutItems = [qrCodeShortcutItem, sendShortcutItem]
    }
    
    static func handle(shortcut: UIApplicationShortcutItem) {
        
        guard let type = ShortcutType(rawValue: shortcut.type) else { return }
        
        guard AppRouter.isNavigationReady else {
            queuedShortcut = shortcut
            return
        }
        
        queuedShortcut = nil
        
        switch type {
        case .showQR:
            AppRouter.moveToProfile()
        case .send:
            AppRouter.moveToTransactionSend(deeplink: nil)
        }
    }
    
    static func executeQueuedShortcut() {
        guard let shortcut = queuedShortcut else { return }
        handle(shortcut: shortcut)
    }
}
