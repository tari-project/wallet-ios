//  TransactionDetailsView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 14/03/2022
	Using Swift 5.0
	Running on macOS 12.2

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

final class TransactionDetailsView: DynamicThemeView {

    private enum NavigationBarState {
        case normal
        case transactionStatusVisible
        case transactionStatusAndCancelButtonVisible
    }

    // MARK: - Subviews

    @View private var navigationBar = NavigationBar()

    @View private var subtitleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = .Poppins.Medium.withSize(13.0)
        view.textAlignment = .center
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()

    @View private var transactionStateView = AnimatedRefreshingView()

    @View private(set) var cancelButton: TextButton = {
        let view = TextButton()
        view.setTitle(localized("tx_detail.tx_cancellation.cancel"), for: .normal)
        view.style = .warning
        view.font = .Poppins.Medium.withSize(12.0)
        return view
    }()

    @View private var mainContentView = KeyboardAvoidingContentView()

    @View private(set) var contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        return view
    }()

    @View private(set) var valueView = TransactionDetailsValueView()
    @View private(set) var contactView = TransactionDetailsSectionView<TransactionDetailsEmojiView>()
    @View private(set) var contactNameView = TransactionDetailsSectionView<TransactionDetailsContactView>()
    @View private(set) var noteSeparatorView = TransactionDetailsSeparatorView()
    @View private(set) var noteView = TransactionDetailsSectionView<TransactionDetailsNoteView>()
    @View private(set) var blockExplorerSeparatorView = TransactionDetailsSeparatorView()
    @View private(set) var blockExplorerView = TransactionDetailsSectionView<TransactionDetailsBlockExplorerView>()

    // MARK: - Properties

    var transactionState: AnimatedRefreshingViewState? {
        didSet { updateNavigationBar() }
    }

    var title: String? {
        get { navigationBar.title }
        set { navigationBar.title = newValue }
    }

    var subtitle: String? {
        get { subtitleLabel.text }
        set { subtitleLabel.text = newValue }
    }

    private var stackViewBottomConstraints: NSLayoutConstraint?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        updateNavigationBar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        contactNameView.title = localized("tx_detail.contact_name")
        noteView.title = localized("tx_detail.note")
        blockExplorerView.title = localized("tx_detail.block_explorer.description")
        transactionStateView.isHidden = true
    }

    private func setupConstraints() {

        [mainContentView, navigationBar].forEach(addSubview)
        mainContentView.contentView.addSubview(contentStackView)

        @View var stackView = UIStackView()
        stackView.axis = .vertical

        [subtitleLabel, stackView].forEach(navigationBar.bottomContentView.addSubview)
        [transactionStateView, cancelButton].forEach(stackView.addArrangedSubview)
        [valueView, contactView, contactNameView, noteSeparatorView, noteView, blockExplorerSeparatorView, blockExplorerView].forEach(contentStackView.addArrangedSubview)

        let stackViewBottomConstraints = stackView.bottomAnchor.constraint(equalTo: navigationBar.bottomContentView.bottomAnchor, constant: -8.0)
        self.stackViewBottomConstraints = stackViewBottomConstraints

        let constraints = [
            navigationBar.topAnchor.constraint(equalTo: topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainContentView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            mainContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStackView.topAnchor.constraint(equalTo: mainContentView.contentView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: mainContentView.contentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: mainContentView.contentView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: mainContentView.contentView.bottomAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: navigationBar.bottomContentView.topAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: navigationBar.bottomContentView.leadingAnchor, constant: 8.0),
            subtitleLabel.trailingAnchor.constraint(equalTo: navigationBar.bottomContentView.trailingAnchor, constant: -8.0),
            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8.0),
            stackView.leadingAnchor.constraint(equalTo: navigationBar.bottomContentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: navigationBar.bottomContentView.trailingAnchor),
            stackViewBottomConstraints,
            transactionStateView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 22.0),
            transactionStateView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -22.0),
            transactionStateView.heightAnchor.constraint(equalToConstant: 48.0),
            cancelButton.heightAnchor.constraint(equalToConstant: 44.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        subtitleLabel.textColor = theme.text.heading
        backgroundColor = theme.backgrounds.primary
    }

    private func updateNavigationBar() {

        guard let state = transactionState else {
            updateNavigationBarElements(state: .normal)
            return
        }

        transactionStateView.setupView(state, visible: true)

        guard state == .txWaitingForRecipient else {
            updateNavigationBarElements(state: .transactionStatusVisible)
            return
        }

        updateNavigationBarElements(state: .transactionStatusAndCancelButtonVisible)
    }

    private func updateNavigationBarElements(state: NavigationBarState) {
        switch state {
        case .normal:
            transactionStateView.isHidden = true
            cancelButton.isHidden = true
            stackViewBottomConstraints?.constant = -8.0
        case .transactionStatusVisible:
            transactionStateView.isHidden = false
            cancelButton.isHidden = true
            stackViewBottomConstraints?.constant = -8.0
        case .transactionStatusAndCancelButtonVisible:
            transactionStateView.isHidden = false
            cancelButton.isHidden = false
            stackViewBottomConstraints?.constant = 0.0
        }
    }
}
