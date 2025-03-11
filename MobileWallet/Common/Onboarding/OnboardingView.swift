//  OnboardingView.swift

/*
	Package MobileWallet
	Created by Browncoat on 25/01/2023
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

final class OnboardingView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private(set) var contentView = UIView()

    @View private(set) var pagerView: OnboardingPagerView = {
        let view = OnboardingPagerView(elementsCount: 4)
        view.isUserInteractionEnabled = false
        return view
    }()

    // MARK: - Properties

    var progress: Double {
        get { pagerView.progress }
        set { pagerView.progress = newValue }
    }

    var onNextButtonPress: (() -> Void)?

    // MARK: - Initialisers

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
        navigationBar.backButtonType = .close
        navigationBar.update(rightButton: NavigationBar.ButtonModel(title: localized("common.next"), callback: { [weak self] in self?.onNextButtonPress?() }))
    }

    private func setupConstraints() {

        [contentView, pagerView].forEach(addSubview)

        let constraints = [
            contentView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            pagerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pagerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Theme

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
    }
}
