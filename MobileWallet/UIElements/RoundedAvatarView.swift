//  RoundedAvatarView.swift

/*
	Package MobileWallet
	Created by Browncoat on 22/02/2023
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

final class RoundedAvatarView: DynamicThemeView {

    enum Avatar {
        case text(_: String?)
        case image(_: UIImage?)
        case empty
    }

    enum BackgroundColorType {
        case `dynamic`
        case `static`
    }

    // MARK: - Subviews

    @TariView private var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.contentMode = .scaleAspectFit
        return label
    }()

    @TariView private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Properties

    var avatar: Avatar = .empty {
        didSet { update(avatar: avatar) }
    }

    var backgroundColorType: BackgroundColorType = .dynamic {
        didSet { updateDynamicElements(theme: theme) }
    }

    var imagePadding: CGFloat = 0.0 {
        didSet {
            imageViewPositiveContraints.forEach { $0.constant = imagePadding }
            imageViewNegativeContraints.forEach { $0.constant = -imagePadding }
        }
    }

    private var imageViewPositiveContraints: [NSLayoutConstraint] = []
    private var imageViewNegativeContraints: [NSLayoutConstraint] = []

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
        imageView.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [label, imageView].forEach(addSubview)

        let constraints = [
            label.heightAnchor.constraint(equalTo: heightAnchor),
            label.widthAnchor.constraint(equalTo: widthAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        imageViewPositiveContraints = [
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ]

        imageViewNegativeContraints = [
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints + imageViewPositiveContraints + imageViewNegativeContraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.lightText
        updateDynamicElements(theme: theme)
    }

    private func updateDynamicElements(theme: AppTheme) {

        switch backgroundColorType {
        case .dynamic:
            backgroundColor = theme.backgrounds.primary
            apply(shadow: theme.shadows.box)
        case .static:
            backgroundColor = .Static.white
            apply(shadow: .none)
        }
    }

    private func update(avatar: Avatar) {
        switch avatar {
        case let .text(text):
            label.text = text
            imageView.image = nil
        case let .image(image):
            label.text = nil
            imageView.image = image
        case .empty:
            label.text = nil
            imageView.image = nil
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = frame.height / 2.0
        layer.cornerRadius = size
        imageView.layer.cornerRadius = size
        label.font = .Poppins.Medium.withSize(size)
    }
}
