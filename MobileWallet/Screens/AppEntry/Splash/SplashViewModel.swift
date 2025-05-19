//  SplashViewModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 21/07/2022
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

struct PaperWalletRecoveryData {
    let cipher: String
    let passphrase: String
}

final class SplashViewModel {

    private enum InternalError: Error {
        case disconnectedFromTor
    }

    enum Status {
        case idle
        case working
        case success
        case successRestored
        case successSync
    }

    enum StatusRepresentation {
        case content
        case logo
    }

    struct StatusModel {
        let status: Status
        let statusRepresentation: StatusRepresentation
    }

    // MARK: - View Model

    @Published private(set) var status: StatusModel?
    @Published private(set) var networkName: String?
    @Published private(set) var appVersion: String?
    @Published private(set) var allNetworkNames: [String] = []
    @Published private(set) var isWalletExist: Bool = false
    @Published private(set) var isRecoveryInProgress: Bool = false
    @Published private(set) var errorMessage: MessageModel?

    // MARK: - Properties

    private let recoveryManager = SeedWordsWalletRecoveryManager()
    private var isWalletConnected: Bool
    private var paperWalletRecoveryData: PaperWalletRecoveryData?
    private var recoveryMode: RecoveryMode = .none
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    enum RecoveryMode {
        case seedPhrase
        case paperWallet
        case none
    }

    init(isWalletConnected: Bool, paperWalletRecoveryData: PaperWalletRecoveryData?, recoveryMode: RecoveryMode = .none) {
        self.isWalletConnected = isWalletConnected
        self.paperWalletRecoveryData = paperWalletRecoveryData
        self.recoveryMode = recoveryMode
        status = StatusModel(status: .idle, statusRepresentation: Tari.shared.wallet(.main).isWalletDBExist ? .logo : .content)
        setupCallbacks()
        setupData()
        StagedWalletSecurityManager.shared.stop()
    }

    // MARK: - Setups

    private func setupCallbacks() {
        NetworkManager.shared.$selectedNetwork
            .map(\.fullPresentedName)
            .sink { [weak self] in self?.networkName = $0 }
            .store(in: &cancellables)

        NetworkManager.shared.$selectedNetwork
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.isWalletExist = Tari.shared.wallet(.main).isWalletDBExist }
            .store(in: &cancellables)

        $isWalletExist
            .dropFirst()
            .filter { !$0 }
            .sink { _ in BackupManager.shared.password = nil }
            .store(in: &cancellables)
    }

    private func setupData() {
        appVersion = AppVersionFormatter.version
        allNetworkNames = [NetworkManager.defaultNetwork.name]
    }

    // MARK: - View Model Actions

    func selectNetwork(onIndex index: Int) {
//        NetworkManager.shared.selectedNetwork = TariNetwork.all[index]
    }

    func openWalletIfExists() -> Bool {
        if Tari.shared.wallet(.main).isWalletDBExist {
            openWallet()
            return true
        } else {
            return false
        }
    }

    func recoverWalletIfNeeded() -> Bool {
        guard let paperWalletRecoveryData else { return false }
        recoveryManager.recover(wallet: .main, cipher: paperWalletRecoveryData.cipher, passphrase: paperWalletRecoveryData.passphrase, customBaseNodeHex: nil, customBaseNodeAddress: nil)
        isRecoveryInProgress = true
        return isRecoveryInProgress
    }

    func deleteWallet() {
        Tari.shared.delete(wallet: .main)
        Tari.shared.canAutomaticalyReconnectWallet = false
        status = StatusModel(status: .idle, statusRepresentation: .content)
        isWalletExist = Tari.shared.wallet(.main).isWalletDBExist
    }

    // MARK: - Actions

    public func createWallet() {
        if status?.status == .working { return }
        Task {
            do {
                status = StatusModel(status: .working, statusRepresentation: .content)
                try await connectToWallet(isWalletConnected: false)
                status = StatusModel(status: .success, statusRepresentation: .content)
            } catch {
                handle(error: error)
            }

        }
    }

    private func openWallet() {
        Task {
            do {
                let statusRepresentation = status?.statusRepresentation ?? .content
                status = StatusModel(status: .working, statusRepresentation: statusRepresentation)

                guard await validateWallet() else {
                    self.deleteWallet()
                    return
                }

                try await connectToWallet(isWalletConnected: isWalletConnected)
                isWalletConnected = false

                var openStatus = Status.success
                if recoveryMode == .paperWallet {
                    openStatus = .successSync
                } else if recoveryMode == .seedPhrase {
                    openStatus = .successRestored
                }
                status = StatusModel(status: openStatus, statusRepresentation: statusRepresentation)
            } catch {
                self.handle(error: error)
            }
        }
    }

    private func validateWallet() async -> Bool {
        await withCheckedContinuation { continuation in
            MigrationManager.validateWalletVersion { continuation.resume(returning: $0) }
        }
    }

    private func connectToWallet(isWalletConnected: Bool) async throws {

        if !isWalletConnected {
            try await Tari.shared.start(wallet: .main)
        }

        try Tari.shared.wallet(.main).keyValues.set(key: .network, value: NetworkManager.shared.selectedNetwork.name)
        Tari.shared.canAutomaticalyReconnectWallet = true
    }

    private func handle(error: Error) {

        status = StatusModel(status: .idle, statusRepresentation: .content)

        guard let error = error as? InternalError else {
            let message = ErrorMessageManager.errorMessage(forError: error)
            errorMessage = MessageModel(title: localized("splash.wallet_error.title"), message: message, type: .error)
            return
        }

        switch error {
        case .disconnectedFromTor:
            errorMessage = MessageModel(title: localized("tor.error.title"), message: localized("tor.error.description"), type: .error)
        }
    }
}
