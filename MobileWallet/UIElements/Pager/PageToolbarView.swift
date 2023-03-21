//  PageToolbarView.swift

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

final class PageToolbarView: DynamicThemeView {

    // MARK: - Subviews

    @View private var selectorLineView = UIView()

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .fillEqually
        view.alignment = .fill
        return view
    }()

    // MARK: - Properties

    var indexPosition: CGFloat = 0.0 {
        didSet { update(indexPosition: indexPosition) }
    }

    var onTap: ((_ index: Int) -> Void)?

    private var selectorLineWidthConstraint: NSLayoutConstraint?
    private var selectorLineCenterXConstraint: NSLayoutConstraint?
    private var selectorLineConstraints: [NSLayoutConstraint] { [selectorLineWidthConstraint, selectorLineCenterXConstraint].compactMap { $0 } }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [stackView, selectorLineView].forEach(addSubview)

        let constraints = [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            selectorLineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            selectorLineView.heightAnchor.constraint(equalToConstant: 3.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    func update(tabs: [String]) {
        tabs
            .enumerated()
            .map { tab in
                let button = BaseButton()
                button.setTitle(tab.element, for: .normal)
                button.titleLabel?.font = .Avenir.medium.withSize(16.0)
                button.onTap = { [weak self] in self?.onTap?(tab.offset) }
                return button
            }
            .forEach(stackView.addArrangedSubview)

        updateButtons(theme: theme)

        NSLayoutConstraint.deactivate(selectorLineConstraints)
        guard let firstButton = stackView.arrangedSubviews.first else { return }

        selectorLineWidthConstraint = selectorLineView.widthAnchor.constraint(equalTo: firstButton.widthAnchor, constant: -24.0)
        selectorLineCenterXConstraint = selectorLineView.centerXAnchor.constraint(equalTo: firstButton.centerXAnchor)

        NSLayoutConstraint.activate(selectorLineConstraints)
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        selectorLineView.backgroundColor = theme.brand.purple
        updateButtons(theme: theme)
    }

    private func updateButtons(theme: ColorTheme) {
        stackView.arrangedSubviews
            .compactMap { $0 as? BaseButton }
            .forEach { $0.setTitleColor(theme.text.heading, for: .normal) }
    }

    private func update(indexPosition: CGFloat) {
        guard let firstButton = stackView.arrangedSubviews.first else { return }
        selectorLineCenterXConstraint?.constant = indexPosition * firstButton.bounds.width
    }
}
