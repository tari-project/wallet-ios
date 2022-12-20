//  RadioButtonView.swift
	
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

final class RadioButtonView: UIView {
    
    // MARK: - Subviews
    
    @View private var dotView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    // MARK: - Properties
    
    var borderColor: UIColor? {
        didSet { layer.borderColor = borderColor?.cgColor }
    }
    
    var fillColor: UIColor? {
        didSet { dotView.backgroundColor = fillColor }
    }
    
    var isSelected: Bool = false {
        didSet {
            dotView.isHidden = !isSelected
        }
    }
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        layer.borderWidth = 1.0
    }
    
    private func setupConstraints() {
        
        addSubview(dotView)
        
        let constraints = [
            dotView.topAnchor.constraint(equalTo: topAnchor, constant: 2.0),
            dotView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2.0),
            dotView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2.0),
            dotView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2.0
        dotView.layer.cornerRadius = (bounds.width - 4.0) / 2.0
    }
}
