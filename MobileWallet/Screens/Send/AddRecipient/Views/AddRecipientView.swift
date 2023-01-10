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

final class AddRecipientView: DynamicThemeView {

    // MARK: - Subviews

    @View private(set) var searchContentView: UIView = {
        let view = UIView()
        view.layer.shadowOpacity = 0.0
        view.backgroundColor = .clear
        return view
    }()

    @View var searchView = AddRecipientSearchView()

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
        view.backgroundColor = .static.popupOverlay
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
        didSet { updateSearchViewColor(theme: theme) }
    }

    var isSearchFieldContainsValidAddress: Bool = false {
        didSet { updateSearchFieldState() }
    }

    var isPreviewButtonVisible: Bool = false {
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
    var onPreviewButtonTap: (() -> Void)?
    var onSearchFieldBeginEditing: (() -> Void)?
    var onReturnButtonTap: (() -> Void)?
    var onContinueButtonTap: (() -> Void)?

    private(set) var tableDataSource: UITableViewDiffableDataSource<String, ContactElementItem>?

    private var continueButtonTopConstraint: NSLayoutConstraint?
    private var continueButtonBottomConstraint: NSLayoutConstraint?
    private var pasteEmojisViewBottomConstraint: NSLayoutConstraint?

    private var normalTableViewTopConstraint: NSLayoutConstraint?
    private var errorTableViewTopConstraint: NSLayoutConstraint?

    // MARK: - Initializers

    override init() {
        super.init()
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
        hideContinueButton()
        updateSearchFieldState()
    }

    private func setupConstraints() {

        [searchContentView, contactsTableView, errorMessageView, continueButton, dimView, searchView, pasteEmojisView].forEach(addSubview)

        let continueButtonTopConstraint = continueButton.topAnchor.constraint(equalTo: bottomAnchor)
        let pasteEmojisViewBottomConstraint = pasteEmojisView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let normalTableViewTopConstraint = contactsTableView.topAnchor.constraint(equalTo: searchContentView.bottomAnchor)

        self.continueButtonTopConstraint = continueButtonTopConstraint
        self.continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -22.0)
        self.pasteEmojisViewBottomConstraint = pasteEmojisViewBottomConstraint
        self.normalTableViewTopConstraint = normalTableViewTopConstraint
        errorTableViewTopConstraint = contactsTableView.topAnchor.constraint(equalTo: errorMessageView.bottomAnchor)

        let constraints = [
            searchContentView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            searchContentView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            searchContentView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            searchContentView.heightAnchor.constraint(equalToConstant: 90.0),
            searchView.centerYAnchor.constraint(equalTo: searchContentView.centerYAnchor),
            searchView.leadingAnchor.constraint(equalTo: searchContentView.leadingAnchor, constant: 22.0),
            searchView.trailingAnchor.constraint(equalTo: searchContentView.trailingAnchor, constant: -22.0),
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
        searchView.qrButton.addTarget(self, action: #selector(onScanButtonTapAction), for: .touchUpInside)
        searchView.yatPreviewButton.addTarget(self, action: #selector(onYatPreviewButtonTapAction), for: .touchUpInside)
        searchView.textField.delegate = self
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

        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            self?.dimView.alpha = 0.6
            self?.pasteEmojisView.alpha = 1.0
            self?.layoutIfNeeded()
        }
    }

    func hideCopyFromClipboardDialog() {

        pasteEmojisViewBottomConstraint?.constant = 0.0

        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            self?.dimView.alpha = 0.0
            self?.pasteEmojisView.alpha = 0.0
            self?.layoutIfNeeded()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        updateSearchViewColor(theme: theme)

        let searchContentViewShadowOpacity = searchContentView.layer.shadowOpacity
        searchContentView.apply(shadow: theme.shadows.box)
        searchContentView.layer.shadowOpacity = searchContentViewShadowOpacity
    }

    private func updateSearchViewColor(theme: ColorTheme) {
        searchView.textField.textColor = isSearchTextDimmed ? theme.text.lightText : theme.text.heading
    }

    private func updateSearchViewShadow() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.searchContentView.layer.shadowOpacity = self.isSearchViewShadowVisible ? 0.1 : 0.0
        }
    }

    private func updateSearchFieldState() {
        searchView.textField.textAlignment = isSearchFieldContainsValidAddress ? .center : .left
        searchView.textField.returnKeyType = isSearchFieldContainsValidAddress ? .continue : .default
        searchView.isQrButtonVisible = !isSearchFieldContainsValidAddress
        searchView.isPreviewButtonVisible = isPreviewButtonVisible
    }

    // MARK: - Action Targets

    @objc private func onScanButtonTapAction() {
        onScanButtonTap?()
    }

    @objc private func onYatPreviewButtonTapAction() {
        onPreviewButtonTap?()
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
