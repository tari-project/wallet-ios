//  ContactBookView.swift

/*
	Package MobileWallet
	Created by Browncoat on 09/02/2023
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
import Combine

final class ContactBookView: BaseNavigationContentView {

    // MARK: - Subviews

    @TariView private var shareBar: ContactBookShareBar = {
        let view = ContactBookShareBar()
        view.alpha = 0.0
        return view
    }()

    @TariView private var searchTextField: SearchField = {
        let view = SearchField()
        view.placeholder = localized("contact_book.search_bar.placeholder")
        return view
    }()

    // MARK: - Properties

    var searchText: AnyPublisher<String, Never> { searchTextSubject.eraseToAnyPublisher() }
    var selectedShareOptionID: Int? { shareBar.selectedIdentifier }

    var isShareButtonEnabled: Bool = false {
        didSet { updateShareButton() }
    }

    var onAddContactButtonTap: (() -> Void)?
    var onShareModeButtonTap: (() -> Void)?
    var onCancelShareModeButtonTap: (() -> Void)?
    var onShareButtonTap: (() -> Void)?

    private let searchTextSubject = CurrentValueSubject<String, Never>("")

    var isInSelectionMode: Bool = false {
        didSet { updateViewsState() }
    }

    private var shareBarTopConstraint: NSLayoutConstraint?
    private var shareBarBottomConstraint: NSLayoutConstraint?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupSuviews()
        setupConstraints()
        setupCallbacks()
        updateViewsState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    func setup(pagerView: UIView) {

        addSubview(pagerView)

        let constraints = [
            pagerView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20.0),
            pagerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pagerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pagerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func setupShareBar(models: [ContactBookShareBar.ViewModel]) {
        shareBar.setupButtons(models: models)
    }

    private func setupSuviews() {
        navigationBar.title = localized("contact_book.title")
        navigationBar.backButtonType = .none
    }

    private func setupConstraints() {

        [shareBar, searchTextField].forEach(addSubview)

        sendSubviewToBack(shareBar)

        shareBarTopConstraint = shareBar.topAnchor.constraint(equalTo: navigationBar.bottomAnchor)
        let shareBarBottomConstraint = shareBar.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor)
        self.shareBarBottomConstraint = shareBarBottomConstraint

        let constraints = [
            shareBarBottomConstraint,
            shareBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            shareBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchTextField.topAnchor.constraint(equalTo: shareBar.bottomAnchor, constant: 20.0),
            searchTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            searchTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        searchTextField.bind(withSubject: searchTextSubject, storeIn: &cancellables)

        navigationBar.onBackButtonAction = { [weak self] in
            self?.onCancelShareModeButtonTap?()
        }
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
    }

    private func updateViewsState() {
        updateNavigationButtons()
        updateShareBar()
    }

    private func updateNavigationButtons() {

        let rightButtons: [NavigationBar.ButtonModel]

        if isInSelectionMode {
            rightButtons = [
                NavigationBar.ButtonModel(title: localized("contact_book.nav_bar.buttons.share"), callback: { [weak self] in self?.onShareButtonTap?() })
            ]
        } else {
            rightButtons = [
                NavigationBar.ButtonModel(image: .Images.ContactBook.Buttons.share, callback: { [weak self] in self?.onShareModeButtonTap?() }),
                NavigationBar.ButtonModel(image: .Images.ContactBook.Buttons.addContact, callback: { [weak self] in self?.onAddContactButtonTap?() })
            ]
        }

        navigationBar.backButtonType = isInSelectionMode ? .text(localized("common.cancel")) : .none
        navigationBar.update(rightButtons: rightButtons)

        updateShareButton()
    }

    private func updateShareButton() {
        guard isInSelectionMode else { return }
        navigationBar.rightButton(index: 0)?.isEnabled = isShareButtonEnabled
    }

    private func updateShareBar() {

        if isInSelectionMode {
            shareBarBottomConstraint?.isActive = false
            shareBarTopConstraint?.isActive = true
        } else {
            shareBarTopConstraint?.isActive = false
            shareBarBottomConstraint?.isActive = true
        }

        navigationBar.layoutIfNeeded()

        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) {
            self.layoutIfNeeded()
            self.shareBar.alpha = self.isInSelectionMode ? 1.0 : 0.0
        }
    }
}
