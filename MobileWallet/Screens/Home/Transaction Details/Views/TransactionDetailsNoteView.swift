//  TransactionDetailsNoteView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 16/03/2022
	Using Swift 5.0
	Running on macOS 12.3

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
import TariCommon
import GiphyUISDK

final class TransactionDetailsNoteView: DynamicThemeView {

    // MARK: - Subviews

    @View private var noteLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.txScreenTextLabel
        view.numberOfLines = 0
        return view
    }()

    @View private var gifView: GPHMediaView = {
        let view = GPHMediaView()
        view.layer.cornerRadius = 20.0
        view.clipsToBounds = true
        return view
    }()

    // MARK: - Properties

    var note: String? {
        get { noteLabel.text }
        set { noteLabel.text = newValue }
    }

    var gifMedia: GPHMedia? {
        didSet { updateGifView() }
    }

    private var gifViewHeightConstraints: NSLayoutConstraint?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [noteLabel, gifView].forEach(addSubview)

        let constraints = [
            noteLabel.topAnchor.constraint(equalTo: topAnchor, constant: 11.0),
            noteLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            noteLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            gifView.topAnchor.constraint(equalTo: noteLabel.bottomAnchor, constant: 11.0),
            gifView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            gifView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            gifView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -11.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        noteLabel.textColor = theme.text.heading
    }

    private func updateGifView() {

        gifView.media = gifMedia
        gifViewHeightConstraints?.isActive = false

        if let media = gifMedia {
            gifViewHeightConstraints = gifView.heightAnchor.constraint(equalTo: gifView.widthAnchor, multiplier: 1.0 / media.aspectRatio)
        } else {
            gifViewHeightConstraints = gifView.heightAnchor.constraint(equalToConstant: 0.0)
        }

        gifViewHeightConstraints?.isActive = true
    }
}
