//  AddRecipientView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 13/10/2021
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
import Combine
import TariCommon

final class AddRecipientView: UIView {
    
    // MARK: - Subviews
    
    @View private var navigationBar: NavigationBar = {
        let view = NavigationBar()
        view.title = localized("add_recipient.title")
        return view
    }()
    
    @View private var searchContentView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.shared.colors.navigationBarBackground
        view.layer.shadowOpacity = 0.0
        view.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        view.layer.shadowRadius = 10.0
        view.layer.shadowColor = Theme.shared.colors.defaultShadow?.cgColor
        return view
    }()
    
    @View var searchField: UITextField = {
        let view = UITextField()
        view.placeholder = localized("add_recipient.inputbox.placeholder")
        view.backgroundColor = Theme.shared.colors.appBackground
        view.font = Theme.shared.fonts.searchContactsInputBoxText
        view.leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 11.0, height: 0.0))
        view.leftViewMode = .always
        view.rightViewMode = .always
        view.layer.cornerRadius = 6.0
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        view.layer.shadowRadius = 6.0
        view.layer.shadowColor = Theme.shared.colors.defaultShadow?.cgColor
        return view
    }()
    
    @View var scanButton = QRButton()
    
    @View var contactsTableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.keyboardDismissMode = .interactive
        view.backgroundColor = .clear
        view.separatorStyle = .none
        return view
    }()
    
    @View private var errorMessageView = ErrorView()
    
    @View private var continueButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("common.continue"), for: .normal)
        return view
    }()
    
    @View private var dimView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.0
        return view
    }()
    
    @View private var pasteEmojisView = PasteEmojisView()
    
    // MARK: - Properties
    
    var isSearchViewShadowVisible: Bool = false {
        didSet {
            guard isSearchViewShadowVisible != oldValue else { return }
            updateSearchViewShadow()
        }
    }
    
    var isContinueButtonVisible: Bool = false {
        didSet { isContinueButtonVisible ? showContinueButton() : hideContinueButton() }
    }
    
    var isSearchTextDimmed: Bool = false {
        didSet { searchField.textColor = isSearchTextDimmed ? Theme.shared.colors.emojisSeparatorExpanded : .black }
    }
    
    var isSearchFieldContainsValidAddress: Bool = false {
        didSet { updateSearchFieldState() }
    }
    
    var errorMessage: String = "" {
        didSet {
            
            normalTableViewTopConstraint?.isActive = errorMessage.isEmpty
            errorTableViewTopConstraint?.isActive = !errorMessage.isEmpty
            
            UIView.animate(withDuration: 0.1) {
                self.layoutIfNeeded()
                self.errorMessageView.message = self.errorMessage
            }
        }
    }
    
    var textSubject: CurrentValueSubject<String, Never> = CurrentValueSubject("")
    
    var onScanButtonTap: (() -> Void)?
    var onSearchFieldBeginEditing: (() -> Void)?
    var onReturnButtonTap: (() -> Void)?
    var onContinueButtonTap: (() -> Void)?
    
    private(set) var tableDataSource: UITableViewDiffableDataSource<String, ContactElementItem>?
    
    private var navigationBarHeightConstraint: NSLayoutConstraint?
    private var continueButtonTopConstraint: NSLayoutConstraint?
    private var continueButtonBottomConstraint: NSLayoutConstraint?
    private var pasteEmojisViewBottomConstraint: NSLayoutConstraint?
    
    private var normalTableViewTopConstraint: NSLayoutConstraint?
    private var errorTableViewTopConstraint: NSLayoutConstraint?
    
    // MARK: - Initializers
    
    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        setupFeedbacks()
        setupTableViewDataSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        backgroundColor = Theme.shared.colors.appBackground
        hideContinueButton()
        updateSearchFieldState()
    }
    
    private func setupConstraints() {
        
        [searchContentView, navigationBar, contactsTableView, errorMessageView, continueButton, dimView, searchField, pasteEmojisView].forEach(addSubview)
        
        let navigationBarHeightConstraint = navigationBar.heightAnchor.constraint(equalToConstant: 44.0)
        let continueButtonTopConstraint = continueButton.topAnchor.constraint(equalTo: bottomAnchor)
        let pasteEmojisViewBottomConstraint = pasteEmojisView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let normalTableViewTopConstraint = contactsTableView.topAnchor.constraint(equalTo: searchContentView.bottomAnchor)
        
        
        
        
        self.navigationBarHeightConstraint = navigationBarHeightConstraint
        self.continueButtonTopConstraint = continueButtonTopConstraint
        self.continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -22.0)
        self.pasteEmojisViewBottomConstraint = pasteEmojisViewBottomConstraint
        self.normalTableViewTopConstraint = normalTableViewTopConstraint
        errorTableViewTopConstraint = contactsTableView.topAnchor.constraint(equalTo: errorMessageView.bottomAnchor)
        
        let constraints = [
            navigationBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            navigationBarHeightConstraint,
            searchContentView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            searchContentView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            searchContentView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            searchContentView.heightAnchor.constraint(equalToConstant: 90.0),
            searchField.centerYAnchor.constraint(equalTo: searchContentView.centerYAnchor),
            searchField.leadingAnchor.constraint(equalTo: searchContentView.leadingAnchor, constant: 22.0),
            searchField.trailingAnchor.constraint(equalTo: searchContentView.trailingAnchor, constant: -22.0),
            searchField.heightAnchor.constraint(equalToConstant: 46.0),
            normalTableViewTopConstraint,
            contactsTableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contactsTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contactsTableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorMessageView.topAnchor.constraint(equalTo: searchContentView.bottomAnchor),
            errorMessageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            errorMessageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            errorMessageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 35.0),
            continueButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            continueButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            continueButtonTopConstraint,
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pasteEmojisView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pasteEmojisView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pasteEmojisView.heightAnchor.constraint(equalToConstant: 78.0),
            pasteEmojisViewBottomConstraint
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupFeedbacks() {
        continueButton.addTarget(self, action: #selector(onContinueButtonTapAction), for: .touchUpInside)
        scanButton.addTarget(self, action: #selector(onScanButtonTapAction), for: .touchUpInside)
        searchField.delegate = self
    }
    
    private func setupTableViewDataSource() {
        tableDataSource = UITableViewDiffableDataSource(tableView: contactsTableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: ContactCell.self, indexPath: indexPath)
            cell.aliasText = model.title
            cell.initial = model.initial
            cell.isEmojiID = model.isEmojiID
            return cell
        }
        tableDataSource?.defaultRowAnimation = .fade
    }
    
    // MARK: - Actions
    
    private func showContinueButton() {
        
        continueButtonTopConstraint?.isActive = false
        continueButtonBottomConstraint?.isActive = true
        
        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            self?.searchContentView.layer.shadowOpacity = 0.1
            self?.layoutIfNeeded()
        }
    }
    
    private func hideContinueButton() {
        
        continueButtonBottomConstraint?.isActive = false
        continueButtonTopConstraint?.isActive = true
        
        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            self?.searchContentView.layer.shadowOpacity = 0.0
            self?.layoutIfNeeded()
        }
    }
    
    func showCopyFromClipboardDialog(text: String, keyboardOffset: CGFloat, onPress: @escaping () -> Void) {
        
        pasteEmojisView.setEmojis(emojis: text, onPress: onPress)
        pasteEmojisViewBottomConstraint?.constant = -keyboardOffset
        navigationBarHeightConstraint?.constant = 0.0
        
        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            self?.dimView.alpha = 0.6
            self?.pasteEmojisView.alpha = 1.0
            self?.layoutIfNeeded()
        }
    }
    
    func hideCopyFromClipboardDialog() {
        
        pasteEmojisViewBottomConstraint?.constant = 0.0
        navigationBarHeightConstraint?.constant = 44.0
        
        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            self?.dimView.alpha = 0.0
            self?.pasteEmojisView.alpha = 0.0
            self?.layoutIfNeeded()
        }
    }
    
    private func updateSearchViewShadow() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.searchContentView.layer.shadowOpacity = self.isSearchViewShadowVisible ? 0.1 : 0.0
        }
    }
    
    private func updateSearchFieldState() {
        searchField.textAlignment = isSearchFieldContainsValidAddress ? .center : .left
        searchField.returnKeyType = isSearchFieldContainsValidAddress ? .continue : .default
        searchField.rightView = isSearchFieldContainsValidAddress ? nil : scanButton
    }
    
    // MARK: - Action Targets
    
    @objc private func onScanButtonTapAction() {
        onScanButtonTap?()
    }
    
    @objc private func onContinueButtonTapAction() {
        onContinueButtonTap?()
    }
}

extension AddRecipientView: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        onSearchFieldBeginEditing?()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        onReturnButtonTap?()
        return true
    }
}
