//  AddRecipientSearchView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 25/10/2021
	Using Swift 5.0
	Running on macOS 12.0

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

final class AddRecipientSearchView: UIView {

    // MARK: - Subviews

    @View var textField: UITextField = {
        let view = UITextField()
        view.placeholder = localized("add_recipient.inputbox.placeholder")
        view.font = Theme.shared.fonts.searchContactsInputBoxText
        view.leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 11.0, height: 0.0))
        view.leftViewMode = .always
        view.rightViewMode = .always
        return view
    }()

    @View var qrButton: PulseButton = {
        let view = PulseButton()
        view.setImage(Theme.shared.images.qrButton, for: .normal)
        return view
    }()
    
    @View var yatPreviewButton = PulseButton()
    
    @View private var contentView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        return view
    }()
    
    @View private var previewView = ScrollableLabel()
    
    // MARK: - Properties
    
    var isQrButtonVisible: Bool = true {
        didSet { updateViews() }
    }
    
    var isPreviewButtonVisible: Bool = false {
        didSet { updateViews() }
    }
    
    var previewText: String? {
        didSet { updatePreview() }
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
        backgroundColor = Theme.shared.colors.appBackground
        layer.cornerRadius = 6.0
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        layer.shadowRadius = 6.0
        layer.shadowColor = Theme.shared.colors.defaultShadow?.cgColor
    }
    
    private func setupConstraints() {
        
        [textField, yatPreviewButton, qrButton].forEach(contentView.addArrangedSubview)
        [contentView, previewView].forEach(addSubview)
       
        let constraints = [
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            yatPreviewButton.widthAnchor.constraint(equalToConstant: 44.0),
            qrButton.widthAnchor.constraint(equalToConstant: 44.0),
            previewView.topAnchor.constraint(equalTo: textField.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: textField.bottomAnchor)
        ]
        
        updateViews()
        NSLayoutConstraint.activate(constraints)
    }
    
    private func updateViews() {
        qrButton.isHidden = !isQrButtonVisible
        yatPreviewButton.isHidden = !isPreviewButtonVisible
    }
    
    private func updatePreview() {
        previewView.isHidden = previewText == nil
        previewView.label.text = previewText
        let iconName = previewView.isHidden ? "eye.fill" : "eye.slash.fill"
        yatPreviewButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
}

