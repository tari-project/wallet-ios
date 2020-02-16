//  TextButton.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/28
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

enum TextButtonVariation {
    case primary
    case secondary
}

class TextButton: UIButton {
    private static let imageHorizontalSpaceing: CGFloat = 1

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    convenience init() {
        self.init(frame: CGRect.zero)
        commonSetup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let image = image(for: .normal) {
            setRightImage(image)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }

    private func commonSetup() {
        setTitleColor(Theme.shared.colors.textButton, for: .normal)
        titleLabel?.font = Theme.shared.fonts.textButton

        if let label = titleLabel {
            label.heightAnchor.constraint(equalToConstant: label.font.pointSize * 1.2).isActive = true
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
            self.alpha = 0.6
            if let imageView = self.imageView {
                imageView.alpha = 0.6
            }
        })
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
            self.alpha = 1
            if let imageView = self.imageView {
                imageView.alpha = 1
            }
        })
    }

    func setVariation(_ variation: TextButtonVariation) {
        switch variation {
        case .secondary:
            setTitleColor(Theme.shared.colors.textButtonSecondary, for: .normal)
            break
        default:
            break
        }
    }

    func setRightImage(_ image: UIImage) {
        if let color = titleColor(for: .normal) {
            setImage(image.withTintColor(color), for: .normal)
        } else {
            setImage(image, for: .normal)
        }
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: TextButton.imageHorizontalSpaceing)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: TextButton.imageHorizontalSpaceing, bottom: 0, right: 0)

        transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    }
}
