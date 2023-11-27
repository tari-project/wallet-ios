//  ChatListCell.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 11/09/2023
	Using Swift 5.0
	Running on macOS 13.5

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
import Combine

final class ChatListCell: DynamicThemeCell {

    struct Model: Identifiable, Hashable {

        let id: String
        let avatar: RoundedAvatarView.Avatar
        let isOnline: Bool
        let title: String
        let message: String
        let badgeNumber: Int
        let timestamp: TimeInterval

        static func == (lhs: ChatListCell.Model, rhs: ChatListCell.Model) -> Bool { lhs.id == rhs.id }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    // MARK: - Subviews

    @View private var avatarView = RoundedAvatarView()
    @View private var statusView = UIView()

    @View private var labelsStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        return view
    }()

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.heavy.withSize(14.0)
        return view
    }()

    @View private var messageLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.light.withSize(14.0)
        view.numberOfLines = 2
        return view
    }()

    @View private var numberBadge: UILabel = {
        let view = UILabel()
        view.textColor = .static.white
        view.font = .Avenir.heavy.withSize(12.0)
        view.textAlignment = .center
        view.clipsToBounds = true
        view.layer.cornerRadius = 6.0
        return view
    }()

    @View private var timestampLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(11.0)
        return view
    }()

    // MARK: - Properties

    private(set) var identifier: String?
    private var dynamicTimestampModel: DynamicTimestampModel?
    private var cancellables = Set<AnyCancellable>()

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
    }

    private func setupConstraints() {

        [titleLabel, messageLabel].forEach(labelsStackView.addArrangedSubview)
        [avatarView, statusView, labelsStackView, numberBadge, timestampLabel].forEach(contentView.addSubview)

        let constraints = [
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25.0),
            avatarView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10.0),
            avatarView.widthAnchor.constraint(equalToConstant: 42.0),
            avatarView.heightAnchor.constraint(equalToConstant: 42.0),
            statusView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            statusView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            statusView.widthAnchor.constraint(equalToConstant: 14.0),
            statusView.heightAnchor.constraint(equalToConstant: 14.0),
            labelsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
            labelsStackView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 15.0),
            labelsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10.0),
            labelsStackView.trailingAnchor.constraint(lessThanOrEqualTo: timestampLabel.leadingAnchor, constant: -8.0),
            numberBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
            numberBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25.0),
            numberBadge.widthAnchor.constraint(greaterThanOrEqualTo: numberBadge.heightAnchor),
            timestampLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25.0),
            timestampLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        statusView.backgroundColor = theme.system.green
        titleLabel.textColor = theme.text.heading
        messageLabel.textColor = theme.text.body
        numberBadge.backgroundColor = theme.icons.active
        timestampLabel.textColor = theme.text.body
    }

    func update(model: Model) {

        identifier = model.id
        avatarView.avatar = model.avatar
        statusView.isHidden = !model.isOnline
        titleLabel.text = model.title
        messageLabel.text = model.message
        numberBadge.text = "\(model.badgeNumber)"
        numberBadge.isHidden = model.badgeNumber == 0

        let timestampModel = DynamicTimestampModel(timestamp: model.timestamp)

        timestampModel.$formattedTimestamp
            .sink { [weak self] in self?.timestampLabel.text = $0 }
            .store(in: &cancellables)

        dynamicTimestampModel = timestampModel
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        numberBadge.layoutIfNeeded()
        statusView.layoutIfNeeded()
        numberBadge.layer.cornerRadius = numberBadge.bounds.height / 2.0
        statusView.layer.cornerRadius = statusView.bounds.height / 2.0
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        dynamicTimestampModel = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
