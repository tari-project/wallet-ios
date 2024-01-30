//  DeeplinkHandler.swift

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

enum DeeplinkHandler {

    private static var storedDeeplink: DeepLinkable?

    static func deeplink(rawDeeplink: String) throws -> DeepLinkable? {

        guard let deeplink = URL(string: rawDeeplink) else { return nil }
        guard let type = DeeplinkType(rawValue: deeplink.path) else { return nil }

        switch type {
        case .transactionSend:
            return try DeepLinkFormatter.model(type: TransactionsSendDeeplink.self, deeplink: deeplink)
        case .baseNodesAdd:
            return try DeepLinkFormatter.model(type: BaseNodesAddDeeplink.self, deeplink: deeplink)
        case .contacts:
            return try DeepLinkFormatter.model(type: ContactListDeeplink.self, deeplink: deeplink)
        case .profile:
            return try DeepLinkFormatter.model(type: UserProfileDeeplink.self, deeplink: deeplink)
        }
    }

    static func handle(rawDeeplink: String, showDefaultDialogIfNeeded: Bool) throws {
        guard let deeplink = try deeplink(rawDeeplink: rawDeeplink) else { return }
        try handle(deeplink: deeplink, showDefaultDialogIfNeeded: showDefaultDialogIfNeeded)
    }

    static func handle(deeplink: DeepLinkable, showDefaultDialogIfNeeded: Bool) throws {

        let actionType: DeepLinkDefaultActionsHandler.ActionType

        if showDefaultDialogIfNeeded {
            actionType = UIApplication.shared.applicationState == .background ? .notification : .popUp
        } else {
            actionType = .direct
        }

        if actionType == .popUp, !(Tari.shared.isWalletConnected && AppRouter.isNavigationReady) {
            retryHandle(deeplink: deeplink)
            return
        }

        switch deeplink.type {
        case .baseNodesAdd:
            try handle(baseNodesAddDeeplink: deeplink)
        case .contacts:
            try handle(contactsDeepLink: deeplink, actionType: actionType)
        case .profile:
            try handle(userProfileDeepLink: deeplink, actionType: actionType)
        case .transactionSend:
            handle(transactionSendDeepLink: deeplink)
        }
    }

    private static func handle(baseNodesAddDeeplink: DeepLinkable) throws {
        guard let deeplink = baseNodesAddDeeplink as? BaseNodesAddDeeplink else { return }
        try DeepLinkDefaultActionsHandler.handle(baseNodesAddDeeplink: deeplink)
    }

    private static func handle(contactsDeepLink: DeepLinkable, actionType: DeepLinkDefaultActionsHandler.ActionType) throws {
        guard let deeplink = contactsDeepLink as? ContactListDeeplink else { return }
        try DeepLinkDefaultActionsHandler.handle(contactListDeepLink: deeplink, actionType: actionType)
    }

    private static func handle(userProfileDeepLink: DeepLinkable, actionType: DeepLinkDefaultActionsHandler.ActionType) throws {
        guard let deeplink = userProfileDeepLink as? UserProfileDeeplink else { return }
        try DeepLinkDefaultActionsHandler.handle(userProfileDeepLink: deeplink, actionType: actionType)
    }

    private static func handle(transactionSendDeepLink: DeepLinkable) {
        guard let deeplink = transactionSendDeepLink as? TransactionsSendDeeplink else { return }
        DeepLinkDefaultActionsHandler.handle(transactionSendDeepLink: deeplink)
    }

    private static func retryHandle(deeplink: DeepLinkable) {
        storedDeeplink = deeplink
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let storedDeeplink else { return }
            self.storedDeeplink = nil
            try? handle(deeplink: storedDeeplink, showDefaultDialogIfNeeded: true)
        }
    }
}
