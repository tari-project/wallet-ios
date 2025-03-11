//  NetworkTrafficView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 20/05/2022
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

final class NetworkTrafficView: DynamicThemeView {

    enum Variant {
        case lowTraffic
        case mediumTraffic
        case highTraffic
    }

    // MARK: - Subviews

    @View private var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private var label: UILabel = {
        let view = UILabel()
        view.text = localized("add_amount.label.network_traffic")
        view.font = .Poppins.Medium.withSize(14.0)
        return view
    }()

    // MARK: - Properties

    var variant: Variant = .lowTraffic {
        didSet { updateIcon() }
    }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
        updateIcon()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [iconView, label].forEach(addSubview)

        let constraints = [
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 16.0),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5.0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightAnchor.constraint(equalToConstant: 21.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        iconView.tintColor = theme.text.body
        label.textColor = theme.text.body
    }

    private func updateIcon() {
        switch variant {
        case .lowTraffic:
            iconView.image = .Icons.Fees.Speedometer.low
        case .mediumTraffic:
            iconView.image = .Icons.Fees.Speedometer.mid
        case .highTraffic:
            iconView.image = .Icons.Fees.Speedometer.high
        }
    }
}
