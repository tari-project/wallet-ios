//  RoundedGlassContentView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 28/06/2023
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

import TariCommon

final class RoundedGlassContentView<Subview: UIView>: UIView {

    // MARK: - Subviews

    @TariView private(set) var subview: Subview = Subview()

    // MARK: - Properties

    var borderWidth: CGFloat = 0.0 {
        didSet { subviewConstraints.forEach { $0.constant = borderWidth }}
    }

    private var subviewConstraints: [NSLayoutConstraint] = []

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupConstraints()

        layer.borderColor = UIColor.Static.white.withAlphaComponent(0.6).cgColor
        layer.borderWidth = 1.0
        backgroundColor = .Static.white.withAlphaComponent(0.4)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        addSubview(subview)

        subviewConstraints = [
            subview.topAnchor.constraint(equalTo: topAnchor),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: subview.trailingAnchor),
            bottomAnchor.constraint(equalTo: subview.bottomAnchor)
        ]

        NSLayoutConstraint.activate(subviewConstraints)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.height, bounds.width) / 2.0
    }
}
