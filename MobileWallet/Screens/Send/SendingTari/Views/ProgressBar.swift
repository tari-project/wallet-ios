//  ProgressBar.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 09/02/2022
	Using Swift 5.0
	Running on macOS 12.1

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

final class ProgressBar: DynamicThemeView {

    enum State {
        case disabled
        case off
        case on
    }

    // MARK: - Subviews

    @View private var bar = UIView()

    // MARK: - Properties

    private(set) var state: State = .disabled

    private var barTrailingOffConstraint: NSLayoutConstraint?
    private var barTrailingOnConstraint: NSLayoutConstraint?

    // MARK: - Initalisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        update(state: .disabled, completion: nil)
    }

    private func setupConstraints() {

        addSubview(bar)

        let barTrailingOffConstraint = bar.trailingAnchor.constraint(equalTo: leadingAnchor)
        barTrailingOnConstraint = bar.trailingAnchor.constraint(equalTo: trailingAnchor)
        self.barTrailingOffConstraint = barTrailingOffConstraint

        let constraints = [
            bar.topAnchor.constraint(equalTo: topAnchor),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            barTrailingOffConstraint,
            bar.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        bar.backgroundColor = theme.brand.purple

        updateBackgroundColor(theme: theme)
    }

    private func updateBackgroundColor(theme: ColorTheme) {
        switch state {
        case .disabled:
            backgroundColor = theme.neutral.inactive
        case .off, .on:
            backgroundColor = theme.brand.purple?.withAlphaComponent(0.5)
        }
    }

    func update(state: State, completion: (() -> Void)?) {
        self.state = state
        bar.isHidden = state == .disabled
        updateBackgroundColor(theme: theme)
        animateBar(isOn: state == .on, completion: completion)
    }

    private func animateBar(isOn: Bool, completion: (() -> Void)?) {

        if isOn {
            barTrailingOffConstraint?.isActive = false
            barTrailingOnConstraint?.isActive = true
        } else {
            barTrailingOnConstraint?.isActive = false
            barTrailingOffConstraint?.isActive = true
        }

        UIView.animate(withDuration: 0.85, delay: 0.1, options: [], animations: {
            self.layoutIfNeeded()
        }, completion: { _ in
            completion?()
        })
    }

    // MARK: - Content Size

    override var intrinsicContentSize: CGSize { CGSize(width: 55.0, height: 4.0) }
}
