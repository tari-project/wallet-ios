//  PopUpStoreHeaderView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 10/04/2022
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

final class PopUpStoreHeaderView: UIView {
    
    // MARK: - Subviews
    
    @View private var imageView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.storeModal
        view.contentMode = .scaleToFill
        return view
    }()
    
    @View private var label: UILabel = {
        let view = UILabel()
        view.textColor = Theme.shared.colors.feedbackPopupTitle
        view.font = Theme.shared.fonts.feedbackPopupTitle
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()
    
    // MARK: - Initialiserss
    
    init() {
        super.init(frame: .zero)
        setupText()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupText() {
        
        let boldedText = localized("store_modal.title.part.2")
        let text = localized("store_modal.title.part.1", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol) + boldedText
        let title = NSMutableAttributedString(string: text)
        
        if let startIndex = text.indexDistance(of: boldedText) {
            let range = NSRange(location: startIndex, length: boldedText.count)
            title.addAttribute(.font, value: Theme.shared.fonts.feedbackPopupHeavy, range: range)
        }
        
        label.attributedText = title
    }
    
    private func setupConstraints() {
        
        [imageView, label].forEach(addSubview)
        
        let constraints = [
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 180.0),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}
