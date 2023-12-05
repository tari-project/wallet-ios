//  CentredPlaceholder.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 01/12/2023
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

final class CentredPlaceholder: UIView {

    // MARK: - Subviews

    @View private var contentView = UIView()

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    func setup(placeholderView: UIView) {

        contentView.subviews.forEach {
            NSLayoutConstraint.deactivate($0.constraints)
            $0.removeFromSuperview()
        }

        contentView.addSubview(placeholderView)

        let constraints = [
            placeholderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            placeholderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupConstraints() {

        addSubview(contentView)

        let constraints = [
            contentView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            contentView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
