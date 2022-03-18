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

final class TransactionDetailsView: UIView {
    
    private enum NavigationBarState {
        case normal
        case transactionStatusVisible
        case transactionStatusAndCancelButtonVisible
    }
    
    // MARK: - Constants
    
    private let defaultNavigationBarHeight = 90.0
    private let statusCapsuleHeight = AnimatedRefreshingView.containerHeight + 10.0
    private let cancelButtonHeight = 25.0
    
    // MARK: - Subviews
    
    @View private(set) var navigationBar = NavigationBarWithSubtitle()
    @View private var transactionStateView = AnimatedRefreshingView()
    
    @View private(set) var cancelButton: TextButton = {
        let view = TextButton()
        view.setTitle(localized("tx_detail.tx_cancellation.cancel"), for: .normal)
        view.setVariation(.warning, font: Theme.shared.fonts.textButtonCancel)
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
    @View private(set) var separatorView = TransactionDetailsSeparatorView()
    
    @View private(set) var noteView = TransactionDetailsSectionView<TransactionDetailsNoteView>()
    
    // MARK: - Properties
    
    var transactionState: AnimatedRefreshingViewState? {
        didSet { updateNavigationBar() }
    }
    
    private var navigationBarHeightConstraint: NSLayoutConstraint?
    private var transactionStateViewBottomConstraint: NSLayoutConstraint?
    private var cancelButtonBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        updateNavigationBar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        backgroundColor = Theme.shared.colors.appBackground
        contactNameView.title = localized("tx_detail.contact_name")
        noteView.title = localized("tx_detail.note")
        transactionStateView.isHidden = true
    }
    
    private func setupConstraints() {
        
        [mainContentView, navigationBar].forEach(addSubview)
        mainContentView.contentView.addSubview(contentStackView)
        
        [transactionStateView, cancelButton].forEach(navigationBar.addSubview)
        [valueView, contactView, contactNameView, separatorView, noteView].forEach(contentStackView.addArrangedSubview)
        
        let navigationBarHeightConstraint = navigationBar.heightAnchor.constraint(equalToConstant: 0.0)
        let transactionStateViewBottomConstraint = transactionStateView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -8.0)
        let cancelButtonBottomConstraint = cancelButton.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor)
        
        self.navigationBarHeightConstraint = navigationBarHeightConstraint
        self.transactionStateViewBottomConstraint = transactionStateViewBottomConstraint
        self.cancelButtonBottomConstraint = cancelButtonBottomConstraint
        
        let constraints = [
            navigationBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            navigationBarHeightConstraint,
            transactionStateView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 22.0),
            transactionStateView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -22.0),
            transactionStateViewBottomConstraint,
            transactionStateView.heightAnchor.constraint(equalToConstant: 48.0),
            cancelButton.topAnchor.constraint(equalTo: transactionStateView.bottomAnchor),
            cancelButton.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 44.0),
            cancelButtonBottomConstraint,
            mainContentView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            mainContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStackView.topAnchor.constraint(equalTo: mainContentView.contentView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: mainContentView.contentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: mainContentView.contentView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: mainContentView.contentView.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Updates
    
    private func updateNavigationBar() {
        
        guard let state = transactionState else {
            updateNavigationBarElements(state: .normal)
            return
        }
        
        transactionStateView.setupView(state, visible: true)
        
        guard state == .txWaitingForRecipient else  {
            updateNavigationBarElements(state: .transactionStatusVisible)
            return
        }
        
        updateNavigationBarElements(state: .transactionStatusAndCancelButtonVisible)
    }
    
    private func updateNavigationBarElements(state: NavigationBarState) {
        switch state {
        case .normal:
            navigationBarHeightConstraint?.constant = defaultNavigationBarHeight
            transactionStateViewBottomConstraint?.isActive = false
            cancelButtonBottomConstraint?.isActive = false
            transactionStateView.isHidden = true
            cancelButton.isHidden = true
        case .transactionStatusVisible:
            navigationBarHeightConstraint?.constant = defaultNavigationBarHeight + statusCapsuleHeight
            transactionStateViewBottomConstraint?.isActive = true
            cancelButtonBottomConstraint?.isActive = false
            transactionStateView.isHidden = false
            cancelButton.isHidden = true
        case .transactionStatusAndCancelButtonVisible:
            navigationBarHeightConstraint?.constant = defaultNavigationBarHeight + statusCapsuleHeight + cancelButtonHeight
            transactionStateViewBottomConstraint?.isActive = false
            cancelButtonBottomConstraint?.isActive = true
            transactionStateView.isHidden = false
            cancelButton.isHidden = false
        }
    }
}

final class TransactionDetailsSeparatorView: UIView {
    
    // MARK: - Subviews
    
    @View private var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.shared.colors.txScreenDivider
        return view
    }()
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupConstaints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupConstaints() {
        
        addSubview(separatorView)
        
        let constraints = [
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}
