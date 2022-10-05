//  HomeView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 04/08/2021
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
import Combine

final class HomeView: UIView {

    // MARK: - Subviews

    let dimmingLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.black.cgColor
        layer.opacity = 0.0
        return layer
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.locations = [0.0, 0.06, 0.18, 0.3, 0.39, 0.51, 0.68, 0.89, 1.0]
        layer.colors = [
            Theme.shared.colors.auroraGradient1!.cgColor,
            Theme.shared.colors.auroraGradient2!.cgColor,
            Theme.shared.colors.auroraGradient3!.cgColor,
            Theme.shared.colors.auroraGradient4!.cgColor,
            Theme.shared.colors.auroraGradient5!.cgColor,
            Theme.shared.colors.auroraGradient6!.cgColor,
            Theme.shared.colors.auroraGradient7!.cgColor,
            Theme.shared.colors.auroraGradient8!.cgColor,
            Theme.shared.colors.auroraGradient9!.cgColor
        ]
        return layer
    }()

    private let balanceTitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("home.available_balance")
        view.font = Theme.shared.fonts.homeScreenTotalBalanceLabel
        view.textColor = Theme.shared.colors.homeScreenTotalBalanceLabel
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let tariIconView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.currencySymbol
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let balanceValueLabel: AnimatedBalanceLabel = {
        let view = AnimatedBalanceLabel()
        view.animationSpeed = .slow
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()

    private let avaiableFoundsTitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("home.label.spendable")
        view.font = Theme.shared.fonts.homeScreenTotalBalanceLabel
        view.textColor = Theme.shared.colors.homeScreenTotalBalanceLabel
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let avaiableFoundsValueLabel: AnimatedBalanceLabel = {
        let view = AnimatedBalanceLabel()
        view.animationSpeed = .slow
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()

    let amountHelpButton: BaseButton = {
        let view = BaseButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
        view.tintColor = .white
        return view
    }()
    
    @View private var connectionStatusButton: BaseButton = BaseButton()
    
    @View var utxosWalletButton: BaseButton = {
        let view = BaseButton()
        view.setImage(Theme.shared.images.homeWalletIcon, for: .normal)
        view.tintColor = .tari.white
        return view
    }()

    let topToolbar: HomeViewToolbar = {
        let view = HomeViewToolbar()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties
    
    var connectionStatusIcon: UIImage? {
        get { connectionStatusButton.image(for: .normal) }
        set {
            UIView.transition(with: connectionStatusButton, duration: 0.5, options: .transitionCrossDissolve) {
                self.connectionStatusButton.setImage(newValue, for: .normal)
            }
        }
    }

    var onOnCloseButtonTap: (() -> Void)? {
        get { topToolbar.onOnCloseButtonTap }
        set { topToolbar.onOnCloseButtonTap = newValue }
    }
    
    var onConnectionStatusButtonTap: (() -> Void)? {
        get { connectionStatusButton.onTap }
        set { connectionStatusButton.onTap = newValue }
    }

    var onAmountHelpButtonTap: (() -> Void)?

    private(set) var toolbarBottomConstraint: NSLayoutConstraint?
    private(set) var toolbarHeightConstraint: NSLayoutConstraint?

    // MARK: - Initializers

    init() {
        super.init(frame: .zero)
        setupLayers()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    func updateViewsOrder() {
        bringSubviewToFront(topToolbar)
    }

    private func setupLayers() {
        [gradientLayer, dimmingLayer].forEach(layer.addSublayer)
    }

    private func setupConstraints() {

        [balanceTitleLabel, tariIconView, balanceValueLabel, avaiableFoundsTitleLabel, avaiableFoundsValueLabel, amountHelpButton, connectionStatusButton, utxosWalletButton, topToolbar].forEach(addSubview)

        let toolbarBottomConstraint = topToolbar.bottomAnchor.constraint(equalTo: topAnchor)
        let toolbarHeightConstraint = topToolbar.heightAnchor.constraint(equalToConstant: 0.0)

        self.toolbarBottomConstraint = toolbarBottomConstraint
        self.toolbarHeightConstraint = toolbarHeightConstraint

        let constraints = [
            balanceTitleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 6.0),
            balanceTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30.0),
            balanceTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            tariIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30.0),
            tariIconView.heightAnchor.constraint(equalToConstant: 16.0),
            tariIconView.widthAnchor.constraint(equalToConstant: 16.0),
            tariIconView.centerYAnchor.constraint(equalTo: balanceValueLabel.centerYAnchor),
            balanceValueLabel.topAnchor.constraint(equalTo: balanceTitleLabel.bottomAnchor, constant: -7.0),
            balanceValueLabel.leadingAnchor.constraint(equalTo: tariIconView.trailingAnchor, constant: 8.0),
            balanceValueLabel.trailingAnchor.constraint(equalTo: utxosWalletButton.leadingAnchor, constant: -8.0),
            avaiableFoundsTitleLabel.topAnchor.constraint(equalTo: balanceValueLabel.bottomAnchor, constant: -1.0),
            avaiableFoundsTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30.0),
            avaiableFoundsValueLabel.topAnchor.constraint(equalTo: avaiableFoundsTitleLabel.bottomAnchor),
            avaiableFoundsValueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30.0),
            avaiableFoundsValueLabel.trailingAnchor.constraint(equalTo: utxosWalletButton.leadingAnchor, constant: -8.0),
            amountHelpButton.leadingAnchor.constraint(equalTo: avaiableFoundsTitleLabel.trailingAnchor, constant: 4.0),
            amountHelpButton.centerYAnchor.constraint(equalTo: avaiableFoundsTitleLabel.centerYAnchor),
            amountHelpButton.heightAnchor.constraint(equalToConstant: 18.0),
            amountHelpButton.widthAnchor.constraint(equalToConstant: 18.0),
            connectionStatusButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -26.0),
            connectionStatusButton.centerYAnchor.constraint(equalTo: balanceValueLabel.centerYAnchor),
            connectionStatusButton.heightAnchor.constraint(equalToConstant: 22.0),
            connectionStatusButton.widthAnchor.constraint(equalToConstant: 22.0),
            utxosWalletButton.topAnchor.constraint(equalTo: connectionStatusButton.bottomAnchor, constant: 8.0),
            utxosWalletButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -26.0),
            utxosWalletButton.heightAnchor.constraint(equalToConstant: 22.0),
            utxosWalletButton.widthAnchor.constraint(equalToConstant: 22.0),
            topToolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            topToolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbarBottomConstraint,
            toolbarHeightConstraint
        ]

        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        amountHelpButton.onTap = { [weak self] in
            self?.onAmountHelpButtonTap?()
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        dimmingLayer.frame = layer.bounds
        gradientLayer.frame = layer.bounds
    }
}
