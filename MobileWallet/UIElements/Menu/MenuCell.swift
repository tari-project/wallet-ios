//  MenuCell.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 27/02/2023
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

final class MenuCell: DynamicThemeCell {

    struct ViewModel: Hashable, Identifiable {
        let id: UInt
        let title: String?
        let isArrowVisible: Bool
        let isDestructive: Bool
    }

    // MARK: - Subviews

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(15.0)
        return view
    }()

    @View private var accessoryItemView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.forwardArrow
        view.contentMode = .scaleAspectFit
        return view
    }()

    // MARK: - Properties

    var viewModel: ViewModel? {
        didSet { update(viewModel: viewModel) }
    }

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupView() {
        selectionStyle = .none
    }

    private func setupConstraints() {

        [titleLabel, accessoryItemView].forEach(contentView.addSubview)

        let constraints = [
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25.0),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            accessoryItemView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25.0),
            accessoryItemView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 63.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        updateTintColor(theme: theme)
    }

    private func updateTintColor(theme: ColorTheme) {

        let isDestructive = viewModel?.isDestructive ?? false
        let tintColor = isDestructive ? theme.system.red : theme.text.heading

        titleLabel.textColor = tintColor
        accessoryItemView.tintColor = tintColor
    }

    private func update(viewModel: ViewModel?) {

        defer { updateTintColor(theme: theme) }

        guard let viewModel else {
            titleLabel.text = nil
            accessoryItemView.isHidden = true
            return
        }

        titleLabel.text = viewModel.title
        accessoryItemView.isHidden = !viewModel.isArrowVisible
    }
}
