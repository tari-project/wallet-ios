//  DeepLinkDefaultActionsHandler.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 29/05/2023
	Using Swift 5.0
	Running on macOS 13.0

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

enum DeepLinkDefaultActionsHandler {

    enum ActionType {
        case direct
        case popUp
        case notification
    }

    private struct ContactData {
        let name: String
        let address: String
    }

    // MARK: - Handlers

    static func handle(baseNodesAddDeeplink: BaseNodesAddDeeplink) throws {
        Task { @MainActor in
            self.showAddBaseNodePopUp(name: baseNodesAddDeeplink.name, peer: baseNodesAddDeeplink.peer)
        }
    }

    static func handle(contactListDeepLink: ContactListDeeplink, actionType: ActionType) throws {
        let contacts = contactData(deeplink: contactListDeepLink)
        try handle(deeplink: contactListDeepLink, contacts: contacts, actionType: actionType)
    }

    static func handle(userProfileDeepLink: UserProfileDeeplink, actionType: ActionType) throws {
        let contacts = contactData(deeplink: userProfileDeepLink)
        try handle(deeplink: userProfileDeepLink, contacts: contacts, actionType: actionType)
    }

    static func handle(transactionSendDeepLink: TransactionsSendDeeplink) {

        var amount: MicroTari?

        if let rawAmount = transactionSendDeepLink.amount {
            amount = MicroTari(rawAmount)
        }

        guard let addressComponents = try? TariAddress(base58: transactionSendDeepLink.receiverAddress).components else { return }
        let paymentInfo = PaymentInfo(addressComponents: addressComponents, alias: nil, yatID: nil, amount: amount, feePerGram: nil, note: transactionSendDeepLink.note)

        Task { @MainActor in
            AppRouter.presentSendTransaction(paymentInfo: paymentInfo)
        }
    }

    private static func handle(deeplink: DeepLinkable, contacts: [ContactData], actionType: ActionType) throws {
        switch actionType {
        case .direct:
            try add(contacts: contacts)
        case .popUp:
            Task { @MainActor in
                try await showAddContactsPopUp(contacts: contacts)
            }
        case .notification:
            try showAddContactsNotification(deeplink: deeplink, isSingleContact: contacts.count == 1)
        }
    }

    // MARK: - Pop Ups

    @MainActor private static func showAddBaseNodePopUp(name: String, peer: String) {

        let headerSection = PopUpHeaderWithSubtitle()
        headerSection.titleLabel.text = localized("add_base_node_overlay.label.title")
        headerSection.subtitleLabel.text = localized("add_base_node_overlay.label.subtitle")

        let contentSection = CustomDeeplinkPopUpContentView()
        contentSection.update(name: name, peer: peer)

        let buttonSection = PopUpComponentsFactory.makeButtonsView(models: [
            PopUpDialogButtonModel(title: localized("add_base_node_overlay.button.confirm"), type: .normal, callback: { try? Tari.shared.wallet(.main).connection.addBaseNode(name: name, peer: peer) }),
            PopUpDialogButtonModel(title: localized("common.close"), type: .text)
        ])

        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonSection)
        PopUpPresenter.show(popUp: popUp, configuration: .dialog(hapticType: .none))
    }

    @MainActor private static func showAddContactsPopUp(contacts: [ContactData]) async throws {
        guard await showAddContactsDialog(contacts: contacts) else { return }
        try add(contacts: contacts)
    }

    private static func showAddContactsDialog(contacts: [ContactData]) async -> Bool {

        let isPlural = contacts.count > 1

        let title = isPlural ? localized("contacts_received.popup.title.plural") : localized("contacts_received.popup.title.singular")
        let messagePart2 = isPlural ? localized("contacts_received.popup.message.part.2.plural.bold", arguments: contacts.count) : localized("contacts_received.popup.message.part.2.singular.bold")
        let messagePart3 = isPlural ? localized("contacts_received.popup.message.part.3.plural") : localized("contacts_received.popup.message.part.3.singular")
        let confirmButtonTitle = isPlural ? localized("contacts_received.popup.buttons.confirm.plural") : localized("contacts_received.popup.buttons.confirm.singular")

        return await withCheckedContinuation { continuation in

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
                    PopUpDialogButtonModel(title: confirmButtonTitle, type: .normal, callback: { continuation.resume(returning: true) }),
                    PopUpDialogButtonModel(title: localized("contacts_received.popup.buttons.reject"), type: .text, callback: { continuation.resume(returning: false) })
                ],
                hapticType: .success
            )

            DispatchQueue.main.async {
                PopUpPresenter.showPopUp(model: model)
            }
        }
    }

    // MARK: - Notifications

    private static func showAddContactsNotification(deeplink: DeepLinkable, isSingleContact: Bool) throws {
        guard let rawEncodedDeeplink = try DeepLinkFormatter.deeplink(model: deeplink)?.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else { return }
        LocalNotificationsManager.shared.showContactsReceivedNotification(rawEncodedDeeplink: rawEncodedDeeplink, isSingleContact: isSingleContact)
    }

    // MARK: - Actions

    private static func contactData(deeplink: ContactListDeeplink) -> [ContactData] {
        deeplink.list.map { ContactData(name: $0.alias, address: $0.tariAddress) }
    }

    private static func contactData(deeplink: UserProfileDeeplink) -> [ContactData] {
        [ContactData(name: deeplink.alias, address: deeplink.tariAddress)]
    }

    private static func add(contacts: [ContactData]) throws {

        let contactsManager = ContactsManager()

        try contacts.forEach {

            let address = try TariAddress(base58: $0.address)

            if Tari.shared.wallet(.main).isWalletRunning.value {
                _ = try contactsManager.createInternalModel(name: $0.name, isFavorite: false, address: address)
            } else {
                try PendingDataManager.shared.storeContact(name: $0.name, isFavorite: false, address: address)
            }
        }
    }
}
