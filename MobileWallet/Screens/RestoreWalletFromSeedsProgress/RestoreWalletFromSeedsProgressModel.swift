//  RestoreWalletFromSeedsProgressModel.swift

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

import Combine

final class RestoreWalletFromSeedsProgressModel {

    final class ViewModel {
        @Published var status: String? = localized("restore_from_seed_words.progress_overlay.status.connecting")
        @Published var progress: String?
        @Published var error: SimpleErrorModel?
        @Published var isWalletRestored: Bool = false
    }

    // MARK: - Properties

    let viewModel = ViewModel()
    private var cancelables: Set<AnyCancellable> = []

    // MARK: - Initializers

    init() {
        registerOnRestoreProgressCallbacks()
    }

    // MARK: - Setups

    private func registerOnRestoreProgressCallbacks() {
        TariEventBus
            .events(forType: .restoreWalletStatusUpdate)
            .compactMap { $0.object as? RestoreWalletStatus }
            .sink { [weak self] in self?.handle(restoreStatus: $0) }
            .store(in: &cancelables)
    }

    // MARK: - Actions

    func startRestoringWallet() {
        do {
            let result = try TariLib.shared.tariWallet?.startRecovery()
            if result == false {
                handleStartRecoveryFailure()
            }
        } catch {
            handleStartRecoveryFailure()
        }
    }

    // MARK: - Handlers

    private func handle(restoreStatus: RestoreWalletStatus) {

        switch restoreStatus {
        case .connectingToBaseNode:
            return
        case .connectedToBaseNode:
            viewModel.status = localized("restore_from_seed_words.progress_overlay.status.connected")
            viewModel.progress = nil
            viewModel.error = nil
        case let .connectionFailed(attempt, maxAttempts), let .scanningRoundFailed(attempt, maxAttempts):
            viewModel.status = localized("restore_from_seed_words.progress_overlay.status.connecting")
            viewModel.progress = localized("restore_from_seed_words.progress_overlay.progress.connection_failed", arguments: attempt + 1, maxAttempts + 1)
            viewModel.error = nil
        case let .progress(restoredUTXOs, totalNumberOfUTXOs):
            let value = Double(restoredUTXOs) / Double(totalNumberOfUTXOs) * 100.0
            viewModel.status =  localized("restore_from_seed_words.progress_overlay.status.progress")
            viewModel.progress = String(format: "%.1f%%", value)
            viewModel.error = nil
        case .completed:
            viewModel.isWalletRestored = true
        case .recoveryFailed, .unknown:
            viewModel.error = SimpleErrorModel(
                title: localized("restore_from_seed_words.progress_overlay.error.title"),
                description: localized("restore_from_seed_words.progress_overlay.error.description.connection_failed")
            )
        }
    }

    private func handleStartRecoveryFailure() {
        viewModel.error = SimpleErrorModel(
            title: localized("restore_from_seed_words.progress_overlay.error.title"),
            description: localized("restore_from_seed_words.progress_overlay.error.description.unknown_error")
        )
    }
}
