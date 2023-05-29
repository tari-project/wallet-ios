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

    static func handleInForeground(contactListDeeplink: ContactListDeeplink) async throws -> Bool {
        try await Task.sleep(nanoseconds: 500000000) // FIXME: Replace it with App state handler
        guard await showAddContactsDialog(deeplink: contactListDeeplink) else { return false }
        try addContacts(deeplink: contactListDeeplink)
        return true
    }

    private static func showAddContactsDialog(deeplink: ContactListDeeplink) async -> Bool {

        let contactCount = deeplink.list.count
        let isPlural = contactCount > 1

        let title = isPlural ? localized("contacts_received.popup.title.plural") : localized("contacts_received.popup.title.singular")
        let messagePart2 = isPlural ? localized("contacts_received.popup.message.part.2.plural.bold", arguments: contactCount) : localized("contacts_received.popup.message.part.2.singular.bold")
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
}
