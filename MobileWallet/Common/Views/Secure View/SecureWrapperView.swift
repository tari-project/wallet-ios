//  SecureWrapperView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 13/02/2024
	Using Swift 5.0
	Running on macOS 14.2

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

import TariCommon
import Combine

enum ScreenshotPreventionStatus {
    case enforced
    case turnedOff
    case automatic
}

final class SecureWrapperView<MainView: UIView>: UIView {

    // MARK: - Subviews

    @TariView private(set) var view: MainView

    @TariView private var textField: UITextField = {
        let view = UITextField()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }()

    private var contentView: UIView? { textField.subviews.first { type(of: $0).description().contains("CanvasView") }}

    // MARK: - Properties

    @Published var screenshotPreventionStatus: ScreenshotPreventionStatus = .automatic
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    convenience init() {
        self.init(mainView: MainView())
    }

    init(mainView: MainView) {
        self.view = mainView
        super.init(frame: .zero)
        setupViews()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {

        guard let contentView else {
            Logger.log(message: "No secure content view", domain: .userInterface, level: .warning)
            return
        }

        addSubview(contentView)

        if #unavailable(iOS 16.0) {
            contentView.isUserInteractionEnabled = true
        }

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)

        let constraints = [
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        Publishers.CombineLatest(SecurityManager.shared.$areScreenshotsDisabled, $screenshotPreventionStatus)
            .sink { [weak self] in self?.handle(areScreenshotsDisabled: $0, screenshotPreventionStatus: $1) }
            .store(in: &cancellables)
    }

    private func handle(areScreenshotsDisabled: Bool, screenshotPreventionStatus: ScreenshotPreventionStatus) {

        guard screenshotPreventionStatus == .automatic else {
            textField.isSecureTextEntry = screenshotPreventionStatus == .enforced
            return
        }

        textField.isSecureTextEntry = areScreenshotsDisabled
    }
}
