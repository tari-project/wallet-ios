//  TooltipView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 07/07/2021
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
import Combine

final class TooltipView: UIView {

    // MARK: - Subviews

    private let textLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textColor = .white
        view.font = Theme.shared.fonts.tooltip
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let tipView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let tipLayer = CAShapeLayer()

    // MARK: - Properties

    var tipXAnchor: NSLayoutXAxisAnchor { tipView.centerXAnchor }
    var tipYAnchor: NSLayoutYAxisAnchor { tipView.topAnchor }

    var text: String? {
        get { textLabel.text }
        set { textLabel.text = newValue }
    }

    var contentBackgroundColor: UIColor? = UIColor.init(white: 0.0, alpha: 0.5) {
        didSet { updateContentBackgroundColor() }
    }

    private var cancelables = Set<AnyCancellable>()

    // MARK: - Initializers

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")

    }

    // MARK: - Setups

    private func setup() {
        setupViews()
        setupConstraints()
        updateContentBackgroundColor()
    }

    private func setupViews() {
        isUserInteractionEnabled = false
        tipView.layer.insertSublayer(tipLayer, at: 0)
    }

    private func setupConstraints() {

        [tipView, contentView].forEach(addSubview)
        contentView.addSubview(textLabel)

        let tipCenterXConstraint = tipView.centerXAnchor.constraint(equalTo: centerXAnchor)
        tipCenterXConstraint.priority = .defaultHigh

        let constraints = [
            tipView.topAnchor.constraint(equalTo: topAnchor),
            tipCenterXConstraint,
            tipView.heightAnchor.constraint(equalToConstant: 12.0),
            tipView.widthAnchor.constraint(equalToConstant: 12.0),
            contentView.topAnchor.constraint(equalTo: tipView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            textLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12.0),
            textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12.0),
            textLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12.0),
            textLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    private func updateContentBackgroundColor() {
        tipLayer.fillColor = contentBackgroundColor?.cgColor
        contentView.backgroundColor = contentBackgroundColor
    }

    private func updateTipShape() {
        let tipPath = UIBezierPath()
        tipPath.move(to: CGPoint(x: tipView.bounds.midX, y: 0.0))
        tipPath.addLine(to: CGPoint(x: tipView.bounds.maxX, y: tipView.bounds.maxX))
        tipPath.addLine(to: CGPoint(x: 0.0, y: tipView.bounds.maxX))
        tipPath.close()

        tipLayer.path = tipPath.cgPath
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTipShape()
    }
}
