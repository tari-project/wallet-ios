//  FormTextField.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 02/03/2023
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
import Combine
import TariCommon

final class FormTextField: DynamicThemeView {

    // MARK: - Subviews

    @View private var textField: EmojiTextField = {
        let view = EmojiTextField()
        view.font = .Avenir.medium.withSize(14.0)
        return view
    }()

    @View private var separator = UIView()

    // MARK: - Properties

    var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    var returnKeyType: UIReturnKeyType {
        get { textField.returnKeyType }
        set { textField.returnKeyType = newValue }
    }

    var publisher: AnyPublisher<String, Never> {
        textField.textPublisher()
    }

    var isEmojiKeyboardVisible: Bool {
        get { textField.isEmojiKeyboardVisible }
        set { textField.isEmojiKeyboardVisible = newValue }
    }

    var onReturnPressed: (() -> Void)?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [textField, separator].forEach(addSubview)

        let constraints = [
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 26.0),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        textField.delegate = self
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        textField.textColor = theme.text.heading
        separator.backgroundColor = theme.neutral.secondary
    }

    // MARK: - First Responder

    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }
}

extension FormTextField: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturnPressed?()
        return false
    }
}
