//  PasteEmojisView.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/02/17
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

class PasteEmojisView: UIView {
    private let textButton = TextButton()
    private let emojiLabel = UILabel()
    private let PADDING: CGFloat = 14
    private var onPressCallback: (() -> Void)?

    override func draw(_ rect: CGRect) {
        backgroundColor = Theme.shared.colors.appBackground

        textButton.setVariation(.secondary)
        textButton.translatesAutoresizingMaskIntoConstraints = false
        textButton.isUserInteractionEnabled = false
        addSubview(textButton)
        textButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        textButton.topAnchor.constraint(equalTo: topAnchor, constant: PADDING).isActive = true

        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emojiLabel)
        emojiLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: PADDING).isActive = true
        emojiLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -PADDING).isActive = true
        emojiLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -PADDING).isActive = true
        emojiLabel.textAlignment = .center
        emojiLabel.textColor = Theme.shared.colors.emojisSeparatorExpanded
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (onTap(_:))))
    }

    func setEmojis(emojis: String, onPress: @escaping () -> Void) {
        textButton.setTitle(NSLocalizedString("Paste copied Emoji ID", comment: ""), for: .normal)
        let first = "\(emojis.prefix(6))".insertSeparator(" | ", atEvery: 3)
        let last = "\(emojis.suffix(6))".insertSeparator(" | ", atEvery: 3)
        emojiLabel.text = "\(first)...\(last)"

        self.onPressCallback = onPress
        textButton.addTarget(self, action: #selector(onTap), for: .allTouchEvents)
    }

    @objc func onTap(_ sender: Any?) {
        if let callBack = onPressCallback {
            callBack()
        }
    }
}
