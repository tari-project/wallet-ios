//  PopUpUTXOsSplitContentView.swift
	
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
import Combine

final class PopUpUTXOsSplitContentView: UIView {
    
    // MARK: - Constants
    
    private static let minimumValue = 2
    private static let maximumValue = 50
    
    // MARK: - Subviews
    
    @View private var descriptionLabel: UILabel = {
        let view = UILabel()
        view.text = localized("utxos_wallet.pop_up.split.description")
        view.textColor = .tari.greys.mediumDarkGrey
        view.textAlignment = .center
        view.font = .Avenir.medium.withSize(14.0)
        view.numberOfLines = 0
        return view
    }()
    
    @View private var valuePicker: ValuePickerView = {
        let view = ValuePickerView()
        view.minValue = minimumValue
        view.maxValue = maximumValue
        return view
    }()
    
    @View private var valueSlider: UISlider = {
        let view = UISlider()
        view.minimumValue = Float(minimumValue)
        view.maximumValue = Float(maximumValue)
        view.tintColor = .tari.purple
        return view
    }()
    
    @View private var estimationLabelBackground: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.shared.colors.profileBackground
        view.layer.cornerRadius = 5.0
        return view
    }()
    
    @View private var estimationLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textAlignment = .center
        view.textColor = .tari.greys.mediumDarkGrey
        view.font = .Avenir.medium.withSize(14.0)
        
        return view
    }()
    
    // MARK: - Properties
    
    @Published private(set) var value: Int = minimumValue
    
    private var cancellables = Set<AnyCancellable>()
    
    func update(amount: String, splitCount: String, splitAmount: String, fee: String) {
        
        let imageBounds = CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
        
        let format = NSAttributedString(string: localized("utxos_wallet.pop_up.split.estimation"))
        let amount = amount.withCurrencySymbol(imageBounds: imageBounds, imageTintColor: .tari.greys.mediumDarkGrey)
        let splitCount = NSAttributedString(string: splitCount)
        let splitAmount = splitAmount.withCurrencySymbol(imageBounds: imageBounds, imageTintColor: .tari.greys.mediumDarkGrey)
        let fee = fee.withCurrencySymbol(imageBounds: imageBounds, imageTintColor: .tari.greys.mediumDarkGrey)
        
        estimationLabel.attributedText = NSAttributedString(format: format, arguments: amount, splitCount, splitAmount, fee)
    }
    
    // MARK: - Initalisers
    
    init() {
        super.init(frame: .zero)
        setupConstraints()
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupConstraints() {
        
        [descriptionLabel, valuePicker, valueSlider, estimationLabelBackground].forEach(addSubview)
        estimationLabelBackground.addSubview(estimationLabel)
        
        let constraints = [
            descriptionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10.0),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            valuePicker.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 22.0),
            valuePicker.centerXAnchor.constraint(equalTo: centerXAnchor),
            valueSlider.topAnchor.constraint(equalTo: valuePicker.bottomAnchor, constant: 10.0),
            valueSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            valueSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            estimationLabelBackground.topAnchor.constraint(equalTo: valueSlider.bottomAnchor, constant: 22.0),
            estimationLabelBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            estimationLabelBackground.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            estimationLabelBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
            estimationLabel.topAnchor.constraint(equalTo: estimationLabelBackground.topAnchor, constant: 10.0),
            estimationLabel.leadingAnchor.constraint(equalTo: estimationLabelBackground.leadingAnchor, constant: 20.0),
            estimationLabel.trailingAnchor.constraint(equalTo: estimationLabelBackground.trailingAnchor, constant: -20.0),
            estimationLabel.bottomAnchor.constraint(equalTo: estimationLabelBackground.bottomAnchor, constant: -10.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        
        valueSlider.addTarget(self, action: #selector(sliderWalueChanged), for: .valueChanged)
        
        $value
            .removeDuplicates()
            .sink { [weak self] in
                self?.valueSlider.setValue(Float($0), animated: true)
                self?.valuePicker.value = $0
            }
            .store(in: &cancellables)
        
        valuePicker.onValueChanged = { [weak self] in
            self?.value = $0
        }
    }
    
    // MARK: - Action Targets
    
    @objc private func sliderWalueChanged(_ slider: UISlider) {
        value = Int(round(slider.value))
    }
}
