//  ContextualButton.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 14/06/2022
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

final class ContextualButton: BaseButton {
    
    // MARK: - Subviews
    
    @View private var label: UILabel = {
        let view = UILabel()
        view.textColor = .tari.greys.black
        view.textAlignment = .right
        view.font = .Avenir.medium.withSize(17.0)
        return view
    }()
    
    @View private var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = .tari.greys.black
        return view
    }()
    
    // MARK: - Properties
    
    var isExpanded: Bool = true {
        didSet { updateLayout() }
    }
    
    private var labelLeadingConstraint: NSLayoutConstraint?
    
    private var testConst: NSLayoutConstraint?
    
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
        
        [label, iconView].forEach(addSubview)

        let labelLeadingConstraint = label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15.0)
        self.labelLeadingConstraint = labelLeadingConstraint

        let constraints = [
            iconView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 15.0),
            labelLeadingConstraint,
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 10.0),
            iconView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10.0),
            iconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15.0),
            iconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10.0),
            iconView.widthAnchor.constraint(equalToConstant: 20.0),
            iconView.heightAnchor.constraint(equalToConstant: 20.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Actions
    
    func update(text: String?, icon: UIImage?) {
        label.text = text
        iconView.image = icon
    }
    
    private func updateLayout() {
        labelLeadingConstraint?.isActive = isExpanded
        label.alpha = isExpanded ? 1.0 : 0.0
    }
}
