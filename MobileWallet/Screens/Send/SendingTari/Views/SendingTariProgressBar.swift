//  SendingTariProgressBar.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 03/02/2022
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

final class SendingTariProgressBar: UIView {
    
    // MARK: - Subviews
    
    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 6.0
        view.distribution = .fillEqually
        return view
    }()
    
    // MARK: - Properties
    
    private(set) var currentStep: Int = 0
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    func update(sections: Int) {
        stackView.arrangedSubviews.forEach(stackView.removeArrangedSubview)
        (0..<sections).forEach { _ in self.stackView.addArrangedSubview(ProgressBar()) }
    }
    
    private func setupConstraints() {
        
        addSubview(stackView)
        
        let constraints = [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Actions
    
    func update(state: ProgressBar.State, forSection section: Int, completion: (() -> Void)?) {
        progressBar(forSection: section)?.update(state: state, completion: completion)
    }
    
    func state(forSection section: Int) -> ProgressBar.State? {
        progressBar(forSection: section)?.state
    }
    
    // MARK: - Helpers
    
    private func progressBar(forSection section: Int) -> ProgressBar? {
        guard stackView.arrangedSubviews.count > section else { return nil }
        return stackView.arrangedSubviews[section] as? ProgressBar
    }
}
