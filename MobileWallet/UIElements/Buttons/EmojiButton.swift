//  EmojiButton.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/25
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

class EmojiButton: UIButton {
    private let RADIUS_POINTS: CGFloat = 12.0
    private let HEIGHT: CGFloat = 32.0
    private let WIDTH: CGFloat = 152
    private var isCompiled = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isCompiled = true
        commonSetup()
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()

        if isCompiled {
            removeStyle()
            setShadow()
        }
   }

    private func removeStyle() {
        layer.shadowOpacity = 0.0
    }
    private func commonSetup() {
        bounds = CGRect(x: bounds.maxX, y: bounds.maxY, width: bounds.width, height: HEIGHT)
        layer.cornerRadius = RADIUS_POINTS
        heightAnchor.constraint(equalToConstant: HEIGHT).isActive = true
        widthAnchor.constraint(equalToConstant: WIDTH).isActive = true
        backgroundColor = Theme.shared.colors.emojiButtonBackground

        setTitleColor(Theme.shared.colors.emojiButtonClip, for: .normal)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)

        setShadow()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        pulseIn()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        pulseOut()
    }

    private func pulseIn() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
            self.alpha = 0.94
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        })
    }

    private func pulseOut() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
            self.alpha = 1
            self.transform = CGAffineTransform(scaleX: 1, y: 1)
        })
    }

    private func setShadow() {
        layer.shadowColor = Theme.shared.colors.emojiButtonShadow!.cgColor
        layer.shadowOffset = .zero //CGSize(width: 12.0, height: 12.0)
        layer.shadowRadius = RADIUS_POINTS * 1.2
        layer.shadowOpacity = 0.1
        clipsToBounds = true
        layer.masksToBounds = false
    }

    func setEmojis(_ emojis: String) {
        setTitle(emojis, for: .normal)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 6.5, bottom: 0, right: 6.5)

//        let attributedString = NSMutableAttributedString(string: emojis)
//        var currentPosition = 0
//        for char in emojis {
//
//            let charLength = char.utf16.count
//
//            attributedString.addAttribute(
//                NSAttributedString.Key.foregroundColor,
//                value: Theme.shared.colors.emojiButtonShadow!.withAlphaComponent(0.1),
//                range: NSRange(location: currentPosition, length: charLength)
//            )
//            currentPosition += charLength
//        }
//        setAttributedTitle(attributedString, for: .normal)
    }
}
