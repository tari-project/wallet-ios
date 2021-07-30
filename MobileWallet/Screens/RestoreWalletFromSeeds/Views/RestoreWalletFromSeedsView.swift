//  RestoreWalletFromSeedsView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 12/07/2021
	Using Swift 5.0
	Running on macOS 12.0

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
import Combine

final class RestoreWalletFromSeedsView: KeyboardAvoidingContentView {

    // MARK: - Subviews

    private let descriptionLabel: UILabel = {
        let view = UILabel()
        view.textColor = Theme.shared.colors.restoreFromSeedWordsTextColor
        view.font = Theme.shared.fonts.restoreFormSeedWordsDescription
        view.text = localized("restore_from_seed_words.label.description")
        view.numberOfLines = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let tokenView: TokenCollectionView = {
        let view = TokenCollectionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let submitButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("restore_from_seed_words.button.submit"), for: .normal)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties

    var tokens: AnyPublisher<[String], Never> { tokenView.tokens }
    var onTapOnSubmitButton: (() -> Void)?

    // MARK: - Initializers

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        setupFeedbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    func prepareView() {
        tokenView.prepareView()
    }

    private func setupViews() {
        backgroundColor = Theme.shared.colors.appBackground
    }

    private func setupConstraints() {

        [descriptionLabel, tokenView, submitButton].forEach(contentView.addSubview)

        let constraints = [
            descriptionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20.0),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25.0),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25.0),
            tokenView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20.0),
            tokenView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25.0),
            tokenView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25.0),
            tokenView.heightAnchor.constraint(equalToConstant: 200.0),
            submitButton.topAnchor.constraint(greaterThanOrEqualTo: tokenView.bottomAnchor, constant: 20.0),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25.0),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25.0),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -28.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupFeedbacks() {
        submitButton.addTarget(self, action: #selector(onTapOnSubmitButtonAction), for: .touchUpInside)
    }

    // MARK: - Actions

    func update(buttonIsEnabledStatus: Bool) {
        submitButton.variation = buttonIsEnabledStatus ? .normal : .disabled
    }

    // MARK: - Action Targets

    @objc private func onTapOnSubmitButtonAction() {
        onTapOnSubmitButton?()
    }
}
