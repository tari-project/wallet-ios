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

import TariCommon

final class RestoreWalletFromSeedsView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var mainContentView = KeyboardAvoidingContentView()

    @View private var descriptionLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.restoreFormSeedWordsDescription
        view.text = localized("restore_from_seed_words.label.description")
        view.numberOfLines = 0
        return view
    }()

    @View var tokenView = TokenCollectionView()

    @View private(set) var selectBaseNodeButton: TextButton = {
        let view = TextButton()
        view.style = .secondary
        view.isHidden = !TariSettings.showDisabledFeatures
        return view
    }()

    @View private(set) var submitButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("restore_from_seed_words.button.submit"), for: .normal)
        return view
    }()

    // MARK: - Properties

    var isCustomBaseNodeSet: Bool = false {
        didSet {
            let title = isCustomBaseNodeSet ? localized("restore_from_seed_words.button.select_base_node.edit") : localized("restore_from_seed_words.button.select_base_node.select")
            selectBaseNodeButton.setTitle(title, for: .normal)
        }
    }

    // MARK: - Initializers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        navigationBar.title = localized("restore_from_seed_words.title")
    }

    private func setupConstraints() {

        addSubview(mainContentView)
        [descriptionLabel, tokenView, selectBaseNodeButton, submitButton].forEach(mainContentView.contentView.addSubview)

        let constraints = [
            mainContentView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            mainContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: mainContentView.contentView.topAnchor, constant: 20.0),
            descriptionLabel.leadingAnchor.constraint(equalTo: mainContentView.contentView.leadingAnchor, constant: 25.0),
            descriptionLabel.trailingAnchor.constraint(equalTo: mainContentView.contentView.trailingAnchor, constant: -25.0),
            tokenView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20.0),
            tokenView.leadingAnchor.constraint(equalTo: mainContentView.contentView.leadingAnchor, constant: 25.0),
            tokenView.trailingAnchor.constraint(equalTo: mainContentView.contentView.trailingAnchor, constant: -25.0),
            tokenView.heightAnchor.constraint(equalToConstant: 272.0),
            selectBaseNodeButton.topAnchor.constraint(greaterThanOrEqualTo: tokenView.bottomAnchor, constant: 20.0),
            selectBaseNodeButton.leadingAnchor.constraint(equalTo: mainContentView.contentView.leadingAnchor, constant: 25.0),
            selectBaseNodeButton.trailingAnchor.constraint(equalTo: mainContentView.contentView.trailingAnchor, constant: -25.0),
            submitButton.topAnchor.constraint(equalTo: selectBaseNodeButton.bottomAnchor, constant: 20.0),
            submitButton.leadingAnchor.constraint(equalTo: mainContentView.contentView.leadingAnchor, constant: 25.0),
            submitButton.trailingAnchor.constraint(equalTo: mainContentView.contentView.trailingAnchor, constant: -25.0),
            submitButton.bottomAnchor.constraint(equalTo: mainContentView.contentView.bottomAnchor, constant: -28.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        descriptionLabel.textColor = theme.text.body
    }

    func update(buttonIsEnabledStatus: Bool) {
        submitButton.isEnabled = buttonIsEnabledStatus
    }

    // MARK: - First Responder

    override func resignFirstResponder() -> Bool { tokenView.resignFirstResponder() }
}
