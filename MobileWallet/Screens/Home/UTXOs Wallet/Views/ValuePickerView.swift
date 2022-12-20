//  ValuePickerView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 05/07/2022
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

final class ValuePickerView: DynamicThemeView {
    
    // MARK: - Subviews
    
    @View private var minusButtonBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 9.0
        return view
    }()
    
    @View private var minusButton: BaseButton = {
        let view = BaseButton()
        view.setImage(Theme.shared.images.utxoWalletPickerMinus, for: .normal)
        return view
    }()
    
    @View private var valueLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .Avenir.heavy.withSize(22.0)
        return view
    }()
    
    @View private var plusButtonBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 9.0
        return view
    }()
    
    @View private var plusButton: BaseButton = {
        let view = BaseButton()
        view.setImage(Theme.shared.images.utxoWalletPickerPlus, for: .normal)
        return view
    }()
    
    // MARK: - Properties
    
    var minValue: Int = 0
    var maxValue: Int = 0
    var onValueChanged: ((Int) -> Void)?
    
    var value: Int = 0 {
        didSet { update(value: value) }
    }
    
    // MARK: - Initialisers
    
    override init() {
        super.init()
        setupConstraints()
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupConstraints() {
        
        [minusButtonBackgroundView, plusButtonBackgroundView, minusButton, valueLabel, plusButton].forEach(addSubview)
        
        let constraints = [
            minusButtonBackgroundView.centerXAnchor.constraint(equalTo: minusButton.centerXAnchor),
            minusButtonBackgroundView.centerYAnchor.constraint(equalTo: minusButton.centerYAnchor),
            minusButtonBackgroundView.widthAnchor.constraint(equalToConstant: 18.0),
            minusButtonBackgroundView.heightAnchor.constraint(equalToConstant: 18.0),
            plusButtonBackgroundView.centerXAnchor.constraint(equalTo: plusButton.centerXAnchor),
            plusButtonBackgroundView.centerYAnchor.constraint(equalTo: plusButton.centerYAnchor),
            plusButtonBackgroundView.widthAnchor.constraint(equalToConstant: 18.0),
            plusButtonBackgroundView.heightAnchor.constraint(equalToConstant: 18.0),
            minusButton.topAnchor.constraint(equalTo: topAnchor),
            minusButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            minusButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            minusButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor, constant: 8.0),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            valueLabel.widthAnchor.constraint(equalToConstant: 70.0),
            plusButton.topAnchor.constraint(equalTo: topAnchor),
            plusButton.leadingAnchor.constraint(equalTo: valueLabel.trailingAnchor, constant: 8.0),
            plusButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            plusButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 34.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        
        minusButton.onTap = { [weak self] in
            guard let self = self else { return }
            self.value = max(self.minValue, self.value - 1)
        }
        
        plusButton.onTap = { [weak self] in
            guard let self = self else { return }
            self.value = min(self.maxValue, self.value + 1)
        }
    }
    
    // MARK: - Updates
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        valueLabel.textColor = theme.text.heading
        valueLabel.backgroundColor = theme.backgrounds.secondary
        updateButtonsColor(theme: theme)
    }
    
    private func updateButtonsColor(theme: ColorTheme) {
        minusButtonBackgroundView.backgroundColor = value == minValue ? theme.neutral.inactive  : theme.brand.purple
        plusButtonBackgroundView.backgroundColor = value == maxValue ? theme.neutral.inactive : theme.brand.purple
    }
    
    private func update(value: Int) {
        valueLabel.text = "\(value)"
        updateButtonsColor(theme: theme)
        onValueChanged?(value)
    }
}
