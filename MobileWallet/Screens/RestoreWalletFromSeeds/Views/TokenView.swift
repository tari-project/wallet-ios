//  TokenView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 23/07/2021
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
import TariCommon

final class TokenView: DynamicThemeCollectionCell {

    // MARK: - Subviews

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.restoreFromSeedWordsToken
        return view
    }()

    @View private var deleteIconView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.cancelGrey
        return view
    }()

    // MARK: - Properties

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }
    
    var isDeleteIconVisible: Bool = true {
        didSet {
            deleteIconLeadingConstraint?.isActive = isDeleteIconVisible
            deleteIconView.isHidden = !isDeleteIconVisible
        }
    }
    
    var isValid: Bool = true {
        didSet { updateColors() }
    }
    
    private var validBorderColor: UIColor?
    private var invalidBorderColor: UIColor?
    private var validTextColor: UIColor?
    private var invalidTextColor: UIColor?
    private var validIconTintColor: UIColor?
    private var invalidIconTintColor: UIColor?
    private var deleteIconLeadingConstraint: NSLayoutConstraint?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        layer.cornerRadius = 5.0
        layer.borderWidth = 1.0
        isValid = true
    }

    private func setupConstraints() {

        [label, deleteIconView].forEach(addSubview)
        
        let labelTrailingConstraint = label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13.0)
        labelTrailingConstraint.priority = .defaultHigh
        
        let deleteIconLeadingConstraint = deleteIconView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5.0)
        self.deleteIconLeadingConstraint = deleteIconLeadingConstraint

        let constraints = [
            label.topAnchor.constraint(equalTo: topAnchor, constant: 3.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13.0),
            labelTrailingConstraint,
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3.0),
            deleteIconLeadingConstraint,
            deleteIconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8.0),
            deleteIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteIconView.heightAnchor.constraint(equalToConstant: 14.0),
            deleteIconView.widthAnchor.constraint(equalToConstant: 14.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Updates
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        
        backgroundColor = theme.backgrounds.primary
        validBorderColor = theme.neutral.tertiary
        invalidBorderColor = theme.system.red
        validTextColor = theme.text.body
        invalidTextColor = theme.system.red
        validIconTintColor = theme.text.body
        invalidIconTintColor = theme.system.red
        
        updateColors()
    }
    
    private func updateColors() {
        layer.borderColor = isValid ? validBorderColor?.cgColor : invalidBorderColor?.cgColor
        label.textColor = isValid ? validTextColor : invalidTextColor
        deleteIconView.tintColor = isValid ? validIconTintColor : invalidIconTintColor
    }
}
