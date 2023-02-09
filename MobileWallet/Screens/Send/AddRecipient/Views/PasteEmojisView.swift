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

class PasteEmojisView: DynamicThemeView {
    private let textButton = TextButton()
    private let scrollView = UIScrollView()
    private let emojiLabel = UILabelWithPadding()
    private var onPressCallback: (() -> Void)?

    override init() {
        super.init()

        textButton.setVariation(.secondary)
        textButton.translatesAutoresizingMaskIntoConstraints = false
        textButton.isUserInteractionEnabled = false
        addSubview(textButton)
        textButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        textButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4).isActive = true
        scrollView.heightAnchor.constraint(equalToConstant: CGFloat(30)).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setEmojis(emojis: String, onPress: @escaping () -> Void) {
        textButton.setTitle(localized("emoji.paste"), for: .normal)
        self.onPressCallback = onPress
        textButton.addTarget(self, action: #selector(onTap), for: .allTouchEvents)

        let padding = CGFloat(14)
        emojiLabel.padding = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
        emojiLabel.text = emojis.insertSeparator(" | ", atEvery: 3) + " "
        emojiLabel.textAlignment = .center
        emojiLabel.letterSpacing(value: 1.6)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.sizeToFit()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (onTap(_:))))
        emojiLabel.frame = CGRect(
            x: 0,
            y: 0,
            width: emojiLabel.frame.size.width,
            height: emojiLabel.frame.size.height
        )
        scrollView.addSubview(emojiLabel)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSize = CGSize(
            width: emojiLabel.frame.size.width + padding * 2,
            height: CGFloat(30)
        )
    }

    @objc func onTap(_ sender: Any?) {
        if let callBack = onPressCallback {
            callBack()
        }
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        apply(shadow: theme.shadows.box)
        emojiLabel.textColor = theme.neutral.secondary
    }
}
