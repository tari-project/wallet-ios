//  ContactBookCell.swift

/*
	Package MobileWallet
	Created by Browncoat on 10/02/2023
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

import UIKit
import TariCommon

final class ContactBookCell: DynamicThemeCell {

    struct ViewModel: Identifiable, Hashable {
        let id: UUID
        let name: String
        let avatarText: String
        let avatarImage: UIImage?
        let isFavorite: Bool
        let menuItems: [ContactCapsuleMenu.ButtonViewModel]
        let contactTypeImage: UIImage?
    }

    // MARK: - Subviews

    @View private var avatarMenu = ContactCapsuleMenu()

    @View private var contactTypeBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8.0
        return view
    }()

    @View private var contactTypeView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private var nameLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.heavy.withSize(15.0)
        return view
    }()

    @View private var favoriteView: UIImageView = {
        let view = UIImageView()
        view.image = .icons.star.filled
        view.contentMode = .scaleAspectFit
        return view
    }()

    // MARK: - Properties

    private(set) var isExpanded: Bool = false

    var onButtonTap: ((UInt) -> Void)?
    var onExpand: (() -> Void)?

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
        setupCallbacks()
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

        [nameLabel, favoriteView, avatarMenu, contactTypeBackgroundView, contactTypeView].forEach(contentView.addSubview)

        let constraints = [
            avatarMenu.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
            avatarMenu.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22.0),
            avatarMenu.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10.0),
            contactTypeBackgroundView.trailingAnchor.constraint(equalTo: avatarMenu.avatarView.trailingAnchor),
            contactTypeBackgroundView.bottomAnchor.constraint(equalTo: avatarMenu.avatarView.bottomAnchor),
            contactTypeBackgroundView.widthAnchor.constraint(equalToConstant: 16.0),
            contactTypeBackgroundView.heightAnchor.constraint(equalToConstant: 16.0),
            contactTypeView.topAnchor.constraint(equalTo: contactTypeBackgroundView.topAnchor, constant: 3.0),
            contactTypeView.leadingAnchor.constraint(equalTo: contactTypeBackgroundView.leadingAnchor, constant: 3.0),
            contactTypeView.trailingAnchor.constraint(equalTo: contactTypeBackgroundView.trailingAnchor, constant: -3.0),
            contactTypeView.bottomAnchor.constraint(equalTo: contactTypeBackgroundView.bottomAnchor, constant: -3.0),
            nameLabel.leadingAnchor.constraint(equalTo: avatarMenu.avatarView.trailingAnchor, constant: 10.0),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            favoriteView.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 10.0),
            favoriteView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22.0),
            favoriteView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        avatarMenu.onButtonTap = { [weak self] in self?.onButtonTap?($0) }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        nameLabel.textColor = theme.text.heading
        favoriteView.tintColor = theme.brand.purple
        contactTypeBackgroundView.backgroundColor = theme.brand.purple
        contactTypeView.tintColor = theme.backgrounds.primary
    }

    func update(viewModel: ViewModel) {
        nameLabel.text = viewModel.name

        if let avatarImage = viewModel.avatarImage {
            avatarMenu.avatarView.avatar = .image(avatarImage)
        } else {
            avatarMenu.avatarView.avatar = .text(viewModel.avatarText)
        }

        avatarMenu.update(buttons: viewModel.menuItems)
        favoriteView.isHidden = !viewModel.isFavorite
        contactTypeView.image = viewModel.contactTypeImage
        contactTypeBackgroundView.isHidden = viewModel.contactTypeImage == nil
    }

    func updateCell(isExpanded: Bool, withAnmiation: Bool) {

        self.isExpanded = isExpanded

        if isExpanded {
            avatarMenu.show(withAnmiation: withAnmiation)
            onExpand?()
        } else {
            avatarMenu.hide(withAnmiation: withAnmiation)
        }
    }
}
