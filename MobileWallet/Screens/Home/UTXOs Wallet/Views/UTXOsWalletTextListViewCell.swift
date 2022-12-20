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

final class UTXOsWalletTextListViewCell: DynamicThemeCell {
    
    struct Model: Identifiable, Hashable {
        var id: UUID
        let amount: String
        let status: UtxoStatus
        let statusText: String?
        let hash: String
        let isSelectable: Bool
    }
    
    // MARK: - Subviews
    
    @View private var backgroundContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    @View private var amountLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.heavy.withSize(15.0)
        return view
    }()
    
    @View private var hashLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.roman.withSize(12.0)
        return view
    }()
    
    @View private var statusCircleView: UIView = UIView()
    
    @View private var statusLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.roman.withSize(12.0)
        return view
    }()
    
    @View private var tickView = UTXOsWalletTickButton()
    
    // MARK: - Properties
    
    var isTickSelected: Bool = false {
        didSet { update(selectionState: isTickSelected) }
    }
    
    private(set) var elementID: UUID?
    
    private var status: UtxoStatus = .mined
    private var isSelectable = false
    private var leadingConstraint: NSLayoutConstraint?
    private var leadingConstraintInEditing: NSLayoutConstraint?
    
    // MARK: - Initialisers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    private func setupConstraints() {
        
        [backgroundContentView, tickView].forEach(contentView.addSubview)
        [amountLabel, statusCircleView, statusLabel, hashLabel].forEach(backgroundContentView.addSubview)
        
        let leadingConstraint = backgroundContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30.0)
        leadingConstraintInEditing = backgroundContentView.leadingAnchor.constraint(equalTo: tickView.trailingAnchor, constant: 10.0)
        
        self.leadingConstraint = leadingConstraint
        
        
        let constraints = [
            backgroundContentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            leadingConstraint,
            backgroundContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tickView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30.0),
            tickView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tickView.widthAnchor.constraint(equalToConstant: 24.0),
            tickView.heightAnchor.constraint(equalToConstant: 24.0),
            amountLabel.topAnchor.constraint(equalTo: backgroundContentView.topAnchor, constant: 15.0),
            amountLabel.leadingAnchor.constraint(equalTo: backgroundContentView.leadingAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: backgroundContentView.trailingAnchor, constant: -30.0),
            statusCircleView.leadingAnchor.constraint(equalTo: backgroundContentView.leadingAnchor),
            statusCircleView.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            statusCircleView.widthAnchor.constraint(equalToConstant: 8.0),
            statusCircleView.heightAnchor.constraint(equalToConstant: 8.0),
            statusLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 5.0),
            statusLabel.leadingAnchor.constraint(equalTo: statusCircleView.trailingAnchor, constant: 5.0),
            statusLabel.trailingAnchor.constraint(equalTo: backgroundContentView.trailingAnchor, constant: -30.0),
            hashLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5.0),
            hashLabel.leadingAnchor.constraint(equalTo: backgroundContentView.leadingAnchor),
            hashLabel.trailingAnchor.constraint(equalTo: backgroundContentView.trailingAnchor, constant: -30.0),
            hashLabel.bottomAnchor.constraint(equalTo: backgroundContentView.bottomAnchor, constant: -15.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Actions
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        statusCircleView.backgroundColor = status.color(theme: theme)
        amountLabel.textColor = theme.text.heading
        hashLabel.textColor = theme.text.body
        statusLabel.textColor = theme.text.body
    }
    
    func update(model: Model) {
        elementID = model.id
        isSelectable = model.isSelectable
        amountLabel.text = model.amount
        hashLabel.text = model.hash
        statusLabel.text = model.statusText
        
        status = model.status
        update(theme: theme)
    }
    
    func updateTickBox(isVisible: Bool, animated: Bool) {
        
        if isVisible {
            leadingConstraint?.isActive = false
            leadingConstraintInEditing?.isActive = true
        } else {
            leadingConstraintInEditing?.isActive = false
            leadingConstraint?.isActive = true
        }
        
        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.tickView.alpha = isVisible ? 1.0 : 0.0
            self.layoutIfNeeded()
        }
    }
    
    func updateBackground(isSemitransparent: Bool, animated: Bool) {
        
        UIView.animate(withDuration: animated ? 0.3 : 0.0) {
            self.contentView.alpha = isSemitransparent ? 0.6 : 1.0
        }
    }
    
    private func update(selectionState: Bool) {
        tickView.isSelected = selectionState
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        statusCircleView.layer.cornerRadius = statusCircleView.bounds.height / 2.0
    }
}
