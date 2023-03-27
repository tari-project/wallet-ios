//  ContactBookShareBar.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 29/03/2023
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

final class ContactBookShareBar: UIView {

    enum ButtonType: Int, CaseIterable {
        case qr
        case link
        case ble
    }

    // MARK: - Subviews

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .fillEqually
        view.spacing = 44.0
        return view
    }()

    // MARK: - Properties

    private(set) var selectedButtonType: ButtonType = .qr {
        didSet { updateButtons() }
    }

    // MARK: - Initliasers

    init() {
        super.init(frame: .zero)
        setupConstraints()
        setupButtons()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Subviews

    private func setupConstraints() {

        addSubview(stackView)

        let constraints = [
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 112.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupButtons() {
        ButtonType.allCases
            .map { makeButton(type: $0) }
            .forEach { stackView.addArrangedSubview($0) }
    }

    private func makeButton(type: ButtonType) -> ContactBookShareButton {
        @View var button = ContactBookShareButton()
        button.isSelected = type == selectedButtonType
        button.update(image: type.icon, text: type.text)
        button.onTap = { [weak self] in self?.selectedButtonType = type }
        return button
    }

    private func updateButtons() {
        stackView.arrangedSubviews
            .compactMap { $0 as? ContactBookShareButton }
            .enumerated()
            .forEach { $1.isSelected = $0 == self.selectedButtonType.rawValue }
    }
}

extension ContactBookShareBar.ButtonType {

    var icon: UIImage? {
        switch self {
        case .qr:
            return Theme.shared.images.qrButton?.withRenderingMode(.alwaysTemplate)
        case .link:
            return .icons.link
        case .ble:
            return .icons.bluetooth
        }
    }

    var text: String? {
        switch self {
        case .qr:
            return localized("contact_book.share_bar.buttons.qr")
        case .link:
            return localized("contact_book.share_bar.buttons.link")
        case .ble:
            return localized("contact_book.share_bar.buttons.ble")
        }
    }
}

private class ContactBookShareButton: DynamicThemeView {

    // MARK: - Subviews

    @View private var roundedView = RoundedButton()

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(14.0)
        view.textAlignment = .center
        return view
    }()

    // MARK: - Properties

    var onTap: (() -> Void)?

    var isSelected: Bool = false {
        didSet { updateColors(theme: theme) }
    }

    // MARK: - Initliasers

    override init() {
        super.init()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [roundedView, label].forEach(addSubview)

        let constraints = [
            roundedView.topAnchor.constraint(equalTo: topAnchor),
            roundedView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            roundedView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            roundedView.centerXAnchor.constraint(equalTo: centerXAnchor),
            roundedView.heightAnchor.constraint(equalToConstant: 46.0),
            roundedView.widthAnchor.constraint(equalToConstant: 46.0),
            label.topAnchor.constraint(equalTo: roundedView.bottomAnchor, constant: 5.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        roundedView.onTap = { [weak self] in
            self?.onTap?()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        roundedView.apply(shadow: theme.shadows.box)
        updateColors(theme: theme)
    }

    private func updateColors(theme: ColorTheme) {
        roundedView.backgroundColor = isSelected ? theme.brand.purple : theme.buttons.primaryText
        roundedView.tintColor = isSelected ? theme.backgrounds.primary : theme.icons.default
        label.textColor = isSelected ? theme.text.heading : theme.text.body
    }

    func update(image: UIImage?, text: String?) {
        roundedView.setImage(image, for: .normal)
        label.text = text
    }
}
