//  PopPresenter+ContactBook.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 08/03/2023
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

extension PopUpPresenter {

    @MainActor static func showUnlinkConfirmationDialog(emojiID: String, name: String, confirmationCallback: @escaping () -> Void) {

        let model = PopUpDialogModel(
            titleComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.unlink_contact.popup.confirmation.title"), style: .normal)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.unlink_contact.popup.confirmation.message.part1", arguments: emojiID), style: .normal),
                StylizedLabel.StylizedText(text: name, style: .bold)
            ],
            buttons: [
                PopUpDialogButtonModel(title: localized("common.confirm"), type: .normal, callback: { confirmationCallback() }),
                PopUpDialogButtonModel(title: localized("common.cancel"), type: .text)
            ],
            hapticType: .none
        )

        showPopUp(model: model)
    }

    @MainActor static func showUnlinkSuccessDialog(emojiID: String, name: String) {

        let model = PopUpDialogModel(
            titleComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.unlink_contact.popup.success.title"), style: .normal)
            ],
            messageComponents: [
                StylizedLabel.StylizedText(text: localized("contact_book.unlink_contact.popup.success.message.part1", arguments: emojiID), style: .normal),
                StylizedLabel.StylizedText(text: name, style: .bold)
            ],
            buttons: [
                PopUpDialogButtonModel(title: localized("common.close"), type: .text)
            ],
            hapticType: .none
        )

        showPopUp(model: model)
    }
}
