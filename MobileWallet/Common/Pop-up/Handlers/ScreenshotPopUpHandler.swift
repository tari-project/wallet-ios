//  ScreenshotPopUpHandler.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 24/06/2024
	Using Swift 5.0
	Running on macOS 14.4

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

final class ScreenshotPopUpHandler {

    // MARK: - Constants

    private let disabledViewControllers = [SendingTariViewController.self, YatTransactionViewController.self]

    // MARK: - Properties

    static let shared = ScreenshotPopUpHandler()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    private init() {}

    // MARK: - Actions

    func configure() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .receive(on: DispatchQueue.main)
            .filter { [weak self] _ in self?.canShowPopup() ?? false }
            .sink { [weak self] _ in self?.showPopUp() }
            .store(in: &cancellables)
    }

    private func showPopUp() {

        let model = PopUpDialogModel(
            title: localized("screen_recording.pop_up.title"),
            message: localized("screen_recording.pop_up.message"),
            buttons: [
                PopUpDialogButtonModel(title: localized("screen_recording.pop_up.button.ok"), type: .normal),
                PopUpDialogButtonModel(title: localized("screen_recording.pop_up.button.enable"), type: .text, callback: { [weak self] in self?.showScreenShotSettingsScreen() })
            ],
            hapticType: .error
        )

        Task { @MainActor in
            PopUpPresenter.showPopUp(model: model)
        }
    }

    private func showScreenShotSettingsScreen() {
        let controller = ScreenRecordingSettingsConstructor.buildScene(backButtonType: .close)
        AppRouter.present(controller: controller)
    }

    // MARK: - Handlers

    func canShowPopup() -> Bool {

        guard SecurityManager.shared.areScreenshotsDisabled else { return false }

        var topController = UIApplication.shared.topController

        if let navigationController = topController as? UINavigationController {
            topController = navigationController.visibleViewController
        }

        guard let topController else { return false }
        return !disabledViewControllers.contains { topController.isKind(of: $0) }
    }
}
