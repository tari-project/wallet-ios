//  AboutViewHeader.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 26/05/2022
	Using Swift 5.0
	Running on macOS 12.3

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

final class AboutViewHeader: DynamicThemeHeaderFooterView {

    // MARK: - Subviews

    @View private var tintedBackgroundView: UIView = {
        let view = UIView()
        return view
    }()

    @View private var label: UILabel = {
        let view = UILabel()
        view.text = localized("about.label.creative_commons")
        view.font = .Poppins.Light.withSize(14.0)
        return view
    }()

    @View private var button: TextButton = {
        let view = TextButton()
        view.setTitle(localized("about.button.creative_commons"), for: .normal)
        view.style = .secondary
        view.font = .Poppins.Light.withSize(14.0)
        return view
    }()

    // MARK: - Properties

    var onButtonTap: (() -> Void)?

    // MARK: - Initialisers

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupConstraint()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraint() {

        [tintedBackgroundView, label, button].forEach(addSubview)

        let constraints = [
            tintedBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            tintedBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tintedBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tintedBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 5.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: -5.0),
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            button.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -25.0),
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        button.onTap = { [weak self] in
            self?.onButtonTap?()
        }
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        tintedBackgroundView.backgroundColor = theme.backgrounds.primary
        label.textColor = theme.text.heading
    }
}
