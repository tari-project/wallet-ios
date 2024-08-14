//  PopUpNetworkStatusContentView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 15/07/2022
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

final class PopUpNetworkStatusContentView: DynamicThemeView {

    // MARK: - Subviews

    @View private var topRowStackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .equalSpacing
        view.spacing = 36.0
        return view
    }()

    @View private var bottomRowStackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .equalSpacing
        view.spacing = 36.0
        return view
    }()

    @View private var columnStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .equalSpacing
        view.spacing = 20.0
        return view
    }()

    @View private var networkStatusView: StatusView = {
        let view = StatusView()
        view.update(icon: .Icons.ConnectionDetails.internet)
        return view
    }()

    @View private var torStatusView: StatusView = {
        let view = StatusView()
        view.update(icon: .Icons.ConnectionDetails.tor)
        return view
    }()

    @View private var baseNodeConnectionStatusView: StatusView = {
        let view = StatusView()
        view.update(icon: .Icons.Settings.baseNode)
        return view
    }()

    @View private var baseNodeSyncStatusView: StatusView = {
        let view = StatusView()
        view.update(icon: .Icons.ConnectionDetails.sync)
        return view
    }()

    @View private var chainTipLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.normalFont = .Avenir.medium.withSize(14.0)
        view.boldFont = .Avenir.heavy.withSize(14.0)
        view.separator = " "
        view.textAlignment = .center
        return view
    }()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [columnStackView, chainTipLabel].forEach(addSubview)
        [topRowStackView, bottomRowStackView].forEach(columnStackView.addArrangedSubview)
        [networkStatusView, torStatusView].forEach(topRowStackView.addArrangedSubview)
        [baseNodeConnectionStatusView, baseNodeSyncStatusView].forEach(bottomRowStackView.addArrangedSubview)

        let constraints = [
            columnStackView.topAnchor.constraint(equalTo: topAnchor),
            columnStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            columnStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            columnStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            chainTipLabel.topAnchor.constraint(equalTo: columnStackView.bottomAnchor, constant: 20.0),
            chainTipLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            chainTipLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            chainTipLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        chainTipLabel.textColor = theme.text.body
    }

    func updateNetworkStatus(text: String, status: StatusView.Status) {
        networkStatusView.update(text: text, status: status)
    }

    func updateTorStatus(text: String, status: StatusView.Status) {
        torStatusView.update(text: text, status: status)
    }

    func updateBaseNodeConnectionStatus(text: String, status: StatusView.Status) {
        baseNodeConnectionStatusView.update(text: text, status: status)
    }

    func updateBaseNodeSyncStatus(text: String, status: StatusView.Status) {
        baseNodeSyncStatusView.update(text: text, status: status)
    }

    func update(chainTipSuffix: String) {
        chainTipLabel.textComponents = [
            StylizedLabel.StylizedText(text: localized("connection_status.popUp.label.chain_tip.prefix"), style: .bold),
            StylizedLabel.StylizedText(text: chainTipSuffix, style: .normal)
        ]
    }
}

final class StatusView: DynamicThemeView {

    enum Status {
        case error
        case warning
        case ok
    }

    // MARK: - Subviews

    @View private var iconViewBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 24.0
        return view
    }()

    @View private var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private var statusDotView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 7.0
        return view
    }()

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(14.0)
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    // MARK: - Properties

    private var status: Status = .error

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [iconViewBackgroundView, statusDotView, label].forEach(addSubview)
        iconViewBackgroundView.addSubview(iconView)

        let constraints = [
            iconViewBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            iconViewBackgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconViewBackgroundView.widthAnchor.constraint(equalToConstant: 46.0),
            iconViewBackgroundView.heightAnchor.constraint(equalToConstant: 46.0),
            iconView.topAnchor.constraint(equalTo: iconViewBackgroundView.topAnchor, constant: 11.0),
            iconView.leadingAnchor.constraint(equalTo: iconViewBackgroundView.leadingAnchor, constant: 11.0),
            iconView.trailingAnchor.constraint(equalTo: iconViewBackgroundView.trailingAnchor, constant: -11.0),
            iconView.bottomAnchor.constraint(equalTo: iconViewBackgroundView.bottomAnchor, constant: -11.0),
            label.topAnchor.constraint(equalTo: iconViewBackgroundView.bottomAnchor, constant: 5.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            statusDotView.topAnchor.constraint(equalTo: iconViewBackgroundView.topAnchor),
            statusDotView.trailingAnchor.constraint(equalTo: iconViewBackgroundView.trailingAnchor),
            statusDotView.widthAnchor.constraint(equalToConstant: 14.0),
            statusDotView.heightAnchor.constraint(equalToConstant: 14.0),
            widthAnchor.constraint(equalToConstant: 110.0),
            heightAnchor.constraint(equalToConstant: 94.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        iconViewBackgroundView.backgroundColor = theme.backgrounds.primary
        iconViewBackgroundView.apply(shadow: theme.shadows.box)
        iconView.tintColor = theme.icons.default
        label.textColor = theme.text.body

        updateBackgroundColor(theme: theme)
    }

    func update(text: String, status: Status) {
        label.text = text
        self.status = status
        updateBackgroundColor(theme: theme)
    }

    func update(icon: UIImage?) {
        iconView.image = icon
    }

    private func updateBackgroundColor(theme: ColorTheme) {
        switch status {
        case .error:
            statusDotView.backgroundColor = theme.system.red
        case .warning:
            statusDotView.backgroundColor = theme.system.orange
        case .ok:
            statusDotView.backgroundColor = theme.system.green
        }
    }
}
