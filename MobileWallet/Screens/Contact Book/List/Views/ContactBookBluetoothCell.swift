//  ContactBookBluetoothCell.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 31/05/2023
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

final class ContactBookBluetoothCell: DynamicThemeCell {

    // MARK: - Subviews

    @View private var avatarView: RoundedAvatarView = {
        let view = RoundedAvatarView()
        view.avatar = .image(.Icons.General.bluetooth)
        view.imagePadding = 10.0
        return view
    }()

    @View private var labelsContentView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        return view
    }()

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("contact_book.cell.bluetooth.lable.title")
        view.font = .Avenir.heavy.withSize(15.0)
        return view
    }()

    @View private var subtitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("contact_book.cell.bluetooth.lable.subtitle")
        view.font = .Avenir.medium.withSize(13.0)
        return view
    }()

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
        selectionStyle = .none
        backgroundColor = .clear
    }

    private func setupConstraints() {

        [avatarView, labelsContentView].forEach(contentView.addSubview)
        [titleLabel, subtitleLabel].forEach(labelsContentView.addArrangedSubview)

        let constraints = [
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22.0),
            avatarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10.0),
            avatarView.widthAnchor.constraint(equalToConstant: 44.0),
            avatarView.heightAnchor.constraint(equalToConstant: 44.0),
            labelsContentView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
            labelsContentView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10.0),
            labelsContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22.0),
            labelsContentView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            labelsContentView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        avatarView.tintColor = theme.icons.default
        titleLabel.textColor = theme.text.heading
        subtitleLabel.textColor = theme.text.body
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        let duration: TimeInterval = animated ? 0.3 : 0.0
        UIView.animate(withDuration: duration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) {
            self.alpha = editing ? 0.6 : 1.0
        }
    }
}
