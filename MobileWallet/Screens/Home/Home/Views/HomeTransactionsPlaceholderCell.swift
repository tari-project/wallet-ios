//  HomeTransactionsPlaceholderCell.swift

/*
    Package MobileWallet
    Created by Adrian Truszczyński on 04/07/2023
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

final class HomeTransactionsPlaceholderCell: DynamicThemeCell {

    // MARK: - Subviews

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = .Text.primary
        view.font = .Poppins.Medium.withSize(12.0)
        view.numberOfLines = 0
        view.textAlignment = .center
        view.text = localized("home.transaction_list.placeholder")
        return view
    }()

    @View private var mineButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .small)
        button.setTitle("Start Mining Tari", for: .normal)
        return button
    }()

    // MARK: - Properties

    var onStartMiningButtonTap: (() -> Void)? {
        didSet {
            mineButton.onTap = onStartMiningButtonTap
        }
    }

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
    }

    private func setupConstraints() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(mineButton)

        let constraints = [
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -60),
            mineButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            mineButton.widthAnchor.constraint(equalToConstant: 156),
            mineButton.heightAnchor.constraint(equalToConstant: 36),
            mineButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            contentView.heightAnchor.constraint(equalToConstant: 200)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        titleLabel.textColor = .Text.primary
    }
}
