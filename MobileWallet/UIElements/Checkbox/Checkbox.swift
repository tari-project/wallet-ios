//  Checkbox.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 04.06.2020
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

class CheckBox: UIButton {
    private let borderLayer = CALayer()

    private let animationView = AnimationView()
    private let selectAnimation = Animation.named(.checkboxSelectAnimation)
    private let deselectAnimation = Animation.named(.checkboxDeselectAnimation)

    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                animationView.animation = selectAnimation
            } else {
                animationView.animation = deselectAnimation
            }
            animationView.play()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(self.buttonClicked), for: .touchUpInside)
        setupAnimationView()
        clipsToBounds = false
    }

    override func draw(_ rect: CGRect) {
        borderLayer.frame = rect
        borderLayer.cornerRadius = 0.1 * rect.height
        borderLayer.masksToBounds = true

        borderLayer.borderWidth = 2
        borderLayer.borderColor = Theme.shared.colors.checkBoxBorderColor?.cgColor
        layer.insertSublayer(borderLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func buttonClicked() {
        isChecked = !isChecked
    }

    private func viewSetup() {

    }

    private func setupAnimationView() {
        addSubview(animationView)
        animationView.isUserInteractionEnabled = false
        animationView.animationSpeed = 2

        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 2.72).isActive = true
        animationView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 2.72).isActive = true
        animationView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        animationView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}
