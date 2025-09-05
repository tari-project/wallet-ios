//  SeedWordsRecoveryProgressModel.swift

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
import UIKit

final class SeedWordsRecoveryProgressModel {
    final class ViewModel {
        @Published var status: String? = localized("restore_from_seed_words.progress_overlay.status.connecting")
        @Published var progress: String?
        @Published var error: MessageModel?
        @Published var isWalletRestored: Bool = false
    }

    // MARK: - Properties

    let viewModel = ViewModel()
    private var cancellables: Set<AnyCancellable> = []
    private var scannedHeight: UInt64?
    private var blockHeight: UInt64?
    private var lastUpdate: Date?

    // MARK: - Initializers

    init() {
        registerOnRestoreProgressCallbacks()
    }

    // MARK: - Setups

    private func registerOnRestoreProgressCallbacks() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                // Only start recovery if it's not already in progress
                if !Tari.mainWallet.recovery.isInProgress && self.viewModel.isWalletRestored == false {
                    self.startRestoringWallet()
                }
            }
            .store(in: &cancellables)

        Tari.mainWallet.recovery.$status
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(restoreStatus: $0) }
            .store(in: &cancellables)

        Tari.mainWallet.connectionCallbacks.$scannedHeight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.scannedHeight = $0
                self?.handleWalletHeightUpdate()
            }
            .store(in: &cancellables)

        Tari.mainWallet.connectionCallbacks.$blockHeight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.blockHeight = $0 }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func startRestoringWallet() {
        guard (try? Tari.mainWallet.recovery.startRecovery()) == true else {
            return handleStartRecoveryFailure()
        }
        Tari.shared.isDisconnectionDisabled = true
    }

    // MARK: - Handlers

    private func handle(restoreStatus: RestoreWalletStatus) {
        switch restoreStatus {
        case .progress:
            () // handled via more reliable scannedHeight observation
        case .completed:
            handleRecoveryComplete()
        case let .scanningRoundFailed(attempt, maxAttempts):
            viewModel.status = localized("restore_from_seed_words.progress_overlay.status.connecting")
            viewModel.progress = localized("restore_from_seed_words.progress_overlay.progress.connection_failed", arguments: attempt + 1, maxAttempts + 1)
            viewModel.error = nil
        case .unknown:
            viewModel.error = MessageModel(
                title: localized("restore_from_seed_words.progress_overlay.error.title"),
                message: localized("restore_from_seed_words.progress_overlay.error.description.connection_failed"),
                type: .error
            )
        }
    }
    
    private func handleWalletHeightUpdate() {
        guard let scannedHeight, let blockHeight, 0 < blockHeight else { return }
        if scannedHeight == blockHeight {
            handleRecoveryComplete()
        } else {
            handleProgress(Double(scannedHeight) / Double(blockHeight) * 100.0)
        }
    }
    
    private func handleProgress(_ percentValue: Double) {
        viewModel.status = localized("restore_from_seed_words.progress_overlay.status.progress")
        viewModel.progress = String(format: "%.1f%%", percentValue)
        viewModel.error = nil
        lastUpdate = .now
        
        Task(after: 10) { [weak self] in
            // if the restore got stuck, try to reconnect
            if let lastUpdate = self?.lastUpdate, lastUpdate.addingTimeInterval(9) < .now {
                Logger.log(message: "Restore - Attrmpting wallet reconnect", domain: .general, level: .verbose)
                Tari.shared.reconnect()
                self?.lastUpdate = nil
            }
        }
    }
    
    private func handleRecoveryComplete() {
        Tari.shared.isDisconnectionDisabled = false
        viewModel.isWalletRestored = true
    }

    private func handleStartRecoveryFailure() {
        viewModel.error = MessageModel(
            title: localized("restore_from_seed_words.progress_overlay.error.title"),
            message: localized("restore_from_seed_words.progress_overlay.error.description.unknown_error"),
            type: .error
        )
    }
}
