//  ExpandButton.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 10/03/2022
	Using Swift 5.0
	Running on macOS 12.2

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

final class ExpandButton: BaseButton {
    
    // MARK: - Constants
    
    private let totalHeight: CGFloat = 32.0
    
    // MARK: - Subviews
    
    @View private var topArrowView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.expandButtonArrow
        view.tintColor = Theme.shared.colors.checkBoxBorderColor
        return view
    }()
    
    @View private var bottomArrowView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.expandButtonArrow
        view.tintColor = Theme.shared.colors.checkBoxBorderColor
        return view
    }()
    
    // MARK: - Properties
    
    var areArrowsPointedInside: Bool = false {
        didSet { updateArrows() }
    }
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        updateArrows()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        layer.borderColor = Theme.shared.colors.checkBoxBorderColor?.cgColor
        layer.borderWidth = totalHeight / 23.0
        layer.cornerRadius = totalHeight / 2.0
    }
    
    private func setupConstraints() {
        
        [topArrowView, bottomArrowView].forEach(addSubview)
        
        let padding = (2.8 / 23.0) * totalHeight
        let arrowHeight = (10.3 / 23.0) * totalHeight
        
        let constraints = [
            topArrowView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            topArrowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            topArrowView.heightAnchor.constraint(equalToConstant: arrowHeight),
            topArrowView.widthAnchor.constraint(equalToConstant: arrowHeight),
            bottomArrowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            bottomArrowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            bottomArrowView.heightAnchor.constraint(equalToConstant: arrowHeight),
            bottomArrowView.widthAnchor.constraint(equalToConstant: arrowHeight),
            heightAnchor.constraint(equalToConstant: totalHeight),
            widthAnchor.constraint(equalToConstant: totalHeight)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Actions
    
    private func updateArrows() {
        
        let topArrowAngle: CGFloat = areArrowsPointedInside ? .pi : 0.0
        let bottomArrowAngle: CGFloat = areArrowsPointedInside ? 0.0 : .pi
        
        topArrowView.transform = CGAffineTransform(rotationAngle: topArrowAngle)
        bottomArrowView.transform = CGAffineTransform(rotationAngle: bottomArrowAngle)
    }
}
