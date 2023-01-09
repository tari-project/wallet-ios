//  ActionButton.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/10/31
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

enum ActionButtonVariation {
    case normal
    case destructive
    case loading
    case disabled
}

final class ActionButton: DynamicThemeBaseButton {
    static let RADIUS_POINTS: CGFloat = 4.0
    static let HEIGHT: CGFloat = 53.0

    private let gradientLayer = CAGradientLayer()
    private let pendingAnimationView = AnimationView()

    var variation: ActionButtonVariation = .normal {
        didSet { updateStyle(theme: theme) }
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
        bounds = CGRect(x: bounds.maxX, y: bounds.maxY, width: bounds.width, height: ActionButton.HEIGHT)
        layer.cornerRadius = ActionButton.RADIUS_POINTS
        heightAnchor.constraint(equalToConstant: ActionButton.HEIGHT).isActive = true
        titleLabel?.font = Theme.shared.fonts.actionButton
        titleLabel?.adjustsFontSizeToFitWidth = true
        contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)

        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.locations = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
    }

    override func setImage(_ image: UIImage?, for state: UIControl.State) {
        if let color = titleColor(for: .normal), let newImage = image {
            super.setImage(newImage.withTintColor(color), for: state)
        } else {
            super.setImage(image, for: state)
        }

        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 7)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        updateStyle(theme: theme)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: { [weak self] in
            guard let self = self else { return }
            self.alpha = 0.94
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        })
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: { [weak self] in
            guard let self = self else { return }
            self.alpha = 1
            self.transform = CGAffineTransform(scaleX: 1, y: 1)
        })

        isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isUserInteractionEnabled = true
        }
    }

    private func removeStyle() {
        gradientLayer.removeFromSuperlayer()
        pendingAnimationView.removeFromSuperview()
        titleLabel?.isHidden = false
    }

    private func updateStyle(theme: ColorTheme) {
        removeStyle()

        switch variation {
        case .normal:
            isEnabled = true
            layer.insertSublayer(gradientLayer, at: 0)
            imageView?.tintColor = theme.buttons.primaryText
        case .destructive:
            isEnabled = true
            backgroundColor = theme.system.red
            imageView?.tintColor = theme.buttons.primaryText
        case .loading:
            isEnabled = false
            layer.insertSublayer(gradientLayer, at: 0)
            titleLabel?.isHidden = true
            imageView?.tintColor = .clear
            setupPendingAnimation()
        case .disabled:
            isEnabled = false
            backgroundColor = theme.buttons.disabled
            imageView?.tintColor = theme.buttons.disabledText
        }

        gradientLayer.colors = [theme.buttons.primaryStart, theme.buttons.primaryEnd].compactMap { $0?.cgColor }
    }

    func animateIn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [weak self] in
            guard let self = self else { return }
            self.isHidden = false
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: .curveEaseOut,
                animations: { [weak self] in
                    guard let self = self else { return }
                    self.transform = CGAffineTransform(scaleX: 1, y: 1)
                }
            )
        })
    }

    func animateOut() {
        // Wait till after pulse affect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: .curveEaseOut,
                animations: { [weak self] in
                    guard let self = self else { return }
                    self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                }, completion: { [weak self] (_) in
                    guard let self = self else { return }
                    self.isHidden = true
            })
        })
    }

    func hideButtonWithAlpha(comletion: (() -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            UIView.animate(withDuration: 0.5, animations: { [weak self] in
                self?.alpha = 0.0
                self?.layoutIfNeeded()
            }) { _ in
                comletion?()
            }
        })
    }

    private func setupPendingAnimation() {
        pendingAnimationView.backgroundBehavior = .pauseAndRestore
        pendingAnimationView.animation = Animation.named(.pendingCircleAnimation)

        addSubview(pendingAnimationView)
        pendingAnimationView.translatesAutoresizingMaskIntoConstraints = false
        pendingAnimationView.widthAnchor.constraint(equalToConstant: 45).isActive = true
        pendingAnimationView.heightAnchor.constraint(equalToConstant: 45).isActive = true
        pendingAnimationView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        pendingAnimationView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        pendingAnimationView.play(fromProgress: 0, toProgress: 1, loopMode: .loop)
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        setTitleColor(theme.buttons.primaryText, for: .normal)
        setTitleColor(theme.buttons.disabledText, for: .disabled)
        updateStyle(theme: theme)
    }
}
