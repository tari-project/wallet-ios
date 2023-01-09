//  ContactAvatarView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 17/10/2021
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

final class ContactAvatarView: DynamicThemeView {
    
    // MARK: - Subviews
    
    @View private var placeholderImageView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.unknownUser
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    @View private var label: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.contactCellAliasLetter
        return view
    }()

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        
        backgroundColor = theme.neutral.tertiary
        placeholderImageView.tintColor = theme.text.body
        label.textColor = theme.text.body
    }
    
    // MARK: - Properties
    
    var text: String = "" {
        didSet {
            label.text = text
            label.isHidden = text.isEmpty
            placeholderImageView.isHidden = !text.isEmpty
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
        layer.cornerRadius = 12.0
        clipsToBounds = true
    }
    
    private func setupConstraints() {
        
        [placeholderImageView, label].forEach(addSubview)
        
        let constraints = [
            placeholderImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholderImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),
            placeholderImageView.widthAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 44.0),
            widthAnchor.constraint(equalToConstant: 44.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}
