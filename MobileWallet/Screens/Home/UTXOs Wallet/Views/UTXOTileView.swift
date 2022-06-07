//  UTXOTileView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 06/06/2022
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

final class UTXOTileView: UIView {
    
    struct Model {
        let amountText: String
        let backgroundColor: UIColor?
        let height: CGFloat
        let statusIcon: UIImage?
        let statusName: String
    }
    
    // MARK: - Subviews
    
    @View private var amountContentView = UIView()
    
    @View private var amountLabel: CurrencyLabelView = {
        let view = CurrencyLabelView()
        view.textColor = .tari.white
        view.font = .Avenir.black.withSize(30.0)
        view.secondaryFont = .Avenir.black.withSize(12.0)
        view.separator = "."
        view.iconHeight = 13.0
        return view
    }()
    
    @View private var statusIcon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = .tari.white
        return view
    }()
    
    @View private var statusLabel: UILabel = {
        let view = UILabel()
        view.textColor = .tari.white
        view.font = .Avenir.medium.withSize(12.0)
        return view
    }()
    
    // MARK: - Initialisers
    
    init(model: Model) {
        super.init(frame: .zero)
        setupViews(model: model)
        setupConstraints(height: model.height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews(model: Model) {
        layer.cornerRadius = 10.0
        backgroundColor = model.backgroundColor
        amountLabel.text = model.amountText
        statusIcon.image = model.statusIcon
        statusLabel.text = model.statusName
    }
    
    private func setupConstraints(height: CGFloat) {
        
        amountContentView.addSubview(amountLabel)
        [amountContentView, statusIcon, statusLabel].forEach(addSubview)
        
        let constraints = [
            amountContentView.topAnchor.constraint(equalTo: topAnchor),
            amountContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            amountContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: amountContentView.leadingAnchor, constant: 10.0),
            amountLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountContentView.trailingAnchor, constant: -10.0),
            amountLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            amountLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10.0),
            statusIcon.heightAnchor.constraint(equalToConstant: 14.0),
            statusIcon.widthAnchor.constraint(equalToConstant: 14.0),
            statusIcon.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            statusLabel.topAnchor.constraint(equalTo: amountContentView.bottomAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusIcon.trailingAnchor, constant: 6.0),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10.0),
            statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10.0),
            heightAnchor.constraint(equalToConstant: height),
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}


