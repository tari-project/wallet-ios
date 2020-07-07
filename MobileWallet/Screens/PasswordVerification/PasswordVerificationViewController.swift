//  PasswordVerificationViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 06.07.2020
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

class PasswordVerificationViewController: SettingsParentViewController {
    enum PasswordVerificationScreenStyle {
        case restore
        case change
    }

    private let variation: PasswordVerificationScreenStyle

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let headerLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let continueButton = ActionButton()

    private let passwordField = PasswordField()
    private let restoreWalletAction: ((_ password: String?) -> Void)?

    private var secureButtonBottomConstraint: NSLayoutConstraint?

    init(variation: PasswordVerificationScreenStyle, restoreWalletAction:((_ password: String?) -> Void)? = nil) {
        self.variation = variation
        self.restoreWalletAction = restoreWalletAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAroundOrSwipedDown(view: scrollView)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChangePosition), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChangePosition), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func changePasswordAction() {
        if let currentPassword = BPKeychainWrapper.loadBackupPasswordFromKeychain() {
            if passwordField.comparePassword(currentPassword) {
                navigationController?.pushViewController(SecureBackupViewController(), animated: true)
            }
        }
    }

    @objc private func continueButtonAction() {
        view.endEditing(true)
        switch variation {
        case .restore: restoreWalletAction?(passwordField.password)
        case .change: changePasswordAction()
        }
    }
}

extension PasswordVerificationViewController {
    override func setupViews() {
        super.setupViews()
        setupContinueButton()
        setupScrollView()
        setupHeaderLabel()
        setupDescriptionLabel()
        setupPasswordField()
    }

    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.backgroundColor = .clear
        navigationBar.title = NSLocalizedString("password_verification.title", comment: "PasswordVerification view")
    }

    private func setupHeaderLabel() {
        headerLabel.font = Theme.shared.fonts.settingsViewHeader
        switch variation {
        case .change:
            headerLabel.text = NSLocalizedString("password_verification.header.enter_current_password", comment: "PasswordVerification view")
        case .restore:
            headerLabel.text = NSLocalizedString("password_verification.header.enter_backup_password", comment: "PasswordVerification view")
        }
        stackView.addArrangedSubview(headerLabel)
        stackView.setCustomSpacing(15, after: headerLabel)
    }

    private func setupDescriptionLabel() {
        let attributedString: NSMutableAttributedString

        switch variation {
        case .change:
            attributedString = NSMutableAttributedString(string: NSLocalizedString("password_verification.description.enter_current_password", comment: "PasswordVerification view"))
            attributedString.addAttributes([NSAttributedString.Key.foregroundColor: Theme.shared.colors.settingsViewDescription!], range: NSRange(location: 0, length: attributedString.length))
        case .restore:
            let atttributedPart1 = NSLocalizedString("password_verification.description.enter_backup_password.part1", comment: "PasswordVerification view")
            let atttributedPart2 = NSLocalizedString("password_verification.description.enter_backup_password.part2", comment: "PasswordVerification view")
            attributedString = NSMutableAttributedString(string: atttributedPart1 + atttributedPart2)
            attributedString.addAttributes([NSAttributedString.Key.foregroundColor: Theme.shared.colors.settingsViewDescription!], range: NSRange(location: 0, length: atttributedPart1.count))
            attributedString.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], range: NSRange(location: atttributedPart1.count, length: atttributedPart2.count))
        }

        attributedString.addAttributes([NSAttributedString.Key.kern: -0.26], range: NSRange(location: 0, length: attributedString.length))

        descriptionLabel.font = Theme.shared.fonts.settingsViewHeaderDescription
        descriptionLabel.attributedText = attributedString
        descriptionLabel.numberOfLines = 0

        stackView.addArrangedSubview(descriptionLabel)
        stackView.setCustomSpacing(25, after: descriptionLabel)
    }

    private func setupPasswordField() {
        passwordField.delegate = self
        passwordField.isConfirmationField = true
        passwordField.warning = NSLocalizedString("password_verification.password_field_warning", comment: "PasswordVerification view")
        passwordField.title = NSLocalizedString("password_verification.password_field.title", comment: "PasswordVerification view")
        passwordField.placeholder = NSLocalizedString("password_verification.password_field.placeholder", comment: "PasswordVerification view")

        stackView.addArrangedSubview(passwordField)
        stackView.setCustomSpacing(25, after: passwordField)
    }

    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false

        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        stackView.axis = .vertical
        stackView.distribution = .fill

        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 30).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
    }

    private func setupContinueButton() {
        switch variation {
        case .restore:
            continueButton.setTitle(NSLocalizedString("password_verification.restore_wallet", comment: "PasswordVerification view"), for: .normal)
        case .change:
            continueButton.setTitle(NSLocalizedString("password_verification.change_password", comment: "PasswordVerification view"), for: .normal)
        }

        continueButton.addTarget(self, action: #selector(continueButtonAction), for: .touchUpInside)
        continueButton.variation = .disabled

        view.addSubview(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                constant: Theme.shared.sizes.appSidePadding).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                 constant: -Theme.shared.sizes.appSidePadding).isActive = true
        continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                                constant: 0).isActive = true

        let continueButtonConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        continueButtonConstraint.priority = UILayoutPriority(rawValue: 999)
        continueButtonConstraint.isActive = true

        secureButtonBottomConstraint = continueButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        secureButtonBottomConstraint?.priority = UILayoutPriority(rawValue: 1000)
        secureButtonBottomConstraint?.isActive = true
    }
}

extension PasswordVerificationViewController: PasswordFieldDelegate {
    func passwordFieldDidChange(_ passwordField: PasswordField) {
        guard let password = passwordField.password else { return }
        continueButton.variation = password.isEmpty ? .disabled : .normal
    }
}

extension PasswordVerificationViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isModalInPresentation = true // Disabling dismiss controller with swipe down on scroll view
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isModalInPresentation = false
    }
}

// MARK: Keyboard behavior
extension PasswordVerificationViewController {
    @objc private func keyboardChangePosition(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let showKeyboard = notification.name == UIResponder.keyboardWillShowNotification
            let keyboardHeight = keyboardSize.height
            secureButtonBottomConstraint?.constant = showKeyboard == true ? -10 - keyboardHeight : -20
            UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
                self?.view.layoutIfNeeded()
            }

            UIView.animate(withDuration: CATransaction.animationDuration(), animations: { [weak self] in
                self?.view.layoutIfNeeded()
            }) { [weak self] _ in
                if showKeyboard == true {
                    self?.scrollView.scrollToBottom(animated: true)
                } else {
                    self?.scrollView.scrollToTop(animated: true)
                }
            }
        }
    }
}
