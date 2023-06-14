//  ContactCell.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/02/11
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

import UIKit
import TariCommon

final class ContactCell: DynamicThemeCell {

    // MARK: - Views

    @View private var contactAvatarView = ContactAvatarView()

    @View private var aliasLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.heavy.withSize(15.0)
        return view
    }()

    // MARK: - Properties

    var initial: String {
        get { contactAvatarView.text }
        set { contactAvatarView.text = newValue }
    }

    var aliasText: String? {
        get { aliasLabel.text }
        set { aliasLabel.text = newValue }
    }

    var isEmojiID: Bool = false {
        didSet { updateAliasLabelColors(theme: theme) }
    }

    // MARK: - Initializers

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

        translatesAutoresizingMaskIntoConstraints = false

        [contactAvatarView, aliasLabel].forEach(contentView.addSubview)

        let constraints = [
            contactAvatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contactAvatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22.0),
            aliasLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            aliasLabel.leadingAnchor.constraint(equalTo: contactAvatarView.trailingAnchor, constant: 10.0),
            aliasLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            aliasLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            aliasLabel.heightAnchor.constraint(equalToConstant: aliasLabel.font.pointSize * 1.15),
            contentView.heightAnchor.constraint(equalToConstant: 70.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        updateAliasLabelColors(theme: theme)
    }

    private func updateAliasLabelColors(theme: ColorTheme) {
        aliasLabel.textColor = isEmojiID ? theme.text.lightText : theme.text.heading
    }

    // MARK: - States

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: true)

        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn) {
            self.contentView.subviews.forEach { $0.alpha = self.isHighlighted ? 0.6 : 1.0 }
        }
    }
}
