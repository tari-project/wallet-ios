//  TariValidationService.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 04/10/2022
	Using Swift 5.0
	Running on macOS 12.4

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

final class TariValidationService: CoreTariService {

    enum SyncStatus {
        case idle
        case syncing
        case synced
        case failed
    }

    private enum TransactionType {
        case txo
        case tx
    }

    // MARK: - Properties

    @Published private(set) var status: SyncStatus = .idle

    private var unverifiedTransactions: Set<TransactionType> = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialiser

    override init(walletManager: FFIWalletHandler, services: MainServiceable) {
        super.init(walletManager: walletManager, services: services)
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        WalletCallbacksManager.shared.transactionOutputValidation
            .filter { $0.status != .alreadyBusy }
            .map { $0.status == .success }
            .sink { [weak self] in self?.handleTransactionValidation(type: .txo, isSuccess: $0) }
            .store(in: &cancellables)

        WalletCallbacksManager.shared.transactionValidation
            .filter { $0.status != .alreadyBusy }
            .map { $0.status == .success }
            .sink { [weak self] in self?.handleTransactionValidation(type: .tx, isSuccess: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func reset() {
        unverifiedTransactions.removeAll()
        status = .idle
    }

    func sync() throws {
        unverifiedTransactions = [.tx, .txo]
        _ = try walletManager.startTransactionOutputValidation()
        _ = try walletManager.startTransactionValidation()
        status = .syncing
    }

    // MARK: - Handlers

    private func handleTransactionValidation(type: TransactionType, isSuccess: Bool) {

        guard !unverifiedTransactions.isEmpty else { return }

        guard isSuccess else {
            unverifiedTransactions.removeAll()
            status = .failed
            return
        }

        unverifiedTransactions.remove(type)

        guard unverifiedTransactions.isEmpty else { return }
        status = .synced
    }
}
