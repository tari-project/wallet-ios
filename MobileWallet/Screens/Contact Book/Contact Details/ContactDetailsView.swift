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

    private enum IDElementsState {
        case allHidden
        case emojiOnly
        case yatOnly
        case yatHidden
        case yatVisible
    }

    // MARK: - Subviews

    @View private var avatarView = RoundedAvatarView()

    @View private var nameLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(17.0)
        view.textAlignment = .center
        return view
    }()

    @View private var emojiIdView: EmojiIdView = {
        let view = EmojiIdView()
        view.isHidden = true
        return view
    }()

    @View private var yatLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .Avenir.medium.withSize(20.0)
        view.isHidden = true
        return view
    }()

    @View private var yatButton: BaseButton = {
        let view = BaseButton()
        view.setImage(.Icons.Yat.buttonOn, for: .disabled)
        return view
    }()

    @View private var tableView = MenuTableView()
    private var footer = ContactDetailsViewBottomView()

    // MARK: - Properties

    var editButtonName: String? {
        didSet { updateEditButton() }
    }

    var avatar: RoundedAvatarView.Avatar {
        get { avatarView.avatar }
        set { avatarView.avatar = newValue }
    }

    var name: String? {
        get { nameLabel.text }
        set { nameLabel.text = newValue }
    }

    var emojiModel: EmojiIdView.ViewModel? {
        didSet { updateEmojiView() }
    }

    var yat: String? {
        didSet { updateYatView() }
    }

    var tableViewSections: [MenuTableView.Section] = [] {
        didSet { update(viewModel: tableViewSections) }
    }

    var onSelectRow: ((UInt) -> Void)? {
        get { tableView.onSelectRow }
        set { tableView.onSelectRow = newValue }
    }

    var onEditButtonTap: (() -> Void)?

    private var idElementsState: IDElementsState = .allHidden {
        didSet { handle(idElementsState: idElementsState) }
    }

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
        tableView.tableFooterView = footer
    }

    private func setupConstraints() {

        [avatarView, nameLabel, emojiIdView, yatLabel, yatButton, tableView].forEach(addSubview)

        let constraints = [
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
            yatLabel.leadingAnchor.constraint(equalTo: emojiIdView.leadingAnchor),
            yatLabel.trailingAnchor.constraint(equalTo: emojiIdView.trailingAnchor),
            yatLabel.centerYAnchor.constraint(equalTo: emojiIdView.centerYAnchor),
            yatButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            yatButton.centerYAnchor.constraint(equalTo: emojiIdView.centerYAnchor),
            yatButton.widthAnchor.constraint(equalToConstant: 24.0),
            yatButton.heightAnchor.constraint(equalToConstant: 24.0),
            tableView.topAnchor.constraint(equalTo: emojiIdView.bottomAnchor, constant: 20.0),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        yatButton.onTap = { [weak self] in
            self?.toggleYatButton()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
        nameLabel.textColor = theme.text.heading
        yatButton.enabledTintColor = theme.icons.active
        yatButton.diabledTintColor = theme.icons.inactive
    }

    func updateFooter(image: UIImage?, text: String?) {
        footer.update(image: image, text: text)
    }

    private func update(viewModel: [MenuTableView.Section]) {
        tableView.viewModel = viewModel
    }

    private func updateEditButton() {
        navigationBar.update(rightButton: NavigationBar.ButtonModel(title: editButtonName, callback: { [weak self] in self?.onEditButtonTap?() }))
    }

    private func updateEmojiView() {
        updateIDElementsState()
        guard let emojiModel else { return }
        emojiIdView.update(viewModel: emojiModel)
    }

    private func updateYatView() {
        updateIDElementsState()
        yatLabel.text = yat
    }

    private func updateIDElementsState() {
        let isEmojiIdAAvailable = emojiModel?.emojiID != nil && emojiModel?.emojiID.isEmpty == false
        let isYatAvailable = yat != nil && yat?.isEmpty == false

        switch (isEmojiIdAAvailable, isYatAvailable) {
        case (true, true):
            idElementsState = .yatHidden
        case (true, false):
            idElementsState = .emojiOnly
        case (false, true):
            idElementsState = .yatOnly
        case (false, false):
            idElementsState = .allHidden
        }
    }

    // MARK: - Handlers

    private func handle(idElementsState: IDElementsState) {

        switch idElementsState {
        case .allHidden:
            emojiIdView.isHidden = true
            yatLabel.isHidden = true
            yatButton.isHidden = true
        case .emojiOnly:
            emojiIdView.isHidden = false
            yatLabel.isHidden = true
            yatButton.isHidden = true
        case .yatOnly:
            emojiIdView.isHidden = true
            yatLabel.isHidden = false
            yatButton.isHidden = false
            yatButton.isEnabled = false
        case .yatHidden:
            emojiIdView.isHidden = false
            yatLabel.isHidden = true
            yatButton.isHidden = false
            yatButton.isEnabled = true
            yatButton.setImage(.Icons.Yat.buttonOn, for: .normal)
        case .yatVisible:
            emojiIdView.isHidden = true
            yatLabel.isHidden = false
            yatButton.isHidden = false
            yatButton.isEnabled = true
            yatButton.setImage(.Icons.Yat.buttonOff, for: .normal)
        }
    }

    // MARK: - Actions

    private func toggleYatButton() {

        switch idElementsState {
        case .yatHidden:
            idElementsState = .yatVisible
        case .yatVisible:
            idElementsState =  .yatHidden
        case .allHidden, .emojiOnly, .yatOnly:
            return
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.updateFooterFrame()
    }
}

private final class ContactDetailsViewBottomView: DynamicThemeView {

    // MARK: - Subviews

    @View private var contentView = UIView()

    @View private var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(15.0)
        return view
    }()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        addSubview(contentView)
        [imageView, label].forEach(contentView.addSubview)

        let constraints = [
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 12.0),
            imageView.heightAnchor.constraint(equalToConstant: 12.0),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10.0),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        imageView.tintColor = theme.text.body
        label.textColor = theme.text.body
    }

    func update(image: UIImage?, text: String?) {
        imageView.image = image
        label.text = text
    }
}
