//  SecureBackupViewController.swift

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
import Combine

class SecureBackupViewController: SettingsParentViewController {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let headerLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let continueButton = ActionButton()

    private let enterPasswordField = PasswordField()
    private let confirmPasswordField = PasswordField()

    private var secureButtonBottomConstraint: NSLayoutConstraint?

    private let pendingView = PendingView(title: localized("backup_pending_view.title"),
                                          definition: localized("backup_pending_view.description"))

    private var descriptionTextColor: UIColor?
    private var descriptionBoldTextColor: UIColor?

    private var cancellables = Set<AnyCancellable>()

    init(backButtonType: NavigationBar.BackButtonType) {
        super.init(nibName: nil, bundle: nil)
        navigationBar.backButtonType = backButtonType
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAroundOrSwipedDown(view: scrollView)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardChangePosition),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardChangePosition),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func continueButtonAction() {

        guard let password = enterPasswordField.password else { return }

        view.endEditing(true)
        continueButton.variation = .disabled
        BackupManager.shared.password = password

        pendingView.showPendingView { [weak self] in
            self?.performBackup()
        }
    }

    private func performBackup() {

        BackupManager.shared.$syncState
            .dropFirst()
            .filter { $0 == .synced || $0 == .outOfSync }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.finishPendingProcess() }
            .store(in: &cancellables)

        BackupManager.shared.backupNow(onlyIfOutdated: false)
    }

    private func finishPendingProcess() {
        pendingView.hidePendingView(completion: { [weak self] in
            self?.returnToBackupSettingsScreen()
        })
    }

    private func returnToBackupSettingsScreen() {

        guard !isModal else {
            dismiss(animated: true)
            return
        }

        if let curentControllers = navigationController?.viewControllers {
            curentControllers.forEach({
                if $0 is BackupWalletSettingsViewController {
                    self.navigationController?.popToViewController($0, animated: true)
                }
            })
        }
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        headerLabel.textColor = theme.text.heading
        descriptionTextColor = theme.text.body
        descriptionBoldTextColor = theme.text.heading

        updateDescriptionLabel()
    }
}

// MARK: Keyboard behavior
extension SecureBackupViewController {
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

// MARK: Setup subviews
extension SecureBackupViewController {
    override func setupViews() {
        super.setupViews()
        setupContinueButton()
        setupScrollView()
        setupHeaderLabel()
        setupDescriptionLabel()
        setupEnterPasswordField()
        setupConfirmPasswordField()
    }

    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.title = localized("secure_backup.title")
    }

    private func setupHeaderLabel() {
        headerLabel.font = Theme.shared.fonts.settingsViewHeader
        headerLabel.text = localized("secure_backup.header")

        stackView.addArrangedSubview(headerLabel)
        stackView.setCustomSpacing(15, after: headerLabel)
    }

    private func setupEnterPasswordField() {
        enterPasswordField.delegate = self
        enterPasswordField.title = localized("secure_backup.enter_password_field.title")
        enterPasswordField.placeholder = localized("secure_backup.enter_password_field.placeholder")
        enterPasswordField.paredPasswordField = confirmPasswordField

        stackView.addArrangedSubview(enterPasswordField)
        stackView.setCustomSpacing(25, after: enterPasswordField)
    }

    private func setupConfirmPasswordField() {
        confirmPasswordField.delegate = self
        confirmPasswordField.title = localized("secure_backup.confirm_password_field.title")
        confirmPasswordField.placeholder = localized("secure_backup.confirm_password_field.placeholder")
        confirmPasswordField.isConfirmationField = true
        confirmPasswordField.paredPasswordField = enterPasswordField
        stackView.addArrangedSubview(confirmPasswordField)
        stackView.setCustomSpacing(25, after: confirmPasswordField)
    }

    private func setupDescriptionLabel() {
        descriptionLabel.font = Theme.shared.fonts.settingsViewHeaderDescription
        descriptionLabel.numberOfLines = 0

        stackView.addArrangedSubview(descriptionLabel)
        stackView.setCustomSpacing(25, after: descriptionLabel)
    }

    private func updateDescriptionLabel() {

        guard let descriptionTextColor, let descriptionBoldTextColor else { return }

        let atttributedPart1 = localized("secure_backup.header_description_part1")
        let atttributedPart2 = localized("secure_backup.header_description_part2")

        let attributedString = NSMutableAttributedString(string: atttributedPart1 + atttributedPart2)

        attributedString.addAttributes([.foregroundColor: descriptionTextColor], range: NSRange(location: 0, length: atttributedPart1.count))
        attributedString.addAttributes([.foregroundColor: descriptionBoldTextColor], range: NSRange(location: atttributedPart1.count, length: atttributedPart2.count))

        descriptionLabel.attributedText = attributedString
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
        continueButton.setTitle(localized("secure_backup.secure_your_backup"), for: .normal)
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

extension SecureBackupViewController: PasswordFieldDelegate {
    func passwordFieldDidChange(_ passwordField: PasswordField) {
        guard let password = passwordField.password else { return }
        if confirmPasswordField.isWarning || enterPasswordField.isWarning {
            continueButton.variation = .disabled
            return
        }
        continueButton.variation = (confirmPasswordField.password == enterPasswordField.password && !password.isEmpty) ? .normal : .disabled
    }
}

extension SecureBackupViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isModalInPresentation = true // Disabling dismiss controller with swipe down on scroll view
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isModalInPresentation = false
    }
}
