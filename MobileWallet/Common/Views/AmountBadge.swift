//  AmountBadge.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 28/06/2023
	Using Swift 5.0
	Running on macOS 13.4

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

final class AmountBadge: DynamicThemeView {

    enum ValueType {
        /// Green
        case positive
        /// Red
        case negative
        /// Yellow
        case waiting
        /// Grey
        case invalidated
    }

    struct ViewModel: Hashable {
        let amount: String?
        let valueType: ValueType
    }

    // MARK: - Subviews

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = .Poppins.Black.withSize(12.0)
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()

    // MARK: - Properties

    private var valueType: ValueType = .invalidated

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
        layer.cornerRadius = 3.0
    }

    private func setupConstraints() {

        addSubview(label)

        let constraints = [
            label.topAnchor.constraint(equalTo: topAnchor, constant: 5.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5.0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5.0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        updateColors(valueType: valueType, theme: theme)
    }

    func update(viewModel: ViewModel) {
        label.text = viewModel.amount
        valueType = viewModel.valueType
        updateColors(valueType: viewModel.valueType, theme: theme)
    }

    private func updateColors(valueType: ValueType, theme: AppTheme) {
        switch valueType {
        case .positive:
            backgroundColor = theme.system.lightGreen
            label.textColor = theme.system.green
        case .negative:
            backgroundColor = theme.system.lightRed
            label.textColor = theme.system.red
        case .waiting:
            backgroundColor = theme.system.lightYellow
            label.textColor = theme.system.yellow
        case .invalidated:
            backgroundColor = theme.backgrounds.secondary
            label.textColor = theme.text.lightText
        }
    }
}
