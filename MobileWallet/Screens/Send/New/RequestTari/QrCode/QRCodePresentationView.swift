//  QRCodePresentationView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 18/01/2022
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

final class QRCodePresentationView: UIView {
    
    // MARK: - Subviews
    
    @View private var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.shared.colors.appBackground
        view.layer.cornerRadius = 26.0
        return view
    }()
    
    @View var qrCodeView: QRCodeView = {
        let view = QRCodeView()
        view.apply(shadow: Shadow(color: .black, opacity: 0.1, radius: 13.5, offset: CGSize(width: 6.75, height: 6.75)))
        return view
    }()
    
    @View var shareButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("request.qr_code.buttons.share"), for: .normal)
        return view
    }()
    
    @View var closeButton: TextButton = {
        let view = TextButton()
        view.setTitle(localized("request.qr_code.buttons.close"), for: .normal)
        view.setTitleColor(Theme.shared.colors.refreshViewLabelLoading, for: .normal)
        return view
    }()
    
    // MARK: - Properties
    
    private var contentViewTopConstraint: NSLayoutConstraint?
    private var contentViewBottomConstraint: NSLayoutConstraint?
    
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
        backgroundColor = .black.withAlphaComponent(0.3)
    }
    
    private func setupConstraints() {
        
        addSubview(contentView)
        [qrCodeView, shareButton, closeButton].forEach(contentView.addSubview)
        
        let contentViewTopConstraint = contentView.topAnchor.constraint(equalTo: bottomAnchor)
        
        self.contentViewTopConstraint = contentViewTopConstraint
        contentViewBottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18.0)
        
        let constraints = [
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14.0),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14.0),
            contentViewTopConstraint,
            qrCodeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
            qrCodeView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            qrCodeView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.667),
            qrCodeView.heightAnchor.constraint(equalTo: qrCodeView.widthAnchor),
            shareButton.topAnchor.constraint(equalTo: qrCodeView.bottomAnchor, constant: 30.0),
            shareButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 165.0),
            closeButton.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 10.0),
            closeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            closeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15.0),
            closeButton.widthAnchor.constraint(equalToConstant: 165.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Actions
    
    func showContent() {
        
        contentViewTopConstraint?.isActive = false
        contentViewBottomConstraint?.isActive = true
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.layoutIfNeeded()
        }
    }
    
    func hideContent() {
        
        contentViewBottomConstraint?.isActive = false
        contentViewTopConstraint?.isActive = true
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.layoutIfNeeded()
        }
    }
}
