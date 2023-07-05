//  StylizedLabel.swift

/*
	Package MobileWallet
	Created by Browncoat on 27/01/2023
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

final class StylizedLabel: UILabel {

    enum Style {
        case normal
        case bold
        case highlighted
    }

    struct StylizedText {
        let text: String
        let style: Style
    }

    // MARK: - Properties

    override var text: String? {
        didSet { textComponents = [] }
    }

    var normalFont: UIFont? {
        didSet { updateText() }
    }

    var boldFont: UIFont? {
        didSet { updateText() }
    }

    var separator: String = "" {
        didSet { updateText() }
    }

    override var textColor: UIColor? {
        didSet { updateText() }
    }

    override var highlightedTextColor: UIColor? {
        didSet { updateText() }
    }

    var textComponents: [StylizedText] = [] {
        didSet { updateText() }
    }

    // MARK: - Updates

    private func updateText() {

        guard !textComponents.isEmpty else { return }

        attributedText = textComponents
            .enumerated()
            .reduce(into: NSMutableAttributedString()) { result, data in

                var font: UIFont?
                var textColor: UIColor?

                switch data.element.style {
                case .normal:
                    font = normalFont
                    textColor = self.textColor
                case .bold:
                    font = boldFont
                    textColor = self.textColor
                case .highlighted:
                    font = normalFont
                    textColor = highlightedTextColor
                }

                if data.offset != 0 {
                    result.append(NSAttributedString(string: separator))
                }

                let location = result.length
                result.append(NSAttributedString(string: data.element.text))

                if let font {
                    result.addAttribute(.font, value: font, range: NSRange(location: location, length: data.element.text.utf16.count))
                }
                if let textColor {
                    result.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: location, length: data.element.text.utf16.count))
                }
            }
    }
}
