//  ContactCapsuleMenu.swift

/*
	Package MobileWallet
	Created by Browncoat on 20/02/2023
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

final class ContactCapsuleMenu: UIView {

    struct ButtonViewModel: Identifiable, Hashable {
        let id: UInt
        let icon: UIImage?
    }

    // MARK: - Subviews

    @View private var backgroundView = ContactCapsuleMenuBackground()
    @View private(set) var avatarView = RoundedAvatarView()

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 15.0
        return view
    }()

    // MARK: - Properties

    var onButtonTap: ((UInt) -> Void)?
    private var avatarViewFrame: CGRect { CGRect(origin: stackView.frame.origin, size: avatarView.frame.size) }

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupConstraints()
        setupGradientMask()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [backgroundView, stackView].forEach(addSubview)
        update(buttons: [])

        let constraints = [
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 44.0),
            avatarView.heightAnchor.constraint(equalToConstant: 44.0),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8.0),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8.0),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupGradientMask() {
        layoutIfNeeded()
        backgroundView.maskFrame = avatarViewFrame
    }

    // MARK: - Updates

    func update(buttons: [ButtonViewModel]) {

        stackView.arrangedSubviews.forEach {
            self.stackView.removeArrangedSubview($0)
            guard $0 != avatarView else { return }
            $0.removeFromSuperview()
        }

        var views: [UIView] = [avatarView]
        views += buttons.map { self.makeButton(model: $0) }

        views.forEach(stackView.addArrangedSubview)
    }

    // MARK: - Actions

    func show(withAnmiation animated: Bool) {

        stackView.arrangedSubviews
            .compactMap { $0 as? ContactBookMenuButton }
            .forEach { $0.show() }

        let duration: TimeInterval = animated ? 0.3 : 0.0
        layoutIfNeeded()

        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [.beginFromCurrentState]) {
            self.backgroundView.maskFrame = self.bounds
        }
    }

    func hide(withAnmiation animated: Bool) {

        stackView.arrangedSubviews
            .compactMap { $0 as? ContactBookMenuButton }
            .forEach { $0.hide() }

        let duration: TimeInterval = animated ? 0.3 : 0.0

        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [.beginFromCurrentState]) {
            self.backgroundView.maskFrame = self.avatarViewFrame
        }
    }

    // MARK: - Helpers

    private func makeButton(model: ButtonViewModel) -> ContactBookMenuButton {
        let button = ContactBookMenuButton()
        button.image = model.icon
        button.onTap = { [weak self] in self?.onButtonTap?(model.id) }
        button.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        return button
    }

    // MARK: - Autolayout

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.layer.cornerRadius = frame.height * 0.5
    }
}
