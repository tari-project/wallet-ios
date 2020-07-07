//  PasswordField.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 01.07.2020
	Using Swift 5.0
	Running on macOS 10.15

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

protocol PasswordFieldDelegate: class {
    func passwordFieldDidChange(_ passwordField: PasswordField)
}

class PasswordField: UIView, UITextFieldDelegate {

    var password: String? {
        return self.textField.text
    }

    var placeholder: String? {
        didSet {
            textField.placeholder = placeholder
        }
    }

    var warning: String? {
        didSet {
            warningLabel.text = warning
        }
    }

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    var isConfirmationField: Bool = false

    private let titleLabel = UILabel()
    private let warningLabel = UILabel()
    private let textField = UITextField()

    enum PasswordFieldState {
        case normal
        case warning
    }

    private(set) var state: PasswordFieldState = .normal {
        didSet {
            warningLabel.isHidden = state != .warning
            switch state {
            case .normal:
                titleLabel.textColor = .black
                textField.textColor = .black
            case .warning:
                titleLabel.textColor = Theme.shared.colors.settingsPasswordWarning
                textField.textColor = Theme.shared.colors.settingsPasswordWarning
            }
        }
    }

    weak var delegate: PasswordFieldDelegate?
    weak var paredPasswordField: PasswordField?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didStartEditingPassword() {
        state = .normal
    }

    func didFinishEditingPassword() {
        guard let paredPassword = self.paredPasswordField?.password else { return }
        _ = comparePassword(paredPassword)
    }

    func comparePassword(_ password: String) -> Bool {
        guard let fieldPassword = self.password
        else { return false }
        if password != fieldPassword && !fieldPassword.isEmpty && isConfirmationField {
            state = .warning
            return false
        } else {
            state = .normal
            return true
        }
    }

    private func setupSubviews() {
        backgroundColor = Theme.shared.colors.appBackground
        state = .normal
        setupTitle()
        setupTextField()
        setupWarningLabel()
        setupLine()
    }

    private func setupTitle() {
        addSubview(titleLabel)
        titleLabel.font = Theme.shared.fonts.settingsPasswordTitle

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    }

    private func setupTextField() {
        addSubview(textField)

        textField.isSecureTextEntry = true
        textField.textColor = .black
        textField.delegate = self

        textField.addTarget(self, action: #selector(textFieldDidChange(_:)),
        for: .editingChanged)

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
        textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20.0).isActive = true
        textField.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        textField.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    private func setupLine() {
        let separatorLine = UIView()
        addSubview(separatorLine)

        separatorLine.backgroundColor = Theme.shared.colors.settingsNavBarSeparator
        separatorLine.translatesAutoresizingMaskIntoConstraints = false

        separatorLine.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        separatorLine.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20.0).isActive = true
        separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    private func setupWarningLabel() {
        addSubview(warningLabel)
        warningLabel.isHidden = true
        warningLabel.font = Theme.shared.fonts.settingsPasswordWarning
        warningLabel.textColor = Theme.shared.colors.settingsPasswordWarning
        warningLabel.backgroundColor = backgroundColor
        warningLabel.textAlignment = .right

        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.centerYAnchor.constraint(equalTo: textField.centerYAnchor).isActive = true
        warningLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        delegate?.passwordFieldDidChange(self)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        didStartEditingPassword()
        paredPasswordField?.didStartEditingPassword()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        didFinishEditingPassword()
        paredPasswordField?.didFinishEditingPassword()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
