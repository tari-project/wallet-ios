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

enum DeeplinkHandler {
    
    static func handle(deeplink: URL) throws {
        
        guard !handle(legacyDeeplink: deeplink) else { return }
        
        switch deeplink.path {
        case TransactionsSendDeeplink.command:
            try handle(transactionSendDeeplink: deeplink)
        case BaseNodesAddDeeplink.command:
            try handle(baseNodesAddDeeplink: deeplink)
        default:
            break
        }
    }
    
    @available(*, deprecated, message: "This method will be removed in the near future")
    private static func handle(legacyDeeplink: URL) -> Bool {
        guard let components = URLComponents(url: legacyDeeplink, resolvingAgainstBaseURL: false), components.scheme == "tari", components.host == NetworkManager.shared.selectedNetwork.name else { return false }
        
        let pathComponents = components.path
            .split(separator: "/")
            .filter { !$0.isEmpty }
        
        guard pathComponents.count == 2, pathComponents[0] == "pubkey" else { return false }
        
        let publicKey = String(pathComponents[1])
        let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name] = $1.value } ?? [:]
        
        var amount: UInt64?
        if let rawAmount = queryItems["amount"] {
            amount = UInt64(rawAmount)
        }
        let note = queryItems["note"]
        
        let deeplink = TransactionsSendDeeplink(receiverPublicKey: publicKey, amount: amount, note: note)
        AppRouter.moveToTransactionSend(deeplink: deeplink)
        
        return true
    }
    
    private static func handle(transactionSendDeeplink: URL) throws {
        let deeplink = try DeepLinkFormatter.model(type: TransactionsSendDeeplink.self, deeplink: transactionSendDeeplink)
        AppRouter.moveToTransactionSend(deeplink: deeplink)
    }
    
    private static func handle(baseNodesAddDeeplink: URL) throws {
        
        let model = try DeepLinkFormatter.model(type: BaseNodesAddDeeplink.self, deeplink: baseNodesAddDeeplink)
        _ = try BaseNode(name: model.name, peer: model.peer)
        
        UserFeedback.shared.callToAction(
            title: localized("add_base_node_overlay.label.title"),
            description: localized("add_base_node_overlay.label.description", arguments: model.name, model.peer),
            actionTitle: localized("add_base_node_overlay.button.confirm"),
            cancelTitle: localized("common.close"),
            onAction: { try? BaseNodeManager.addBaseNode(name: model.name, peer: model.peer) }
        )
    }
}