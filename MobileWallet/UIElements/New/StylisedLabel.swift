//  StylisedLabel.swift

/*
    Package MobileWallet
    Created by Konrad Faltyn on 2024/12/28
    Using Swift 5.0
    Running on macOS 10.15

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
import Lottie

final class StylisedLabel: DynamicThemeView {

    enum Style {
        case headingXL
        case headingXLAlternate
        case heading2XL
        case headlingLG
        case headingMG
        case headingSM
        case body1
        case body2
        case modalTitleLG
        case modalTitle
        case menuItem
        case balanceTitle
        case balanceUnit
        case textBtn
        case buttonLarge
        case buttonMedium
        case buttonSmall
    }

    // MARK: - Subviews
    @View private var labelView: UILabel = {
        let label = UILabel()
        return label
    }()

    // MARK: - Properties

    var style: Style = .body1 {
        didSet { update(style: style, theme: theme) }
    }

    var text: String {
        get {
            return labelView.text ?? ""
        }
        set {
            labelView.text = newValue
        }
    }

    // MARK: - Initialisers

    init(withStyle: StylisedLabel.Style) {
        super.init()

        style = withStyle
        setupViews()
        setupConstraints()
        update(theme: theme)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
    }

    private func setupConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelView)

        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: topAnchor),
            labelView.leftAnchor.constraint(equalTo: leftAnchor),
            labelView.rightAnchor.constraint(equalTo: rightAnchor),
            labelView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Updates
    override func update(theme: AppTheme) {
        super.update(theme: theme)

        switch style {
            case .heading2XL:
            labelView.textColor = .Text.primary
            labelView.font = Typography.heading2XL
            case .headingXLAlternate:
            labelView.textColor = .white
            labelView.font = Typography.headingXL
            case .headingXL:
            labelView.textColor = .Text.primary
            labelView.font = Typography.headingXL
            case .headlingLG:
            labelView.textColor = .Text.primary
            labelView.font = Typography.headingLG
            case .headingMG:
            labelView.textColor = .Text.primary
            labelView.font = Typography.headingMG
            case .headingSM:
            labelView.textColor = .Text.primary
            labelView.font = Typography.headingSM
            case .body1:
            labelView.textColor = .Text.body
            labelView.font = Typography.body1
            case .body2:
            labelView.textColor = .Text.body
            labelView.font = Typography.body2
            case .modalTitleLG:
            labelView.textColor = .Text.primary
            labelView.font = Typography.modalTitleLG
            case .modalTitle:
            labelView.textColor = .Text.primary
            labelView.font = Typography.modalTitle
            case .menuItem:
            labelView.textColor = .Text.primary
            labelView.font = Typography.menuItem
            case .balanceTitle:
            labelView.textColor = .Text.primary
            labelView.font = Typography.menuItem
            case .textBtn:
            labelView.textColor = .Text.primary
            labelView.font = Typography.textBtn
            case .buttonLarge:
            labelView.textColor = .Text.primary
            labelView.font = Typography.buttonLarge
            case .buttonMedium:
            labelView.textColor = .Text.primary
            labelView.font = Typography.buttonMedium
            case .buttonSmall:
            labelView.textColor = .Text.primary
            labelView.font = Typography.buttonSmall
            case .balanceUnit:
            labelView.textColor = .Text.primary
            labelView.font = .Poppins.SemiBold.withSize(20)
        }
    }

    private func update(style: Style, theme: AppTheme) {
        update(theme: theme)
    }
}
