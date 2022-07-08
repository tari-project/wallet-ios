//  PopUpCombineUTXOsConfirmationContentView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 08/07/2022
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

final class PopUpCombineUTXOsConfirmationContentView: UIView {
    
    // MARK: - Subviews
    
    @View private var messageLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(14.0)
        view.textColor = Theme.shared.colors.profileMiddleLabel
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()
    
    @View private var feeLabel = UTXOsEstimationLabel()
    
    // MARK: - Properties
    
    var messageText: String? {
        get { messageLabel.text }
        set { messageLabel.text = newValue }
    }
    
    var feeText: String? {
        didSet {
            guard let feeText = feeText else { return }
            let format = NSAttributedString(string: localized("utxos_wallet.pop_up.join_confirmation.fee"))
            let feeWithCurrencySymbol = feeText.withCurrencySymbol(imageBounds: CGRect(x: 0.0, y: 0.0, width: 8.0, height: 8.0), imageTintColor: .tari.greys.mediumDarkGrey)
            feeLabel.attributedText = NSAttributedString(format: format, arguments: feeWithCurrencySymbol)
        }
    }
    
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
        
        [messageLabel, feeLabel].forEach(addSubview)
        
        let constraints = [
            messageLabel.topAnchor.constraint(equalTo: topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15.0),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15.0),
            feeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 10.0),
            feeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            feeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            feeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}

