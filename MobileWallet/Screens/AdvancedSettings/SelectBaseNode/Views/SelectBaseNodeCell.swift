//  SelectBaseNodeCell.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 20/07/2021
	Using Swift 5.0
	Running on macOS 12.0

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

final class SelectBaseNodeCell: DynamicThemeCell {

    enum AccessoryType {
        case none, tick, deleteButton
    }

    // MARK: - Subviews

    private let titleLabel: UILabel = {
       let view = UILabel()
        view.font = Theme.shared.fonts.systemTableViewCell
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let subtitleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.systemTableViewCellMarkDescriptionSmall
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let labelsStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 4.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let tickView: UIImageView = {
        let view = UIImageView(image: Theme.shared.images.scheduledIcon)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let deleteButton: UIButton = {
        let view = UIButton()
        view.titleLabel?.font = UIFont.Avenir.heavy.withSize(14.0)
        view.setTitle(localized("select_base_node.cell.delete"), for: .normal)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties

    var onDeleteButtonTap: (() -> Void)?

    // MARK: - Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
        setupFeedbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func prepareForReuse() {
        update(title: nil, subtitle: nil, accessoryType: .none)
    }

    // MARK: - Setups

    private func setupConstraints() {

        [labelsStackView, deleteButton, tickView].forEach(contentView.addSubview)
        [titleLabel, subtitleLabel].forEach(labelsStackView.addArrangedSubview)

        let heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 65.0)
        heightConstraint.priority = .sceneSizeStayPut

        let constraints = [
            labelsStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            labelsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25.0),
            deleteButton.topAnchor.constraint(equalTo: topAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: labelsStackView.trailingAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12.0),
            deleteButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            tickView.centerYAnchor.constraint(equalTo: centerYAnchor),
            tickView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12.0),
            tickView.widthAnchor.constraint(equalToConstant: 21.0),
            tickView.heightAnchor.constraint(equalToConstant: 21.0),
            heightConstraint
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupFeedbacks() {
        selectionStyle = .none
        deleteButton.addTarget(self, action: #selector(onDeleteButtonTapAction), for: .touchUpInside)
    }

    func update(title: String?, subtitle: String?, accessoryType: AccessoryType) {
        titleLabel.text = title
        subtitleLabel.text = subtitle

        switch accessoryType {
        case .tick:
            self.tickView.isHidden = false
            self.deleteButton.isHidden = true
        case .deleteButton:
            self.tickView.isHidden = true
            self.deleteButton.isHidden = false
        case .none:
            self.tickView.isHidden = true
            self.deleteButton.isHidden = true
        }
    }

    // MARK: - Action Targets

    @objc private func onDeleteButtonTapAction() {
        onDeleteButtonTap?()
    }

    // MARK: - State Setters

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {

        guard !highlighted else {
            contentView.alpha = 0.5
            return
        }

        UIView.animate(withDuration: CATransaction.animationDuration(), delay: 0.0, options: .curveEaseIn) {
            self.contentView.alpha = 1.0
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        titleLabel.textColor = theme.text.heading
        subtitleLabel.textColor = theme.text.body
        deleteButton.setTitleColor(theme.system.red, for: .normal)
        deleteButton.setTitleColor(theme.system.red?.withAlphaComponent(0.5), for: .highlighted)
    }
}
