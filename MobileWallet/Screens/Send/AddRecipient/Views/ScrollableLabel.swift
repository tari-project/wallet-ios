//  ScrollableLabel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 25/10/2021
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
import TariCommon

final class ScrollableLabel: UIView {

    // MARK: - Constants

    private let margin = 12.0

    // MARK: - Subviews

    @View var label: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.searchContactsInputBoxText
        return view
    }()

    @View var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    private let maskLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        layer.startPoint = CGPoint(x: 0.0, y: 0.5)
        layer.endPoint = CGPoint(x: 1.0, y: 0.5)
        return layer
    }()

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        backgroundColor = .white
        layer.mask = maskLayer
    }

    private func setupConstraints() {

        scrollView.addSubview(label)
        addSubview(scrollView)

        let constraints = [
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            label.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: margin),
            label.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -margin),
            label.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            label.heightAnchor.constraint(equalTo: heightAnchor),
            heightAnchor.constraint(equalToConstant: 46.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        maskLayer.frame = bounds
        let startPoint = margin / bounds.width
        let endPoint = 1.0 - startPoint
        maskLayer.locations = [0.0, NSNumber(value: startPoint), NSNumber(value: endPoint), 1.0]
    }
}
