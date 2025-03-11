//  LoadingGIFButton.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 03.08.2020
	Using Swift 5.0
	Running on macOS 10.15

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
import Lottie

enum LoadinGIFButtonVariation {
    case retry
    case loading
}

class LoadingGIFButton: DynamicThemeBaseButton {
    static let HEIGHT: CGFloat = 20.0
    private let pendingAnimationView = AnimationView()

    var variation: LoadinGIFButtonVariation = .retry {
        didSet {
            updateStyle()
        }
    }

    override init() {
        super.init()
        commonSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }

    private func commonSetup() {
        let loadingTitile = localized("loading_gif_button.title.loading")
        let retryTitle = localized("loading_gif_button.title.retry")
        setTitle(loadingTitile, for: .disabled)
        setTitle(retryTitle, for: .normal)
        bounds = CGRect(x: bounds.maxX, y: bounds.maxY, width: bounds.width, height: 53.0)
        heightAnchor.constraint(equalToConstant: LoadingGIFButton.HEIGHT).isActive = true
        backgroundColor = .clear
        contentHorizontalAlignment = .left
        titleLabel?.font = Theme.shared.fonts.loadingGifButtonTitle
        isEnabled = false
    }

    private func updateStyle() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch self.variation {
            case .retry:
                self.pendingAnimationView.removeFromSuperview()
                self.isEnabled = true
            case .loading:
                self.isEnabled = false
                self.setupPendingAnimation()
            }
        }
    }

    private func setupPendingAnimation() {
        pendingAnimationView.backgroundBehavior = .pauseAndRestore
        pendingAnimationView.animation = Animation.named(.pendingCircleAnimation)

        addSubview(pendingAnimationView)
        pendingAnimationView.translatesAutoresizingMaskIntoConstraints = false
        pendingAnimationView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        pendingAnimationView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        pendingAnimationView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        pendingAnimationView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        pendingAnimationView.play(fromProgress: 0, toProgress: 1, loopMode: .loop)
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        setTitleColor(theme.text.links, for: .normal)
        setTitleColor(theme.buttons.disabledText, for: .disabled)
    }
}
