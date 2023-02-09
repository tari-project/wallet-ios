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
    case warning
}

final class TextButton: DynamicThemeBaseButton {

    private static let imageHorizontalSpaceing: CGFloat = 2.0
    var spacing: CGFloat = imageHorizontalSpaceing

    private var variation: TextButtonVariation = .primary {
        didSet { updateTextColor(theme: theme) }
    }

    override init() {
        super.init()
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
        if let label = titleLabel {
            label.heightAnchor.constraint(equalToConstant: label.font.pointSize * 1.2).isActive = true
        }
        setVariation(variation)
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

    func setVariation(_ variation: TextButtonVariation, font: UIFont? = Theme.shared.fonts.textButton) {
        self.variation = variation
        titleLabel?.font = font
    }

    func setRightImage(_ image: UIImage?) {

        guard let image = image else { return }

        if let color = titleColor(for: .normal) {
            setImage(image.withTintColor(color, renderingMode: .alwaysOriginal), for: .normal)
        } else {
            setImage(image, for: .normal)
        }

        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)

        transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
    }

    private func updateTextColor(theme: ColorTheme) {
        switch variation {
        case .primary:
            setTitleColor(theme.text.body, for: .normal)
        case .secondary:
            setTitleColor(theme.text.links, for: .normal)
        case .warning:
            setTitleColor(theme.system.red, for: .normal)
        }
    }
}
