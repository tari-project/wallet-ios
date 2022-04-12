//  CustomDeeplinkPopUpContentView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 11/04/2022
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

final class CustomDeeplinkPopUpContentView: UIView {
    
    // MARK: - Subviews
    
    @View private var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.shared.colors.profileBackground
        view.layer.cornerRadius = 10.0
        return view
    }()
    
    @View private var nameLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(14.0)
        view.textColor = Theme.shared.colors.profileMiddleLabel
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()
    
    @View private var peerTitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("add_base_node_overlay.label.peer")
        view.font = .Avenir.black.withSize(14.0)
        view.textColor = Theme.shared.colors.profileMiddleLabel
        view.textAlignment = .center
        return view
    }()
    
    @View private var peerAddressLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(14.0)
        view.textColor = Theme.shared.colors.profileMiddleLabel
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()
    
    @View private var showHideButton: TextButton = {
        let view = TextButton()
        view.setVariation(.secondary)
        return view
    }()
    
    // MARK: - Properties
    
    private var isExpanded: Bool = false {
        didSet { updateViews() }
    }
    
    private var buttonTopConstraintWhenViewCollapsed: NSLayoutConstraint?
    private var buttonTopConstraintWhenViewExpanded: NSLayoutConstraint?
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupConstraints()
        setupCallbacks()
        updateViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupConstraints() {
        
        buttonTopConstraintWhenViewExpanded = showHideButton.topAnchor.constraint(equalTo: peerAddressLabel.bottomAnchor, constant: 12.0)
        buttonTopConstraintWhenViewCollapsed = showHideButton.topAnchor.constraint(equalTo: topAnchor)
        
        [backgroundView, showHideButton].forEach(addSubview)
        [nameLabel, peerTitleLabel, peerAddressLabel].forEach(backgroundView.addSubview)
        
        let constraints = [
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            nameLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 22.0),
            nameLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 14.0),
            nameLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -14.0),
            peerTitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4.0),
            peerTitleLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 14.0),
            peerTitleLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -14.0),
            peerAddressLabel.topAnchor.constraint(equalTo: peerTitleLabel.bottomAnchor),
            peerAddressLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 14.0),
            peerAddressLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -14.0),
            showHideButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18.0),
            showHideButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        showHideButton.onTap = { [weak self] in
            self?.isExpanded.toggle()
        }
    }
    
    // MARK: - Actions
    
    func update(name: String, peer: String) {
        peerAddressLabel.text = peer
        
        let namePrefix = localized("add_base_node_overlay.label.name")
        let nameText = NSMutableAttributedString(string: namePrefix + " " + name)
        
        nameText.setAttributes([.font : UIFont.Avenir.black.withSize(14.0)], range: NSRange(location: 0, length: namePrefix.count))
        nameLabel.attributedText = nameText
    }
    
    private func updateViews() {
        
        let buttonTitle = isExpanded ? localized("add_base_node_overlay.button.hide_details") : localized("add_base_node_overlay.button.show_details")
        showHideButton.setTitle(buttonTitle, for: .normal)
        
        if isExpanded {
            buttonTopConstraintWhenViewCollapsed?.isActive = false
            buttonTopConstraintWhenViewExpanded?.isActive = true
        } else {
            buttonTopConstraintWhenViewExpanded?.isActive = false
            buttonTopConstraintWhenViewCollapsed?.isActive = true
        }
        
        UIView.animate(withDuration: 0.3) {
            self.backgroundView.alpha = self.isExpanded ? 1.0 : 0.0
            PopUpPresenter.layoutIfNeeded()
        }
    }
}
 
