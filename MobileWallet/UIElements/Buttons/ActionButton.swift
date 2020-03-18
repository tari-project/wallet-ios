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

enum ActionButtonVariation {
    case normal
    case raised //Like normal but with a shadow
    case loading
    case disabled
}

class ActionButton: UIButton {
    static let GRADIENT_LAYER_NAME = "GradientLayer"
    static let RADIUS_POINTS: CGFloat = 4.0
    static let HEIGHT: CGFloat = 53.0
    static let GRADIENT_ANGLE: Double = 90
    //private var isCompiled = false

    var variation: ActionButtonVariation = .normal {
        didSet {
            updateStyle()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }

    private func commonSetup() {
        setTitleColor(Theme.shared.colors.actionButtonTitle, for: .normal)
        setTitleColor(Theme.shared.colors.actionButtonTitleDisabled, for: .disabled)
        bounds = CGRect(x: bounds.maxX, y: bounds.maxY, width: bounds.width, height: ActionButton.HEIGHT)
        layer.cornerRadius = ActionButton.RADIUS_POINTS
        heightAnchor.constraint(equalToConstant: ActionButton.HEIGHT).isActive = true
        backgroundColor = Theme.shared.colors.actionButtonBackgroundSimple
        titleLabel?.font = Theme.shared.fonts.actionButton
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateStyle()
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
    }

     private func removeStyle() {
        ActionButton.removeGradient(self)
        backgroundColor = Theme.shared.colors.actionButtonBackgroundSimple
    }

    //Static function so that SlideView can implement same affect
    static func removeGradient(_ view: UIView) {
        if let sublayers = view.layer.sublayers {
            for layer in sublayers {
                if layer.name == ActionButton.GRADIENT_LAYER_NAME {
                     layer.removeFromSuperlayer()
                }
            }
        }
    }

    //Static function so that SlideView can implement same affect
    static func applyGradient(_ view: UIView) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            Theme.shared.colors.gradient1!.cgColor,
            Theme.shared.colors.gradient2!.cgColor
        ]
        gradient.locations = [-0.8, 3]
        gradient.cornerRadius = ActionButton.RADIUS_POINTS
        gradient.name = ActionButton.GRADIENT_LAYER_NAME

        let x: Double! = GRADIENT_ANGLE / 360.0
        let a = pow(sinf(Float(2 * Double.pi * ((x + 0.75) / 2.0))), 2.0)
        let b = pow(sinf(Float(2 * Double.pi * ((x + 0.0) / 2))), 2)
        let c = pow(sinf(Float(2 * Double.pi * ((x + 0.25) / 2))), 2)
        let d = pow(sinf(Float(2 * Double.pi * ((x + 0.5) / 2))), 2)

        gradient.endPoint = CGPoint(x: CGFloat(c), y: CGFloat(d))
        gradient.startPoint = CGPoint(x: CGFloat(a), y: CGFloat(b))

        view.layer.insertSublayer(gradient, at: 0)
    }

    private func applyShadow() {
        layer.shadowColor = Theme.shared.colors.actionButtonShadow!.cgColor
        layer.shadowOffset = CGSize(width: 10.0, height: 10.0)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.5
        clipsToBounds = true
        layer.masksToBounds = false
    }

    private func updateStyle() {
        removeStyle()
        switch variation {
            case .normal:
                isEnabled = true
                ActionButton.applyGradient(self)
                return
            case .raised:
                isEnabled = true
                applyShadow()
                ActionButton.applyGradient(self)
                return
            case .loading:
                isEnabled = false
                ActionButton.applyGradient(self)
                //TODO spinner
                return
            case .disabled:
                isEnabled = false
                backgroundColor = Theme.shared.colors.actionButtonBackgroundDisabled
                return
        }
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
        //Wait till after pulse affect
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

    func hideButtonWithAlpha() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            UIView.animate(withDuration: 0.5) {
                self.alpha = 0.0
                self.layoutIfNeeded()
            }
        })
    }
}
