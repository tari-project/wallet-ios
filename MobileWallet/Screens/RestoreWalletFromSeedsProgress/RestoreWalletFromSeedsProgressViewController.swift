//  RestoreWalletFromSeedsProgressViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 27/07/2021
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

final class RestoreWalletFromSeedsProgressViewController: UIViewController {

    // MARK: - Properties

    var onSuccess: (() -> Void)?

    private let mainView = RestoreWalletFromSeedsProgressView()
    private let model = RestoreWalletFromSeedsProgressModel()
    private var cancelables: Set<AnyCancellable> = []

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFeedbacks()
        model.startRestoringWallet()
    }

    // MARK: - Setups

    private func setupFeedbacks() {

        model.viewModel.$status
            .assign(to: \.text, on: mainView.statusLabel)
            .store(in: &cancelables)

        model.viewModel.$progress
            .assign(to: \.text, on: mainView.progressLabel)
            .store(in: &cancelables)

        model.viewModel.$error
            .sink { [weak self] in self?.handle(errorModel: $0) }
            .store(in: &cancelables)

        model.viewModel.$isWalletRestored
            .sink { [weak self] in self?.handle(isWalletRestored: $0) }
            .store(in: &cancelables)
    }

    // MARK: - Actions

    private func handle(errorModel: MessageModel?) {
        guard let errorModel = errorModel else { return }
        PopUpPresenter.showMessageWithCloseButton(message: errorModel) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    private func handle(isWalletRestored: Bool) {
        guard isWalletRestored else { return }
        ToastPresenter.show(title: localized("restore_from_seed_words.progress_overlay.success"))
        onSuccess?()
    }
}
