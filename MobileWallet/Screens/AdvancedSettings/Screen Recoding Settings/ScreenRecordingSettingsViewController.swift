//  ScreenRecordingSettingsViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 23/02/2024
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

import Combine

final class ScreenRecordingSettingsViewController: SecureViewController<ScreenRecordingSettingsView> {

    // MARK: - Properties

    private let model: ScreenRecordingSettingsModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: ScreenRecordingSettingsModel, backButtonType: NavigationBar.BackButtonType) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        mainView.navigationBar.backButtonType = backButtonType
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
    }

    // MARK: - Settings

    private func setupCallbacks() {

        model.$areScreenshotsEnabled
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.update(switchValue: $0) }
            .store(in: &cancellables)

        mainView.onSwitchValueChange = { [weak self] in

            guard self?.model.areScreenshotsEnabled != $0 else { return }

            if $0 {
                self?.showConfirmationDialog()
            } else {
                self?.model.areScreenshotsEnabled = false
            }
        }
    }

    private func showConfirmationDialog() {

        let model = PopUpDialogModel(
            title: localized("screen_recording.pop_up.confirmation.title"),
            message: localized("screen_recording.pop_up.confirmation.message"),
            buttons: [
                PopUpDialogButtonModel(title: localized("common.confirm"), type: .normal, callback: { [weak self] in self?.model.areScreenshotsEnabled = true }),
                PopUpDialogButtonModel(title: localized("common.cancel"), type: .text, callback: { [weak self] in self?.mainView.update(switchValue: false) })
            ],
            hapticType: .none
        )

        PopUpPresenter.showPopUp(model: model)
    }
}
