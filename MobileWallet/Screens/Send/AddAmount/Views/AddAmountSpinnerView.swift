//  AddAmountSpinnerView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 27/05/2022
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
import Lottie

final class AddAmountSpinnerView: DynamicThemeView {
    
    // MARK: - Subviews
    
    private let spinnerView: AnimationView = {
        let view = AnimationView()
        view.backgroundBehavior = .pauseAndRestore
        view.animation = Animation.named(.pendingCircleAnimation)
        view.loopMode = .loop
        view.play()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    @View private var label: UILabel = {
        let view = UILabel()
        view.text = localized("add_amount.spinner_view.label.calculating")
        view.textAlignment = .center
        view.font = .Avenir.light.withSize(14.0)
        return view
    }()
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.body
    }
    
    // MARK: - Initialisers
    
    override init() {
        super.init()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupConstraints() {
        
        [spinnerView, label].forEach(addSubview)
        
        let constraints = [
            spinnerView.topAnchor.constraint(equalTo: topAnchor, constant: 5.0),
            spinnerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinnerView.heightAnchor.constraint(equalToConstant: 31.0),
            spinnerView.widthAnchor.constraint(equalToConstant: 31.0),
            label.topAnchor.constraint(equalTo: spinnerView.bottomAnchor, constant: 2.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -5.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}
