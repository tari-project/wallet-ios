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

final class VerifySeedWordsView: BaseSettingsView {
    
    // MARK: - Subviews
    
    @View private var scrollView = UIScrollView()
    @View private var contentView = UIView()
    
    @View private var headerLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.settingsSeedPhraseDescription
        view.textColor = Theme.shared.colors.settingsViewDescription
        view.text = localized("verify_phrase.header")
        return view
    }()
    
    
    @View private(set) var tokensView = TokenCollectionView()
    
    @View private var errorLabel: UILabel = {
        let view = UILabel()
        view.text = localized("verify_phrase.warning")
        view.textColor = Theme.shared.colors.warningBoxBorder
        view.font = Theme.shared.fonts.warningBoxTitleLabel
        view.textAlignment = .center
        view.layer.cornerRadius = 4.0
        view.layer.borderWidth = 1.0
        view.layer.borderColor = Theme.shared.colors.warningBoxBorder?.cgColor
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
        view.textColor = Theme.shared.colors.settingsFillablePhraseViewDescription
        view.textAlignment = .center
        return view
    }()
    
    @View private(set) var selectableTokensView: TokenCollectionView = {
        let view = TokenCollectionView()
        view.backgroundColor = .clear
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
    
    @View private(set) var continueButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("verify_phrase.complete"), for: .normal)
        return view
    }()
    
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
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        [headerLabel, tokensView, tokensViewInfoLabel, successImageView, errorLabel, selectableTokensView, continueButton].forEach(contentView.addSubview)
        
        let scrollViewConstants = [
            scrollView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor),
        ]
        
        let constraints = [
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20.0),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            tokensView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20.0),
            tokensView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            tokensView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            tokensView.heightAnchor.constraint(equalToConstant: 272.0),
            tokensViewInfoLabel.leadingAnchor.constraint(equalTo: tokensView.leadingAnchor, constant: 20.0),
            tokensViewInfoLabel.trailingAnchor.constraint(equalTo: tokensView.trailingAnchor, constant: -20.0),
            tokensViewInfoLabel.centerYAnchor.constraint(equalTo: tokensView.centerYAnchor),
            successImageView.topAnchor.constraint(equalTo: selectableTokensView.topAnchor),
            successImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            successImageView.widthAnchor.constraint(equalToConstant: 29.0),
            successImageView.heightAnchor.constraint(equalToConstant: 29.0),
            errorLabel.topAnchor.constraint(equalTo: selectableTokensView.topAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            errorLabel.heightAnchor.constraint(equalToConstant: 37.0),
            selectableTokensView.topAnchor.constraint(equalTo: tokensView.bottomAnchor, constant: 25.0),
            selectableTokensView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            selectableTokensView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            selectableTokensView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20.0),
            continueButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            continueButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            continueButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -20.0)
        ]
        
        NSLayoutConstraint.activate(scrollViewConstants + constraints)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentSize.height = contentView.bounds.height
    }
    
    // MARK: - Actions
    
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
