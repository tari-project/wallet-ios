//  RoundedAddressView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 18/07/2024
	Using Swift 5.0
	Running on macOS 14.4

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

final class RoundedAddressView: DynamicThemeView {

    // MARK: - Subviews

    @TariView private var addressView = AddressView()

    // MARK: - Properties

    var isCompact: Bool {
        get { addressView.isCompact }
        set { addressView.isCompact = newValue }
    }

    var onViewDetailsButtonTap: (() -> Void)? {
        get { addressView.onViewDetailsButtonTap }
        set { addressView.onViewDetailsButtonTap = newValue }
    }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        layer.cornerRadius = 10.0
    }

    private func setupConstraints() {

        addSubview(addressView)

        let constraints = [
            addressView.topAnchor.constraint(equalTo: topAnchor, constant: 10.0),
            addressView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 10.0),
            addressView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10.0),
            addressView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10.0),
            addressView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
    }

    func update(viewModel: AddressView.ViewModel) {
        addressView.update(viewModel: viewModel)
    }
}
