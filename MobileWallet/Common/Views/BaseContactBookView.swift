//  BaseContactBookView.swift

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

final class BaseContactBookView: DynamicThemeView {

    // MARK: - Subviews

    @View private var searchTextField: SearchField = {
        let view = SearchField()
        view.placeholder = localized("contact_book.search_bar.placeholder")
        return view
    }()

    // MARK: - Properties

    var returnKeyType: UIReturnKeyType {
        get { searchTextField.returnKeyType }
        set { searchTextField.returnKeyType = newValue }
    }

    var onReturnKeyTap: (() -> Void)? {
        get { searchTextField.onReturnTap }
        set { searchTextField.onReturnTap = newValue }
    }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
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

    func setupSearchTextFieldCallback(subject: CurrentValueSubject<String, Never>, storeIn cancellables: inout Set<AnyCancellable>) {
        searchTextField.bind(withSubject: subject, storeIn: &cancellables)
    }

    private func setupConstraints() {

        addSubview(searchTextField)

        let constraints = [
            searchTextField.topAnchor.constraint(equalTo: topAnchor, constant: 20.0),
            searchTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            searchTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
