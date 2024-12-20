//  TokenInputView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 23/07/2021
	Using Swift 5.0
	Running on macOS 12.0

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
import TariCommon

final class TokenInputView: DynamicThemeCollectionCell {

    // MARK: - Subviews

    @View var toolbar = TokensToolbar()

    @View var textField: ObservableTextField = {
        let view = ObservableTextField()
        view.font = Theme.shared.fonts.restoreFromSeedWordsToken
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.spellCheckingType = .no
        view.isSecureTextEntry = false
        view.isUserInteractionEnabled = true
        
        return view
    }()

    // MARK: - Properties

    var onTextChange: ((String) -> Void)?
    var onRemovingCharacterAtFirstPosition: ((String) -> Void)?
    var onEndEditing: ((String) -> Void)?

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupFeedbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        textField.inputAccessoryView = toolbar
    }

    private func setupConstraints() {

        addSubview(textField)

        let constraints = [
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 3.0),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.0),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3.0),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0.0),
            textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 24.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupFeedbacks() {
        textField.addTarget(self, action: #selector(onTextChangeAction), for: .editingChanged)
        textField.delegate = self

        textField.onRemovingCharacterAtFirstPosition = { [weak self] in
            self?.onRemovingCharacterAtFirstPosition?($0)
        }

        toolbar.onTapOnToken = { [weak self] in
            self?.textField.text = $0 + " "
            self?.onTextChangeAction()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        textField.textColor = theme.text.body
    }

    // MARK: - First Responder

    override func becomeFirstResponder() -> Bool { textField.becomeFirstResponder() }

    // MARK: - Target Actions

    @objc private func onTextChangeAction() {
        onTextChange?(textField.text ?? "")
    }

    override func resignFirstResponder() -> Bool {
        onEndEditing?(textField.text ?? "")
        return textField.resignFirstResponder()
    }
    
    public func triggerSystemTextMenu() -> Void {
        let menuController = UIMenuController.shared
        self.becomeFirstResponder() // Ensure the view is first responder

        // Position the menu over the entire view for example:
        menuController.showMenu(from: self, rect: self.bounds)
    }
}

extension TokenInputView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = resignFirstResponder()
        return true
    }
}

final class ObservableTextField: UITextField {

    var onRemovingCharacterAtFirstPosition: ((String) -> Void)?

    override func deleteBackward() {

        guard let cursorLocation = selectedTextRange?.start, beginningOfDocument == cursorLocation else {
            super.deleteBackward()
            return
        }

        super.deleteBackward()
        onRemovingCharacterAtFirstPosition?(text ?? "")
    }
}
