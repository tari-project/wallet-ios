//  ContactDetailsView.swift

/*
	Package MobileWallet
	Created by Browncoat on 23/02/2023
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

final class ContactDetailsView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var avatarView: RoundedAvatarView = {
        let view = RoundedAvatarView()
        view.titleLabel?.font = .Avenir.medium.withSize(46.0)
        return view
    }()

    @View private var nameLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(17.0)
        view.textAlignment = .center
        return view
    }()

    @View private var emojiIdView = EmojiIdView()
    @View private var tableView = MenuTableView()

    // MARK: - Properties

    var avatar: String? {
        get { avatarView.title(for: .normal) }
        set { avatarView.setTitle(newValue, for: .normal) }
    }

    var name: String? {
        get { nameLabel.text }
        set { nameLabel.text = newValue }
    }

    var emojiModel: EmojiIdView.ViewModel? {
        didSet {
            guard let emojiModel else { return }
            emojiIdView.update(viewModel: emojiModel)
        }
    }

    var tableViewSections: [MenuTableView.Section] = [] {
        didSet { update(viewModel: tableViewSections) }
    }

    var onSelectRow: ((UInt) -> Void)? {
        get { tableView.onSelectRow }
        set { tableView.onSelectRow = newValue }
    }

    var onEditButtonTap: (() -> Void)?

    // MARK: - Initalisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        navigationBar.title = localized("contact_book.details.title")
        navigationBar.rightButton.setTitle(localized("common.edit"), for: .normal)
    }

    private func setupConstraints() {

        [avatarView, nameLabel, emojiIdView, tableView].forEach(addSubview)

        let constraints = [ // TODO: Constants
            avatarView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 21.0),
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 90.0),
            avatarView.heightAnchor.constraint(equalToConstant: 90.0),
            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 10.0),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            emojiIdView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10.0),
            emojiIdView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            emojiIdView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            emojiIdView.heightAnchor.constraint(equalToConstant: 38.0),
            tableView.topAnchor.constraint(equalTo: emojiIdView.bottomAnchor, constant: 20.0),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        navigationBar.onRightButtonAction = { [weak self] in
            self?.onEditButtonTap?()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
        nameLabel.textColor = theme.text.heading
    }

    private func update(viewModel: [MenuTableView.Section]) {
        tableView.viewModel = viewModel
    }
}
