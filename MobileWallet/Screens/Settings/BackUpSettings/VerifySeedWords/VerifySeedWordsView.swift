//  VerifySeedWordsView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 23/02/2022
	Using Swift 5.0
	Running on macOS 12.1

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

final class VerifySeedWordsView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var scrollView = ContentScrollView()

    @View private var headerLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.settingsSeedPhraseDescription
        view.text = localized("verify_phrase.header")
        return view
    }()

    @View private(set) var tokensView = TokenCollectionView()

    @View private var errorLabel: UILabel = {
        let view = UILabel()
        view.text = localized("verify_phrase.warning")
        view.font = .Poppins.Bold.withSize(14.0)
        view.textAlignment = .center
        view.layer.cornerRadius = 4.0
        view.layer.borderWidth = 1.0
        view.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
        return view
    }()

    @View private var successImageView: UIImageView = {
        let view = UIImageView()
        view.image =  Theme.shared.images.successIcon
        view.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
        return view
    }()

    @View private(set) var tokensViewInfoLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.text = localized("verify_phrase.container_description")
        view.font = Theme.shared.fonts.settingsFillablePhraseViewDescription
        view.textAlignment = .center
        return view
    }()

    @View private(set) var selectableTokensView = TokenCollectionView()

    @View private(set) var continueButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("verify_phrase.complete"), for: .normal)
        return view
    }()

    // MARK: - Properties

    var isInfoLabelVisible: Bool = true {
        didSet { updateInfoLabel() }
    }

    var isErrorVisible: Bool = false {
        didSet { updateScale(view: errorLabel, isVisible: isErrorVisible) }
    }

    var isSuccessViewVisible: Bool = false {
        didSet { updateScale(view: successImageView, isVisible: isSuccessViewVisible) }
    }

    // MARK: - Initialisers

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
        navigationBar.title = localized("verify_phrase.title")
    }

    private func setupConstraints() {

        @View var spacerView = UIView()

        addSubview(scrollView)
        [headerLabel, tokensView, tokensViewInfoLabel, successImageView, errorLabel, spacerView, selectableTokensView, continueButton].forEach(scrollView.contentView.addSubview)

        let scrollViewConstants = [
            scrollView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
        ]

        let constraints = [
            headerLabel.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor, constant: 16.0),
            headerLabel.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor, constant: 20.0),
            headerLabel.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor, constant: -20.0),
            tokensView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16.0),
            tokensView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor, constant: 20.0),
            tokensView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor, constant: -20.0),
            tokensView.heightAnchor.constraint(equalToConstant: 272.0),
            tokensViewInfoLabel.leadingAnchor.constraint(equalTo: tokensView.leadingAnchor, constant: 20.0),
            tokensViewInfoLabel.trailingAnchor.constraint(equalTo: tokensView.trailingAnchor, constant: -20.0),
            tokensViewInfoLabel.centerYAnchor.constraint(equalTo: tokensView.centerYAnchor),
            successImageView.topAnchor.constraint(equalTo: selectableTokensView.topAnchor),
            successImageView.centerXAnchor.constraint(equalTo: scrollView.contentView.centerXAnchor),
            successImageView.widthAnchor.constraint(equalToConstant: 29.0),
            successImageView.heightAnchor.constraint(equalToConstant: 29.0),
            errorLabel.topAnchor.constraint(equalTo: selectableTokensView.topAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor, constant: 20.0),
            errorLabel.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor, constant: -20.0),
            errorLabel.heightAnchor.constraint(equalToConstant: 37.0),
            selectableTokensView.topAnchor.constraint(equalTo: tokensView.bottomAnchor, constant: 16.0),
            selectableTokensView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor, constant: 20.0),
            selectableTokensView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor, constant: -20.0),
            spacerView.topAnchor.constraint(equalTo: selectableTokensView.bottomAnchor),
            spacerView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            spacerView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            continueButton.topAnchor.constraint(equalTo: spacerView.bottomAnchor, constant: 16.0),
            continueButton.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor, constant: 16.0),
            continueButton.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor, constant: -20.0),
            continueButton.bottomAnchor.constraint(equalTo: scrollView.contentView.safeAreaLayoutGuide.bottomAnchor, constant: -16.0)
        ]

        NSLayoutConstraint.activate(scrollViewConstants + constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)

        headerLabel.textColor = theme.text.body
        errorLabel.textColor = theme.system.red
        errorLabel.layer.borderColor = theme.system.red?.cgColor
        tokensViewInfoLabel.textColor = theme.text.body
        selectableTokensView.backgroundColor = .clear
    }

    private func updateInfoLabel() {
        UIView.animate(withDuration: 0.4, delay: 0.0, options: [.beginFromCurrentState]) {
            self.tokensViewInfoLabel.alpha = self.isInfoLabelVisible ? 1.0 : 0.0
        }
    }

    private func updateScale(view: UIView, isVisible: Bool) {
        UIView.animate(withDuration: 0.4, delay: 0.0, options: [.beginFromCurrentState]) {
            let scale = isVisible ? 1.0 : 0.0001
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
}
