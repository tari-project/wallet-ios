//  FormOverlayPresenter.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 17/04/2023
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

import UIKit

enum FormOverlayPresenter {

    static func showForm(title: String, rightButtonTitle: String? = localized("common.done"), textFieldModels: [ContactBookFormView.TextFieldViewModel], presenter: UIViewController, onClose: @escaping () -> Void) {

        let formView = ContactBookFormView(title: title, rightButtonTitle: rightButtonTitle, textFieldsModels: textFieldModels)
        let overlay = FormOverlay(formView: formView)
        overlay.onClose = onClose

        presenter.present(overlay, animated: true)
    }
}

extension FormOverlayPresenter {

    static func showSingleFieldContactEditForm(isContactExist: Bool, alias: String, presenter: UIViewController, onClose: ((String) -> Void)?) {

        var alias = alias
        let title = isContactExist ? localized("contact_book.details.edit_form.title.edit") : localized("contact_book.details.edit_form.title.add")

        let models = [
            ContactBookFormView.TextFieldViewModel(
                placeholder: localized("contact_book.details.edit_form.text_field.name"),
                text: alias,
                isEmojiKeyboardVisible: false,
                callback: { alias = $0 }
            )
        ]

        showForm(title: title, textFieldModels: models, presenter: presenter) {
            onClose?(alias)
        }
    }

    static func showTwoFieldsContactEditForm(isContactExist: Bool, nameComponents: [String], presenter: UIViewController, onClose: ((_ nameComponents: [String]) -> Void)?) {

        var nameComponents = nameComponents
        let title = isContactExist ? localized("contact_book.details.edit_form.title.edit") : localized("contact_book.details.edit_form.title.add")

        let models = [
            ContactBookFormView.TextFieldViewModel(
                placeholder: localized("contact_book.details.edit_form.text_field.first_name"),
                text: nameComponents[0],
                isEmojiKeyboardVisible: false,
                callback: { nameComponents[0] = $0 }
            ),
            ContactBookFormView.TextFieldViewModel(
                placeholder: localized("contact_book.details.edit_form.text_field.last_name"),
                text: nameComponents[1],
                isEmojiKeyboardVisible: false,
                callback: { nameComponents[1] = $0 }
            )
        ]

        showForm(title: title, textFieldModels: models, presenter: presenter) {
            onClose?(nameComponents)
        }
    }

    static func showFullContactEditForm(isContactExist: Bool, nameComponents: [String], yat: String, presenter: UIViewController, onClose: ((_ nameComponents: [String], _ yat: String) -> Void)?) {

        var nameComponents = nameComponents
        var yat = yat

        let title = isContactExist ? localized("contact_book.details.edit_form.title.edit") : localized("contact_book.details.edit_form.title.add")

        let models = [
            ContactBookFormView.TextFieldViewModel(
                placeholder: localized("contact_book.details.edit_form.text_field.first_name"),
                text: nameComponents[0],
                isEmojiKeyboardVisible: false,
                callback: { nameComponents[0] = $0 }
            ),
            ContactBookFormView.TextFieldViewModel(
                placeholder: localized("contact_book.details.edit_form.text_field.last_name"),
                text: nameComponents[1],
                isEmojiKeyboardVisible: false,
                callback: { nameComponents[1] = $0 }
            ),
            ContactBookFormView.TextFieldViewModel(
                placeholder: localized("contact_book.details.edit_form.text_field.yat"),
                text: yat,
                isEmojiKeyboardVisible: true,
                callback: { yat = $0 }
            )
        ]

        showForm(title: title, textFieldModels: models, presenter: presenter) {
            onClose?(nameComponents, yat)
        }
    }

    static func showSelectCustomBaseNodeForm(hex: String?, address: String?, presenter: UIViewController, onClose: ((_ hex: String?, _ address: String?) -> Void)?) {

        var hex = hex
        var address = address

        let title = localized("restore_from_seed_words.form.title")
        let models = [
            ContactBookFormView.TextFieldViewModel(placeholder: localized("restore_from_seed_words.form.placeholder.hex"), text: hex, isEmojiKeyboardVisible: false, callback: { hex = $0 }),
            ContactBookFormView.TextFieldViewModel(placeholder: localized("restore_from_seed_words.form.placeholder.address"), text: address, isEmojiKeyboardVisible: false, callback: { address = $0 })
        ]

        showForm(title: title, textFieldModels: models, presenter: presenter) {
            onClose?(hex, address)
        }
    }

    static func showAddBaseNodeForm(presenter: UIViewController, onClose: ((_ name: String, _ hex: String, _ address: String) -> Void)?) {

        var name = ""
        var hex = ""
        var address = ""

        showForm(
            title: localized("add_base_node.form.title"),
            rightButtonTitle: localized("add_base_node.form.button.save"),
            textFieldModels: [
                ContactBookFormView.TextFieldViewModel(placeholder: localized("add_base_node.form.text_field.placeholder.name"), text: nil, isEmojiKeyboardVisible: false, callback: { name = $0 }),
                ContactBookFormView.TextFieldViewModel(placeholder: localized("add_base_node.form.text_field.placeholder.hex"), text: nil, isEmojiKeyboardVisible: false, callback: { hex = $0 }),
                ContactBookFormView.TextFieldViewModel(placeholder: localized("add_base_node.form.text_field.placeholder.address"), text: nil, isEmojiKeyboardVisible: false, callback: { address = $0 })
            ],
            presenter: presenter,
            onClose: { onClose?(name, hex, address) }
        )
    }
}
