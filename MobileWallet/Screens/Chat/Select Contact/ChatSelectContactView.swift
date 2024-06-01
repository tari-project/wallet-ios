//  ChatSelectContactView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 28/11/2023
	Using Swift 5.0
	Running on macOS 14.0

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

final class ChatSelectContactView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var contactBookView = BaseContactBookView()

    // MARK: - Properties

    var searchText: AnyPublisher<String, Never> { searchTextSubject.eraseToAnyPublisher() }

    var onReturnKeyTap: (() -> Void)? {
        get { contactBookView.onReturnKeyTap }
        set { contactBookView.onReturnKeyTap = newValue }
    }

    private let searchTextSubject = CurrentValueSubject<String, Never>("")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    func setup(pagerView: UIView) {
        contactBookView.setup(pagerView: pagerView)
    }

    private func setupViews() {
        navigationBar.title = localized("chat.contacts.title")
        contactBookView.returnKeyType = .continue
    }

    private func setupConstraints() {

        addSubview(contactBookView)

        let constraints = [
            contactBookView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            contactBookView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contactBookView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contactBookView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        contactBookView.setupSearchTextFieldCallback(subject: searchTextSubject, storeIn: &cancellables)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
    }
}
