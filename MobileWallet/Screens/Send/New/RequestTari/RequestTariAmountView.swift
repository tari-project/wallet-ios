//  RequestTariAmountView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 14/01/2022
	Using Swift 5.0
	Running on macOS 12.1

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

final class RequestTariAmountView: UIView {
    
    // MARK: - Subviews
    
    @View private var amountLabel: AnimatedBalanceLabel = {
        let view = AnimatedBalanceLabel()
        view.animation = .type
        view.textAlignment = .center(inset: -30)
        return view
    }()
    
    @View var keyboard: AmountKeyboardView = {
        let view = AmountKeyboardView()
        view.setup(keys: .amountKeyboard)
        return view
    }()
    
    @View var generateQrButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("request.buttons.generate_qr"), for: .normal)
        return view
    }()
    
    @View var shareButton: ActionButton = {
        let view = ActionButton()
        view.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        view.tintColor = .white
        view.imageEdgeInsets = .zero
        return view
    }()
    
    @View var amountContentView = UIView()
    @View var keyboardContentView = UIView()
    
    // MARK: - Properties
    
    var amount: String = "0" {
        didSet { update(amount: amount) }
    }
    
    var areButtonsEnabled: Bool = false {
        didSet {
            generateQrButton.variation = areButtonsEnabled ? .normal : .disabled
            shareButton.variation = areButtonsEnabled ? .normal : .disabled
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
        backgroundColor = .white
        update(amount: "0")
        areButtonsEnabled = false
    }
    
    private func setupConstraints() {
        
        amountContentView.addSubview(amountLabel)
        keyboardContentView.addSubview(keyboard)
        [amountContentView, keyboardContentView, generateQrButton, shareButton].forEach(addSubview)
        
        var constraints = [
            amountContentView.topAnchor.constraint(equalTo: topAnchor),
            amountContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            amountContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyboardContentView.topAnchor.constraint(equalTo: amountContentView.bottomAnchor),
            keyboardContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyboardContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            generateQrButton.topAnchor.constraint(equalTo: keyboardContentView.bottomAnchor, constant: 12.0),
            generateQrButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            generateQrButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -25.0),
            shareButton.topAnchor.constraint(equalTo: generateQrButton.topAnchor),
            shareButton.leadingAnchor.constraint(equalTo: generateQrButton.trailingAnchor, constant: 15.0),
            shareButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            shareButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -25.0),
            shareButton.widthAnchor.constraint(equalTo: shareButton.heightAnchor)
        ]
        
        let amountContainnterConstraints = [
            amountLabel.leadingAnchor.constraint(equalTo: amountContentView.leadingAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: amountContentView.trailingAnchor),
            amountLabel.centerYAnchor.constraint(equalTo: amountContentView.centerYAnchor),
        ]
        
        let keyboardBottomConstraint: NSLayoutConstraint
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            keyboardBottomConstraint = keyboard.bottomAnchor.constraint(equalTo: keyboardContentView.bottomAnchor)
        } else {
            let amountContentViewHeightConstraint = amountContentView.heightAnchor.constraint(equalToConstant: 220.0)
            amountContentViewHeightConstraint.priority = .defaultLow
            constraints.append(amountContentViewHeightConstraint)
            keyboardBottomConstraint = keyboard.bottomAnchor.constraint(lessThanOrEqualTo: keyboardContentView.bottomAnchor)
        }
        
        let keyboardContainterConstraints = [
            keyboard.topAnchor.constraint(equalTo: keyboardContentView.topAnchor),
            keyboard.leadingAnchor.constraint(equalTo: keyboardContentView.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: keyboardContentView.trailingAnchor),
            keyboardBottomConstraint
        ]
        
        NSLayoutConstraint.activate(constraints + amountContainnterConstraints + keyboardContainterConstraints)
    }
    
    // MARK: - Updates
    
    private func update(amount: String) {
        
        let amountAttributedText = NSMutableAttributedString(
            string: amount,
            attributes: [
                NSAttributedString.Key.font: Theme.shared.fonts.amountLabel,
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.amountLabel!
            ]
        )
        
        let gemImageString: NSAttributedString = {
            let gemAttachment = NSTextAttachment()
            gemAttachment.image = Theme.shared.images.currencySymbol?.withTintColor(Theme.shared.colors.amountLabel!)
            gemAttachment.bounds = CGRect(x: 0.0, y: 0.0, width: 21.0, height: 21.0)
            return NSAttributedString(attachment: gemAttachment)
        }()
        
        amountAttributedText.insert(gemImageString, at: 0)
        amountAttributedText.insert(NSAttributedString(string: "  "), at: 1)
        
        amountLabel.attributedText = amountAttributedText
    }
}
