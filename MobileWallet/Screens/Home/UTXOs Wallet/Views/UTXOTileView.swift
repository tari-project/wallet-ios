//  UTXOTileView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 06/06/2022
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

final class UTXOTileView: UIView {
    
    struct Model {
        let uuid: UUID
        let amountText: String
        let backgroundColor: UIColor?
        let height: CGFloat
        let statusIcon: UIImage?
        let statusName: String
    }
    
    // MARK: - Subviews
    
    @View private var contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10.0
        return view
    }()
    
    @View private var amountContentView = UIView()
    
    @View private var tickButton: UTXOsWalletTileTickButton = {
        let view = UTXOsWalletTileTickButton()
        view.alpha = 0.0
        return view
    }()
    
    @View private var amountLabel: CurrencyLabelView = {
        let view = CurrencyLabelView()
        view.textColor = .tari.white
        view.font = .Avenir.black.withSize(30.0)
        view.secondaryFont = .Avenir.black.withSize(12.0)
        view.separator = "."
        view.iconHeight = 13.0
        return view
    }()
    
    @View private var statusIcon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = .tari.white
        return view
    }()
    
    @View private var statusLabel: UILabel = {
        let view = UILabel()
        view.textColor = .tari.white
        view.font = .Avenir.medium.withSize(12.0)
        return view
    }()
    
    // MARK: - Properties
    
    let elementID: UUID
    
    var isSelected: Bool = false {
        didSet { update(selectionState: isSelected) }
    }
    
    var isSelectModeEnabled: Bool = false {
        didSet { updateTickBox(isVisible: isSelectModeEnabled) }
    }
    
    var onTapOnTickbox: ((UUID) -> Void)?
    var onLongPress: ((UUID) -> Void)?
    
    // MARK: - Initialisers
    
    init(model: Model) {
        self.elementID = model.uuid
        super.init(frame: .zero)
        setupViews(model: model)
        setupConstraints(height: model.height)
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews(model: Model) {
        backgroundColor = .tari.white
        layer.cornerRadius = 10.0
        contentView.backgroundColor = model.backgroundColor
        amountLabel.text = model.amountText
        statusIcon.image = model.statusIcon
        statusLabel.text = model.statusName
    }
    
    private func setupConstraints(height: CGFloat) {
        
        addSubview(contentView)
        amountContentView.addSubview(amountLabel)
        [amountContentView, statusIcon, statusLabel, tickButton].forEach(contentView.addSubview)
        
        let constraints = [
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 2.0),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2.0),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2.0),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2.0),
            tickButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
            tickButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10.0),
            tickButton.heightAnchor.constraint(equalToConstant: 24.0),
            tickButton.widthAnchor.constraint(equalToConstant: 24.0),
            amountContentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            amountContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            amountContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: amountContentView.leadingAnchor, constant: 10.0),
            amountLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountContentView.trailingAnchor, constant: -10.0),
            amountLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10.0),
            statusIcon.heightAnchor.constraint(equalToConstant: 14.0),
            statusIcon.widthAnchor.constraint(equalToConstant: 14.0),
            statusIcon.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),
            statusLabel.topAnchor.constraint(equalTo: amountContentView.bottomAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusIcon.trailingAnchor, constant: 6.0),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10.0),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10.0),
            contentView.heightAnchor.constraint(equalToConstant: height)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        
        tickButton.onTap = { [weak self] in
            guard let self = self else { return }
            self.onTapOnTickbox?(self.elementID)
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressGesture))
        addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - Actions
    
    private func update(selectionState: Bool) {
        
        UIView.animate(withDuration: 0.3) {
            let shadow: Shadow = selectionState ? .selection : .none
            self.apply(shadow: shadow)
        }
        
        tickButton.isSelected = selectionState
    }
    
    private func updateTickBox(isVisible: Bool) {
        
        UIView.animate(withDuration: 0.1) {
            self.tickButton.alpha = isVisible ? 1.0 : 0.0
        }
    }
    
    // MARK: - Target Actions
    
    @objc private func onLongPressGesture() {
        onLongPress?(elementID)
    }
}
