//  UTXOsWalletTopBar.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 24/06/2022
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

final class UTXOsWalletTopBar: UIView {
    
    // MARK: - Subviews
    
    @View private var filterButton: LeftImageButton = {
        let view = LeftImageButton()
        view.iconView.image = Theme.shared.images.utxoFaucet
        view.iconView.tintColor = .black
        view.label.textColor = .black
        view.label.font = .Avenir.roman.withSize(14.0)
        view.iconSize = CGSize(width: 14.0, height: 14.0)
        view.internalPadding = 12.0
        return view
    }()
    
    @View private var editButton: BaseButton = {
        let view = BaseButton()
        view.titleLabel?.font = .Avenir.roman.withSize(14.0)
        view.setTitleColor(.tari.purple, for: .normal)
        return view
    }()
    
    // MARK: - Properties
    
    var filterButtonTitle: String? {
        get { filterButton.label.text }
        set { filterButton.label.text = newValue }
    }
    
    var height: CGFloat = 0.0 {
        didSet { heightConstraint?.constant = height }
    }
    
    var onFilterButtonTap: (() -> Void)?
    var onSelectButtonTap: (() -> Void)?
    
    var isEditingEnabled: Bool = false {
        didSet { update(isEditingEnabled: isEditingEnabled) }
    }
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupConstraints()
        setupCallbacks()
        update(isEditingEnabled: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var backgroundAlpha: CGFloat = 0.0 {
        didSet { backgroundColor = .tari.white?.withAlphaComponent(backgroundAlpha) }
    }
    
    private var heightConstraint: NSLayoutConstraint?
    
    // MARK: - Setups
    
    private func setupConstraints() {
        
        [filterButton, editButton].forEach(addSubview)
        
        let heightConstraint = heightAnchor.constraint(equalToConstant: height)
        self.heightConstraint = heightConstraint
        
        let constraints = [
            filterButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32.0),
            filterButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            filterButton.heightAnchor.constraint(equalToConstant: 44.0),
            editButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32.0),
            editButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            editButton.heightAnchor.constraint(equalToConstant: 44.0),
            heightConstraint
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        
        filterButton.onTap = { [weak self] in
            self?.onFilterButtonTap?()
        }
        
        editButton.onTap = { [weak self] in
            self?.onSelectButtonTap?()
        }
    }
    
    // MARK: - Actions
    
    private func update(isEditingEnabled: Bool) {
        let title = isEditingEnabled ? localized("common.cancel") : localized("utxos_wallet.button.edit_mode.select")
        editButton.setTitle(title, for: .normal)
    }
}
