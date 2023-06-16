//  RotaryMenuButton.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 09/06/2023
	Using Swift 5.0
	Running on macOS 13.4

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

final class RotaryMenuButton: BaseButton {

    enum IconLocation {
        case left
        case right
    }

    // MARK: - Subviews

    @View private var gradientView: TariGradientView = {
        let view = TariGradientView()
        view.layer.cornerRadius = 22.0
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()

    @View private(set) var iconView: UIImageView = {
        let view = UIImageView()
        view.tintColor = .static.white
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = false
        return view
    }()

    @View private var label: UILabel = {
        let view = UILabel()
        view.textColor = .static.white
        view.font = .Avenir.heavy.withSize(16.0)
        view.numberOfLines = 0
        return view
    }()

    // MARK: - Properties

    var icon: UIImage? {
        get { iconView.image }
        set { iconView.image = newValue }
    }

    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

    var iconLocation: IconLocation = .left {
        didSet { updateSubviewsConstraints() }
    }

    var maxWidth: CGFloat = 0.0 {
        didSet { widthConstraint.constant = maxWidth }
    }

    private var allConstraints: [NSLayoutConstraint] = []
    private lazy var widthConstraint = label.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)

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
        [gradientView, iconView, label].forEach(addSubview)
        updateSubviewsConstraints()
        widthConstraint.isActive = true
    }

    private func updateSubviewsConstraints() {

        NSLayoutConstraint.deactivate(allConstraints)

        switch iconLocation {
        case .left:
            allConstraints = makeConstraintsWithIconOnLeft()
        case .right:
            allConstraints = makeConstraintsWithIconOnRight()
        }

        NSLayoutConstraint.activate(allConstraints)
    }

    // MARK: - Factories

    func makeConstraintsWithIconOnLeft() -> [NSLayoutConstraint] {
        [
            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),
            gradientView.widthAnchor.constraint(equalToConstant: 44.0),
            gradientView.heightAnchor.constraint(equalToConstant: 44.0),
            iconView.topAnchor.constraint(equalTo: gradientView.topAnchor, constant: 5.0),
            iconView.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 5.0),
            iconView.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -5.0),
            iconView.bottomAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: -5.0),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: 10.0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
    }

    func makeConstraintsWithIconOnRight() -> [NSLayoutConstraint] {
        [
            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),
            gradientView.widthAnchor.constraint(equalToConstant: 44.0),
            gradientView.heightAnchor.constraint(equalToConstant: 44.0),
            iconView.topAnchor.constraint(equalTo: gradientView.topAnchor, constant: 5.0),
            iconView.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 5.0),
            iconView.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -5.0),
            iconView.bottomAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: -5.0),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: -10.0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0.0, bounds.height > 0.0 else { return }

        let xAnchorPoint = iconView.frame.midX / bounds.width
        let yAnchorPoint = iconView.frame.midY / bounds.height

        update(anchorPoint: CGPoint(x: xAnchorPoint, y: yAnchorPoint))
    }
}
