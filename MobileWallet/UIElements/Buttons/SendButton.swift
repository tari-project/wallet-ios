//  SendButton.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/12/02
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

class SendButton: ActionButton {
    private let GRADIENT_LAYER_NAME = "GradientLayer"
    private var isCompiled = false
    private let GRADIENT_ANGLE: Double = 90.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGradient()
    }

    override var isEnabled: Bool {
        didSet {
            if isEnabled != oldValue {
                applyStyle()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isCompiled = true
        applyGradient()
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()

        if isCompiled {
            applyStyle()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        applyStyle()
    }

    private func removeGradient() {
       if let sublayers = layer.sublayers {
           for layer in sublayers {
               if layer.name == GRADIENT_LAYER_NAME {
                    layer.removeFromSuperlayer()
               }
           }
       }
   }

    private func applyStyle() {
        if isEnabled {
            applyGradient()
        } else {
            applyDisabledStyle()
        }
    }

   private func applyGradient() {
       removeGradient()
       let gradient: CAGradientLayer = CAGradientLayer()
       gradient.frame = bounds
       gradient.colors = [
           Theme.shared.colors.actionButtonBackgroundGradient1!.cgColor,
           Theme.shared.colors.actionButtonBackgroundGradient2!.cgColor
       ]
       gradient.locations = [-0.8, 3]
       gradient.cornerRadius = RADIUS_POINTS
       gradient.name = GRADIENT_LAYER_NAME

       let x: Double! = GRADIENT_ANGLE / 360.0
       let a = pow(sinf(Float(2 * Double.pi * ((x + 0.75) / 2.0))), 2.0)
       let b = pow(sinf(Float(2 * Double.pi * ((x + 0.0) / 2))), 2)
       let c = pow(sinf(Float(2 * Double.pi * ((x + 0.25) / 2))), 2)
       let d = pow(sinf(Float(2 * Double.pi * ((x + 0.5) / 2))), 2)

       gradient.endPoint = CGPoint(x: CGFloat(c), y: CGFloat(d))
       gradient.startPoint = CGPoint(x: CGFloat(a), y: CGFloat(b))

       layer.insertSublayer(gradient, at: 0)
   }

   func applyShadow() {
       layer.shadowColor = Theme.shared.colors.actionButtonShadow!.cgColor
       layer.shadowOffset = CGSize(width: 10.0, height: 10.0)
       layer.shadowRadius = 10
       layer.shadowOpacity = 0.5
       clipsToBounds = true
       layer.masksToBounds = false
   }

    private func applyDisabledStyle() {
        removeGradient()

        let disabledLayer: CALayer = CALayer()
        disabledLayer.frame = bounds
        disabledLayer.backgroundColor = Theme.shared.colors.actionButtonDisabled!.cgColor
        disabledLayer.name = GRADIENT_LAYER_NAME
        disabledLayer.cornerRadius = RADIUS_POINTS
        layer.insertSublayer(disabledLayer, at: 0)
    }
}
