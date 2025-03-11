//  AddContactView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 15/03/2023
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

import TariCommon

final class AddContactView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var searchViewBackgroundView = UIView()

    @View private(set) var searchView: ContactSearchView = {
        let view = ContactSearchView()
        view.textField.placeholder = localized("contact_book.add_contact.text_field.search.placeholder")
        view.previewText = nil
        return view
    }()

    @View private(set) var nameTextField: UITextField = {
        let view = UITextField()
        view.font = .Poppins.Medium.withSize(14.0)
        return view
    }()

    @View private var nameTextFieldSeparator = UIView()

    @View private var errorLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .Poppins.Medium.withSize(14.0)
        view.numberOfLines = 0
        return view
    }()

    // MARK: - Properties

    var errorText: String? {
        didSet { errorLabel.text = errorText }
    }

    var isDoneButtonEnabled: Bool = false {
        didSet { navigationBar.rightButton(index: 0)?.isEnabled = isDoneButtonEnabled }
    }

    var onDoneButtonTap: (() -> Void)?
    var onQRCodeButtonTap: (() -> Void)?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupSuviews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupSuviews() {
        navigationBar.title = localized("contact_book.add_contact.title")
        navigationBar.update(rightButton: NavigationBar.ButtonModel(title: localized("common.done"), callback: { [weak self] in self?.onDoneButtonTap?() }))
    }

    private func setupConstraints() {

        [searchViewBackgroundView, searchView, nameTextField, nameTextFieldSeparator, errorLabel].forEach(addSubview)

        let constraints = [
            searchViewBackgroundView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            searchViewBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchViewBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchView.topAnchor.constraint(equalTo: searchViewBackgroundView.topAnchor, constant: 22.0),
            searchView.leadingAnchor.constraint(equalTo: searchViewBackgroundView.leadingAnchor, constant: 25.0),
            searchView.trailingAnchor.constraint(equalTo: searchViewBackgroundView.trailingAnchor, constant: -25.0),
            searchView.bottomAnchor.constraint(equalTo: searchViewBackgroundView.bottomAnchor, constant: -22.0),
            nameTextField.topAnchor.constraint(equalTo: searchViewBackgroundView.bottomAnchor, constant: 8.0),
            nameTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            nameTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            nameTextField.heightAnchor.constraint(equalToConstant: 50.0),
            nameTextFieldSeparator.topAnchor.constraint(equalTo: nameTextField.bottomAnchor),
            nameTextFieldSeparator.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            nameTextFieldSeparator.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            nameTextFieldSeparator.heightAnchor.constraint(equalToConstant: 1.0),
            errorLabel.topAnchor.constraint(equalTo: nameTextFieldSeparator.bottomAnchor, constant: 8.0),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        searchView.qrButton.onTap = { [weak self] in
            self?.onQRCodeButtonTap?()
        }
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        searchViewBackgroundView.backgroundColor = theme.backgrounds.secondary
        nameTextField.textColor = theme.text.heading
        nameTextFieldSeparator.backgroundColor = theme.neutral.tertiary
        errorLabel.textColor = theme.system.red

        guard let placeholderColor = theme.text.lightText else { return }
        nameTextField.attributedPlaceholder = NSAttributedString(string: localized("contact_book.add_contact.text_field.name.placeholder"), attributes: [.foregroundColor: placeholderColor])
    }
}
