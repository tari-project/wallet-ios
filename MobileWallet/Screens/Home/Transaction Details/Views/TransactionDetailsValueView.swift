//  TransactionDetailsValueView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 16/03/2022
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

final class TransactionDetailsValueView: UIView {

    // MARK: - Subviews
    
    @View private var currencyImageView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.currencySymbol?.withRenderingMode(.alwaysTemplate)
        view.contentMode = .scaleAspectFit
        view.tintColor = Theme.shared.colors.txViewValueLabel
        return view
    }()
    
    @View private(set) var valueLabel: UILabel = {
        let view = UILabel()
        view.minimumScaleFactor = 0.2
        view.font = Theme.shared.fonts.txScreenCurrencyValueLabel
        view.textColor = Theme.shared.colors.txViewValueLabel
        view.adjustsFontSizeToFitWidth = true
        return view
    }()
    
    @View private var feeLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.txFeeLabel
        view.textColor = Theme.shared.colors.txViewValueLabel
        return view
    }()
    
    @View private(set) var feeButton: TextButton = {
        let view = TextButton()
        view.setTitle(localized("common.fee"), for: .normal)
        view.titleLabel?.font = Theme.shared.fonts.txFeeButton
        view.setRightImage(Theme.shared.images.txFee)
        return view
    }()
    
    var fee: String? {
        didSet { updateFeeElements() }
    }
    
    // MARK: - Properties
    
    private var valueLabelBottomConstraint: NSLayoutConstraint?
    private var feeButtonBottomConstraint: NSLayoutConstraint?
    
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
        backgroundColor = Theme.shared.colors.txViewValueContainer
    }
    
    private func setupConstraints() {
        
        let feeButtonBottomConstraint = feeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30.0)
        self.feeButtonBottomConstraint = feeButtonBottomConstraint
        valueLabelBottomConstraint = valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30.0)
        
        [currencyImageView, valueLabel, feeLabel, feeButton].forEach(addSubview)
        
        let constraints = [
            currencyImageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 22.0),
            currencyImageView.widthAnchor.constraint(equalToConstant: 21.0),
            currencyImageView.heightAnchor.constraint(equalToConstant: 21.0),
            currencyImageView.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            valueLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30.0),
            valueLabel.leadingAnchor.constraint(equalTo: currencyImageView.trailingAnchor, constant: 11.0),
            valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -22.0),
            valueLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            feeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            feeLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor),
            feeButton.topAnchor.constraint(equalTo: feeLabel.bottomAnchor),
            feeButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            feeButtonBottomConstraint
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Actions
    
    private func updateFeeElements() {
        feeLabel.text = fee
        
        let isFeeVisible = fee != nil
        
        feeLabel.isHidden = !isFeeVisible
        feeButton.isHidden = !isFeeVisible
        
        if isFeeVisible {
            valueLabelBottomConstraint?.isActive = false
            feeButtonBottomConstraint?.isActive = true
        } else {
            feeButtonBottomConstraint?.isActive = false
            valueLabelBottomConstraint?.isActive = true
        }
    }
}
