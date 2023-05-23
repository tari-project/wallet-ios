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

protocol DeeplinkHandlable {
    func handle(deeplink: TransactionsSendDeeplink)
    func handle(deeplink: BaseNodesAddDeeplink)
    func handle(deeplink: ContactListDeeplink)
}

enum DeeplinkError: Error {
    case unknownDeeplink
    case transactionSendDeeplinkError(_ error: Error)
    case baseNodesAddDeeplinkError(_ error: Error)
    case contactListDeeplinkError(_ error: Error)
}

enum DeeplinkHandler {

    static func handle(rawDeeplink: String, handler: DeeplinkHandlable? = nil) throws {
        guard let decodedDeeplink = rawDeeplink.removingPercentEncoding, let deeplink = URL(string: decodedDeeplink) else { throw DeeplinkError.unknownDeeplink }
        return try handle(deeplink: deeplink, handler: handler)
    }

    static func handle(deeplink: URL, handler: DeeplinkHandlable? = nil) throws {
        switch deeplink.path {
        case TransactionsSendDeeplink.command:
            try handle(transactionSendDeeplink: deeplink, handler: handler)
        case BaseNodesAddDeeplink.command:
            try handle(baseNodesAddDeeplink: deeplink, handler: handler)
        case ContactListDeeplink.command:
            try handle(contactListDeeplink: deeplink, handler: handler)
        default:
            throw DeeplinkError.unknownDeeplink
        }
    }

    private static func handle(transactionSendDeeplink: URL, handler: DeeplinkHandlable?) throws {

        do {
            let deeplink = try DeepLinkFormatter.model(type: TransactionsSendDeeplink.self, deeplink: transactionSendDeeplink)

            guard let handler = handler else {
                AppRouter.moveToTransactionSend(deeplink: deeplink)
                return
            }

            handler.handle(deeplink: deeplink)
        } catch {
            throw DeeplinkError.transactionSendDeeplinkError(error)
        }
    }

    private static func handle(baseNodesAddDeeplink: URL, handler: DeeplinkHandlable?) throws {

        do {
            let deeplink = try DeepLinkFormatter.model(type: BaseNodesAddDeeplink.self, deeplink: baseNodesAddDeeplink)
            _ = try BaseNode(name: deeplink.name, peer: deeplink.peer)

            guard let handler = handler else {
                showCustomDeeplinkPopUp(name: deeplink.name, peer: deeplink.peer)
                return
            }

            handler.handle(deeplink: deeplink)
        } catch {
            throw DeeplinkError.baseNodesAddDeeplinkError(error)
        }
    }

    private static func handle(contactListDeeplink: URL, handler: DeeplinkHandlable?) throws {

        do {
            let deeplink = try DeepLinkFormatter.model(type: ContactListDeeplink.self, deeplink: contactListDeeplink)

            guard let handler = handler else {
                handle(contactListDeeplink: deeplink, rawDeeplink: contactListDeeplink)
                return
            }

            handler.handle(deeplink: deeplink)
        } catch {
            throw DeeplinkError.contactListDeeplinkError(error)
        }
    }

    private static func handle(contactListDeeplink: ContactListDeeplink, rawDeeplink: URL) {

        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState == .background else {
                showAddContactsDialog(deeplink: contactListDeeplink) {
                    try? addContacts(deeplink: contactListDeeplink)
                }
                return
            }

            guard let rawEncodedDeeplink = rawDeeplink.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
                Logger.log(message: "Unable to encode deeplink", domain: .general, level: .error)
                return
            }

            LocalNotificationsManager.shared.showContactsReceivedNotification(rawEncodedDeeplink: rawEncodedDeeplink, isSingleContact: contactListDeeplink.list.count == 1)
        }
    }

    private static func showAddContactsDialog(deeplink: ContactListDeeplink, onConfrim: @escaping () -> Void) {

        let contactCount = deeplink.list.count
        let isPlural = contactCount > 1

        let title = isPlural ? localized("contacts_received.popup.title.plural") : localized("contacts_received.popup.title.singular")
        let messagePart2 = isPlural ? localized("contacts_received.popup.message.part.2.plural.bold", arguments: contactCount) : localized("contacts_received.popup.message.part.2.singular.bold")
        let messagePart3 = isPlural ? localized("contacts_received.popup.message.part.3.plural") : localized("contacts_received.popup.message.part.3.singular")
        let confirmButtonTitle = isPlural ? localized("contacts_received.popup.buttons.confirm.plural") : localized("contacts_received.popup.buttons.confirm.singular")

        let model = PopUpDialogModel(
            titleComponents: [
                StylizedLabel.StylizedText(text: title, style: .normal)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("contacts_received.popup.message.part.1"), style: .normal),
                StylizedLabel.StylizedText(text: messagePart2, style: .bold),
                StylizedLabel.StylizedText(text: messagePart3, style: .normal)
            ],
            buttons: [
                PopUpDialogButtonModel(title: confirmButtonTitle, type: .normal, callback: onConfrim),
                PopUpDialogButtonModel(title: localized("contacts_received.popup.buttons.reject"), type: .text)
            ],
            hapticType: .success
        )

        PopUpPresenter.showPopUp(model: model)
    }

    private static func addContacts(deeplink: ContactListDeeplink) throws {

        let contactsManager = ContactsManager()

        try deeplink.list
            .forEach {
                let address = try TariAddress(hex: $0.hex)

                if Tari.shared.isWalletConnected {
                    _ = try contactsManager.createInternalModel(name: $0.alias, isFavorite: false, address: address)
                } else {
                    try PendingDataManager.shared.storeContact(name: $0.alias, isFavorite: false, address: address)
                }
            }
    }

    private static func showCustomDeeplinkPopUp(name: String, peer: String) {

        let headerSection = PopUpHeaderWithSubtitle()
        headerSection.titleLabel.text = localized("add_base_node_overlay.label.title")
        headerSection.subtitleLabel.text = localized("add_base_node_overlay.label.subtitle")

        let contentSection = CustomDeeplinkPopUpContentView()
        contentSection.update(name: name, peer: peer)

        let buttonSection = PopUpComponentsFactory.makeButtonsView(models: [
            PopUpDialogButtonModel(title: localized("add_base_node_overlay.button.confirm"), type: .normal, callback: { try? Tari.shared.connection.addBaseNode(name: name, peer: peer) }),
            PopUpDialogButtonModel(title: localized("common.close"), type: .text)
        ])

        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonSection)
        PopUpPresenter.show(popUp: popUp, configuration: .dialog(hapticType: .none))
    }
}
