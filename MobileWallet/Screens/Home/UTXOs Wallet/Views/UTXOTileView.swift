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

final class UTXOTileView: DynamicThemeCollectionCell {
    
    struct Model: Hashable {
        let uuid: UUID
        let amountText: String
        let hash: String
        let height: CGFloat
        let status: UtxoStatus
        let date: String?
        let isSelectable: Bool
    }
    
    // MARK: - Constants
    
    private let cornerShapeRadius: CGFloat = 26.0
    
    // MARK: - Subviews
    
    @View private var backgroundContentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10.0
        view.clipsToBounds = true
        return view
    }()
    
    @View private var amountContentView = UIView()
    
    @View private var tickView: UTXOsWalletTickButton = {
        let view = UTXOsWalletTickButton()
        view.alpha = 0.0
        return view
    }()
    
    @View private var amountLabel: CurrencyLabelView = {
        let view = CurrencyLabelView()
        view.textColor = .static.white
        view.font = .Avenir.black.withSize(30.0)
        view.secondaryFont = .Avenir.black.withSize(12.0)
        view.separator = Locale.current.decimalSeparator
        view.iconHeight = 13.0
        return view
    }()
    
    @View private var dateLabel: UILabel = {
        let view = UILabel()
        view.textColor = .static.white
        view.font = .Avenir.medium.withSize(12.0)
        return view
    }()
    
    @View private var statusIcon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = .static.white
        return view
    }()
    
    private let cornerRoundedShapeLayer = CAShapeLayer()
    
    // MARK: - Properties
    
    private(set) var elementID: UUID?
    private var colorHash: String?
    private var status: UtxoStatus = .mined
    
    var isTickSelected: Bool = false {
        didSet { update(selectionState: isTickSelected) }
    }
    
    var onTap: ((UUID) -> Void)?
    var onLongPress: ((UUID) -> Void)?
    
    // MARK: - Initialisers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupCallbacks()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    func update(model: Model) {
        elementID = model.uuid
        colorHash = model.hash
        status = model.status
        amountLabel.text = model.amountText
        dateLabel.text = model.date
        statusIcon.image = model.status.icon
        updateViewStatus(theme: theme)
    }
    
    private func setupViews() {
        layer.cornerRadius = 10.0
        contentView.translatesAutoresizingMaskIntoConstraints = false
        backgroundContentView.layer.addSublayer(cornerRoundedShapeLayer)
    }
    
    private func setupConstraints() {
        
        contentView.addSubview(backgroundContentView)
        amountContentView.addSubview(amountLabel)
        [amountContentView, dateLabel, statusIcon, tickView].forEach(backgroundContentView.addSubview)

        let constraints = [
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundContentView.topAnchor.constraint(equalTo: topAnchor, constant: 2.0),
            backgroundContentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2.0),
            backgroundContentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2.0),
            backgroundContentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2.0),
            tickView.topAnchor.constraint(equalTo: backgroundContentView.topAnchor, constant: 10.0),
            tickView.leadingAnchor.constraint(equalTo: backgroundContentView.leadingAnchor, constant: 10.0),
            tickView.heightAnchor.constraint(equalToConstant: 24.0),
            tickView.widthAnchor.constraint(equalToConstant: 24.0),
            amountContentView.topAnchor.constraint(equalTo: backgroundContentView.topAnchor),
            amountContentView.leadingAnchor.constraint(equalTo: backgroundContentView.leadingAnchor),
            amountContentView.trailingAnchor.constraint(equalTo: backgroundContentView.trailingAnchor),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: amountContentView.leadingAnchor, constant: 10.0),
            amountLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountContentView.trailingAnchor, constant: -10.0),
            amountLabel.centerXAnchor.constraint(equalTo: backgroundContentView.centerXAnchor),
            amountLabel.centerYAnchor.constraint(equalTo: backgroundContentView.centerYAnchor),
            dateLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 0.0),
            dateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6.0),
            statusIcon.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6.0),
            statusIcon.heightAnchor.constraint(equalToConstant: 14.0),
            statusIcon.widthAnchor.constraint(equalToConstant: 14.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapGesture))
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressGesture))
        [tapGesture, longPressGesture].forEach(addGestureRecognizer)
    }
    
    // MARK: - Updates
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        updateViewStatus(theme: theme)
        updateSelectionState(theme: theme)
        backgroundColor = theme.backgrounds.primary
    }
    
    private func updateViewStatus(theme: ColorTheme) {
        backgroundContentView.backgroundColor = theme.brand.purple?.colorVariant(text: colorHash ?? "")
        cornerRoundedShapeLayer.fillColor = status.color(theme: theme)?.cgColor
    }
    
    private func updateSelectionState(theme: ColorTheme) {
        let shadow = isTickSelected ? theme.shadows.box : .none
        apply(shadow: shadow)
    }
    
    private func updateCornerShape() {
        
        backgroundContentView.layoutIfNeeded()
        
        let rightOffset = backgroundContentView.bounds.maxX
        let bottomOffset = backgroundContentView.bounds.maxY
        let leftOffset = rightOffset - cornerShapeRadius
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: rightOffset, y: bottomOffset))
        bezierPath.addLine(to: CGPoint(x: leftOffset, y: bottomOffset))
        bezierPath.addArc(withCenter: CGPoint(x: rightOffset, y: bottomOffset), radius: cornerShapeRadius, startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
        bezierPath.close()
        
        cornerRoundedShapeLayer.path = bezierPath.cgPath
    }
    
    private func update(selectionState: Bool) {
        
        UIView.animate(withDuration: 0.3) {
            self.updateSelectionState(theme: self.theme)
        }
        
        tickView.isSelected = selectionState
    }
    
    func updateTickBox(isVisible: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.tickView.alpha = isVisible ? 1.0 : 0.0
        }
    }
    
    func updateBackground(isSemitransparent: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.contentView.alpha = isSemitransparent ? 0.6 : 1.0
        }
    }
    
    // MARK: - Target Actions
    
    @objc private func onTapGesture() {
        guard let elementID = elementID else { return }
        onTap?(elementID)
    }
    
    @objc private func onLongPressGesture() {
        guard let elementID = elementID else { return }
        onLongPress?(elementID)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerShape()
    }
}
