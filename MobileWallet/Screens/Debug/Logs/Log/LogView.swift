//  LogView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 17/10/2022
	Using Swift 5.0
	Running on macOS 12.6

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
import Lottie

final class LogView: BaseNavigationContentView {
    
    // MARK: - Subviews
    
    @View private(set) var tableView: UITableView = {
        let view = UITableView()
        view.rowHeight = UITableView.automaticDimension
        return view
    }()
    
    @View private var overlayBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .tari.white?.withAlphaComponent(0.5)
        view.alpha = 0.0
        return view
    }()
    
    @View private var spinnerView: AnimationView = {
        let view = AnimationView()
        view.backgroundBehavior = .pauseAndRestore
        view.animation = Animation.named(.pendingCircleAnimation)
        view.loopMode = .loop
        view.play()
        return view
    }()
    
    // MARK: - Properties
    
    var title: String? {
        get { navigationBar.title }
        set { navigationBar.title = newValue }
    }
    
    var isSpinnerVisible: Bool = false {
        didSet { updateSpinnerState() }
    }
    
    var onFilterButtonTap: (() -> Void)?
    
    // MARK: - Initialisers
    
    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        backgroundColor = .tari.white
        navigationBar.rightButton.setImage(Theme.shared.images.utxoFaucet, for: .normal)
        navigationBar.rightButton.tintColor = .tari.greys.black
    }
    
    private func setupConstraints() {
        
        [tableView, overlayBackgroundView].forEach { addSubview($0) }
        overlayBackgroundView.addSubview(spinnerView)
        
        let constraints = [
            tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            overlayBackgroundView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            overlayBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            spinnerView.centerXAnchor.constraint(equalTo: overlayBackgroundView.centerXAnchor),
            spinnerView.centerYAnchor.constraint(equalTo: overlayBackgroundView.centerYAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        navigationBar.rightButtonAction = { [weak self] in
            self?.onFilterButtonTap?()
        }
    }
    
    // MARK: - Actions
    
    private func updateSpinnerState() {
        UIView.animate(withDuration: 0.3) {
            self.overlayBackgroundView.alpha = self.isSpinnerVisible ? 1.0 : 0.0
        }
    }
}
