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

    struct ViewModel: Identifiable {
        let id: UUID
        let addressViewModel: AddressView.ViewModel
        let isFavorite: Bool
        let contactTypeImage: UIImage?
        let isSelectable: Bool
    }

    // MARK: - Subviews

    @TariView private var contactTypeBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8.0
        return view
    }()

    @TariView private var contactTypeView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    @TariView private var separatorView = UIView()
    @TariView private var contectSectionView = UIView()

    @TariView private var stackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 8.0
        return view
    }()

    @TariView private var addressView = AddressView()

    @TariView private var favoriteView: UIImageView = {
        let view = UIImageView()
        view.image = .Icons.General.star
        view.contentMode = .scaleAspectFit
        return view
    }()

    @TariView private var tickView: TickButton = {
        let view = TickButton()
        view.alpha = 0.0
        return view
    }()

    // MARK: - Properties

    var isTickSelected: Bool {
        get { tickView.isSelected }
        set { tickView.isSelected = newValue }
    }

    private(set) var elementID: UUID?

    private var isSelectable: Bool = false
    private var normalModeConstraint: NSLayoutConstraint?
    private var editModeConstraint: NSLayoutConstraint?

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

        [contectSectionView, addressView].forEach(stackView.addArrangedSubview)
        [contactTypeBackgroundView, contactTypeView, separatorView].forEach(contectSectionView.addSubview)
        [tickView, stackView, favoriteView].forEach(contentView.addSubview)

        let normalModeConstraint = stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0)
        editModeConstraint = tickView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22.0)

        self.normalModeConstraint = normalModeConstraint

        let constraints = [
            tickView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tickView.heightAnchor.constraint(equalToConstant: 24.0),
            tickView.widthAnchor.constraint(equalToConstant: 24.0),
            normalModeConstraint,
            contactTypeBackgroundView.leadingAnchor.constraint(equalTo: contectSectionView.leadingAnchor),
            contactTypeBackgroundView.centerYAnchor.constraint(equalTo: contectSectionView.centerYAnchor),
            contactTypeBackgroundView.widthAnchor.constraint(equalToConstant: 16.0),
            contactTypeBackgroundView.heightAnchor.constraint(equalToConstant: 16.0),
            contactTypeView.topAnchor.constraint(equalTo: contactTypeBackgroundView.topAnchor, constant: 3.0),
            contactTypeView.leadingAnchor.constraint(equalTo: contactTypeBackgroundView.leadingAnchor, constant: 3.0),
            contactTypeView.trailingAnchor.constraint(equalTo: contactTypeBackgroundView.trailingAnchor, constant: -3.0),
            contactTypeView.bottomAnchor.constraint(equalTo: contactTypeBackgroundView.bottomAnchor, constant: -3.0),
            separatorView.leadingAnchor.constraint(equalTo: contactTypeBackgroundView.trailingAnchor, constant: 8.0),
            separatorView.trailingAnchor.constraint(equalTo: contectSectionView.trailingAnchor),
            separatorView.centerYAnchor.constraint(equalTo: contectSectionView.centerYAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 1.0),
            separatorView.heightAnchor.constraint(equalToConstant: 14.0),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24.0),
            stackView.leadingAnchor.constraint(equalTo: tickView.trailingAnchor, constant: 10.0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24.0),
            favoriteView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22.0),
            favoriteView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = .clear
        favoriteView.tintColor = theme.brand.purple
        contactTypeBackgroundView.backgroundColor = theme.brand.purple
        contactTypeView.tintColor = theme.buttons.primaryText
        separatorView.backgroundColor = theme.text.lightText
    }

    func update(viewModel: ViewModel) {
        elementID = viewModel.id
        isSelectable = viewModel.isSelectable
        addressView.update(viewModel: viewModel.addressViewModel)
        favoriteView.isHidden = !viewModel.isFavorite
        contactTypeView.image = viewModel.contactTypeImage
        contectSectionView.isHidden = viewModel.contactTypeImage == nil
    }

    override func setEditing(_ editing: Bool, animated: Bool) {

        let isTickVisible = editing && isSelectable
        let isDimmed = editing && !isSelectable

        if isTickVisible {
            normalModeConstraint?.isActive = false
            editModeConstraint?.isActive = true
        } else {
            editModeConstraint?.isActive = false
            normalModeConstraint?.isActive = true
        }

        let duration: TimeInterval = animated ? 0.3 : 0.0

        UIView.animate(withDuration: duration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) {
            self.tickView.alpha = isTickVisible ? 1.0 : 0.0
            self.alpha = isDimmed ? 0.6 : 1.0
            self.layoutIfNeeded()
        }
    }
}

extension ContactBookCell.ViewModel: Equatable, Hashable {

    static func == (lhs: ContactBookCell.ViewModel, rhs: ContactBookCell.ViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
