//  TransactionDetailsEmojiView.swift

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

final class TransactionDetailsEmojiView: UIView {

    // MARK: - Subviews

    @View private var emojiIdView = EmojiIdView()

    @View private(set) var addContactButton: TextButton = {
        let view = TextButton()
        view.setTitle(localized("tx_detail.add_contact_name"), for: .normal)
        view.setVariation(.secondary)
        return view
    }()

    // MARK: - Properties

    var emojiIdViewModel: EmojiIdView.ViewModel? {
        didSet { updateEmojiIdView() }
    }

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [emojiIdView, addContactButton].forEach(addSubview)

        let constraints = [
            heightAnchor.constraint(equalToConstant: 85.0),
            emojiIdView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            emojiIdView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            emojiIdView.centerYAnchor.constraint(equalTo: centerYAnchor),
            addContactButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            addContactButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions

    private func updateEmojiIdView() {
        guard let emojiIdViewModel = emojiIdViewModel else { return }
        emojiIdView.update(viewModel: emojiIdViewModel, textCentered: false)
    }
}
