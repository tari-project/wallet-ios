//  UTXOsWalletTextListViewCell.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 08/06/2022
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

final class UTXOsWalletTextListViewCell: UITableViewCell {
    
    struct Model: Identifiable, Hashable {
        var id: UUID
        let amount: String
        let hash: String
    }
    
    // MARK: - Subviews
    
    @View private var amountLabel: UILabel = {
        let view = UILabel()
        view.textColor = .tari.greys.black
        view.font = .Avenir.heavy.withSize(15.0)
        return view
    }()
    
    @View private var hashLabel: UILabel = {
        let view = UILabel()
        view.textColor = .tari.greys.mediumDarkGrey
        view.font = .Avenir.roman.withSize(12.0)
        return view
    }()
    
    @View private var tickView = UTXOsWalletTextTickButton()
    
    // MARK: - Properties
    
    var isTickSelected: Bool = false {
        didSet { update(selectionState: isTickSelected) }
    }
    
    var onTapOnTickbox: ((UUID) -> Void)?
    private(set) var elementID: UUID?
    
    private var leadingAmountLabelConstraint: NSLayoutConstraint?
    private var leadingAmountLabelConstraintInEditing: NSLayoutConstraint?
    private var leadingHashLabelConstraint: NSLayoutConstraint?
    private var leadingHashLabelConstraintInEditing: NSLayoutConstraint?
    
    // MARK: - Initialisers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        selectionStyle = .none
    }
    
    private func setupConstraints() {
        
        [tickView, amountLabel, hashLabel].forEach(contentView.addSubview)
        
        let leadingAmountLabelConstraint = amountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30.0)
        let leadingHashLabelConstraint = hashLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30.0)
        leadingAmountLabelConstraintInEditing = amountLabel.leadingAnchor.constraint(equalTo: tickView.trailingAnchor, constant: 10.0)
        leadingHashLabelConstraintInEditing = hashLabel.leadingAnchor.constraint(equalTo: tickView.trailingAnchor, constant: 10.0)
        
        self.leadingAmountLabelConstraint = leadingAmountLabelConstraint
        self.leadingHashLabelConstraint = leadingHashLabelConstraint
        
        let constraints = [
            tickView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30.0),
            tickView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tickView.widthAnchor.constraint(equalToConstant: 24.0),
            tickView.heightAnchor.constraint(equalToConstant: 24.0),
            amountLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15.0),
            leadingAmountLabelConstraint,
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30.0),
            hashLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 5.0),
            leadingHashLabelConstraint,
            hashLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30.0),
            hashLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        
        tickView.onTap = { [weak self] in
            guard let elementID = self?.elementID else { return }
            self?.onTapOnTickbox?(elementID)
        }
    }
    
    // MARK: - Actions
    
    func update(model: Model) {
        elementID = model.id
        amountLabel.text = model.amount
        hashLabel.text = model.hash
    }
    
    func updateTickBox(isVisible: Bool, animated: Bool) {
        
        if isVisible  {
            leadingAmountLabelConstraint?.isActive = false
            leadingHashLabelConstraint?.isActive = false
            leadingAmountLabelConstraintInEditing?.isActive = true
            leadingHashLabelConstraintInEditing?.isActive = true
        } else {
            leadingAmountLabelConstraintInEditing?.isActive = false
            leadingHashLabelConstraintInEditing?.isActive = false
            leadingAmountLabelConstraint?.isActive = true
            leadingHashLabelConstraint?.isActive = true
        }
        
        UIView.animate(withDuration: animated ? 0.3: 0.0) {
            self.tickView.alpha = isVisible ? 1.0 : 0.0
            self.layoutIfNeeded()
        }
    }
    
    private func update(selectionState: Bool) {
        tickView.isSelected = selectionState
    }
}
