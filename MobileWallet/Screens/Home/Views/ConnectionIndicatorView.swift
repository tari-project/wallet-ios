//  ConnectionIndicatorView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 07/07/2021
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
import Combine

final class ConnectionIndicatorView: UIControl {

    enum State {
        case connected, connectedWithIssues, disconnected
    }

    // MARK: - Subviews

    private let dotView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties

    var currentState: CurrentValueSubject<State, Never> = CurrentValueSubject(.disconnected)
    var onTap: (() -> Void)?
    private var cancelables = Set<AnyCancellable>()

    // MARK: - Initializers

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setup() {
        setupConstaints()
        setupActions()
        setupFeedbacks()
    }

    private func setupConstaints() {

        addSubview(dotView)

        let constraints = [
            dotView.centerXAnchor.constraint(equalTo: centerXAnchor),
            dotView.centerYAnchor.constraint(equalTo: centerYAnchor),
            dotView.heightAnchor.constraint(equalToConstant: 6.0),
            dotView.widthAnchor.constraint(equalToConstant: 6.0),
            heightAnchor.constraint(equalToConstant: 44.0),
            widthAnchor.constraint(equalToConstant: 44.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupActions() {
        currentState
            .map { $0.color }
            .assign(to: \.backgroundColor, on: dotView)
            .store(in: &cancelables)
    }

    private func setupFeedbacks() {
        addTarget(self, action: #selector(onTouchUpInsideAction), for: .touchUpInside)
    }

    // MARK: - Target-Actions

    @objc private func onTouchUpInsideAction() {
        onTap?()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        dotView.layer.cornerRadius = min(dotView.bounds.width, dotView.bounds.height) / 2.0
    }
}

private extension ConnectionIndicatorView.State {
    var color: UIColor? {
        switch self {
        case .connected:
            return Theme.shared.colors.connectionStatusOk
        case .connectedWithIssues:
            return Theme.shared.colors.connectionStatusWarning
        case .disconnected:
            return Theme.shared.colors.connectionStatusError
        }
    }
}
