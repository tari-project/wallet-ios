//  LeftImageButton.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 29/06/2022
	Using Swift 5.0
	Running on macOS 12.3

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

final class LeftImageButton: BaseButton {

    // MARK: - Subviews

    @View private(set) var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private(set) var label: UILabel = {
        let view = UILabel()
        return view
    }()

    // MARK: - Properties

    var borderPadding: UIEdgeInsets = .zero {
        didSet {
            topConstraint?.constant = borderPadding.top
            leadingConstraint?.constant = borderPadding.left
            trailingConstraint?.constant = borderPadding.right
            bottomConstraint?.constant = borderPadding.bottom
        }
    }

    var internalPadding: CGFloat = 0.0 {
        didSet { internalPaddingConstraint?.constant = internalPadding }
    }

    var iconSize: CGSize = .zero {
        didSet {
            iconWidthConstraint?.constant = iconSize.width
            iconHeightConstraint?.constant = iconSize.height
        }
    }

    private var topConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var internalPaddingConstraint: NSLayoutConstraint?
    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [iconView, label].forEach(addSubview)

        let topConstraint = label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor)
        let leadingConstraint = iconView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailingConstraint = label.trailingAnchor.constraint(equalTo: trailingAnchor)
        let bottomConstraint = label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        let internalPaddingConstraint = label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor)
        let iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: 0.0)
        let iconHeightConstraint = iconView.heightAnchor.constraint(equalToConstant: 0.0)

        self.topConstraint = topConstraint
        self.leadingConstraint = leadingConstraint
        self.trailingConstraint = trailingConstraint
        self.bottomConstraint = bottomConstraint
        self.internalPaddingConstraint = internalPaddingConstraint
        self.iconHeightConstraint = iconHeightConstraint
        self.iconWidthConstraint = iconWidthConstraint

        let constraints = [
            topConstraint,
            leadingConstraint,
            trailingConstraint,
            bottomConstraint,
            internalPaddingConstraint,
            iconHeightConstraint,
            iconWidthConstraint,
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
