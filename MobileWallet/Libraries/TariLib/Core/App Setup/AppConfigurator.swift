//  AppConfigurator.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 11/10/2022
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

import Combine

final class AppConfigurator {

    // MARK: - Properties

    static let shared = AppConfigurator()

    var isCrashLoggerEnabled: Bool {
        get { crashLogger.isEnabled ?? false }
        set { crashLogger.isEnabled = newValue }
    }

    private let crashLogger = CrashLogger()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    private init() {}

    // MARK: - Actions

    func configure() {
        configureLoggers()
        configureManagers()
        configureCallbacks()
    }

    private func configureLoggers() {
        switch TariSettings.shared.environment {
        case .debug:
            Logger.attach(logger: ConsoleLogger())
        case .testflight, .production:
            break
        }

        Logger.attach(logger: FileLogger())
        Logger.attach(logger: crashLogger)

        crashLogger.configure()
    }

    private func configureManagers() {
        BackupManager.shared.configure()
        StatusLoggerManager.shared.configure()
        DataFlowManager.shared.configure()
        LocalNotificationsManager.shared.configure()
        ScreenshotPopUpHandler.shared.configure()
    }

    private func configureCallbacks() {

        Tari.shared.$torError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(torError: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Handlers

    private func handle(torError: TorError) {

        switch torError {
        case let .connectionFailed(error):
            guard let posixError = error as? PosixError else { return }
            handle(posixError: posixError)
        case .authenticationFailed, .missingController, .missingCookie, .unknown:
            break
        }
    }

    private func handle(posixError: PosixError) {

        switch posixError {
        case .connectionRefused:
            ToastPresenter.show(title: localized("custom_bridges.toast.error.connection_refused"), duration: 5.0)
        default:
            break
        }
    }
}
