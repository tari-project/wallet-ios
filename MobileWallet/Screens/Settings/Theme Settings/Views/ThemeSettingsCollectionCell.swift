//  ThemeSettingsCollectionCell.swift
	
/*
	Package MobileWallet
	Created by Browncoat on 18/12/2022
	Using Swift 5.0
	Running on macOS 13.0

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

final class ThemeSettingsCollectionCell: DynamicThemeCollectionCell {
    
    // MARK: - Subviews
    
    @View private var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    @View private var label: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(15.0)
        view.textAlignment = .center
        return view
    }()
    
    @View private var radioButton = RadioButtonView()
    
    // MARK: - Properties
    
    override var isSelected: Bool {
        didSet { radioButton.isSelected = isSelected }
    }
    
    // MARK: - Initialisers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupConstraints() {
        
        [imageView, label, radioButton].forEach { contentView.addSubview($0) }
        
        let constaints = [
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 10.0),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 200.0),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            radioButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5.0),
            radioButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            radioButton.widthAnchor.constraint(equalToConstant: 16.0),
            radioButton.heightAnchor.constraint(equalToConstant: 16.0),
            radioButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10.0)
        ]
        
        NSLayoutConstraint.activate(constaints)
    }
    
    // MARK: - Updates
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.heading
        radioButton.borderColor = theme.neutral.inactive
        radioButton.fillColor = theme.brand.purple
    }
    
    func update(image: UIImage?, title: String?) {
        imageView.image = image
        label.text = title
    }
}
