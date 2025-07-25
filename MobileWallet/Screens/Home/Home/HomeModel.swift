//  HomeModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 22/06/2023
	Using Swift 5.0
	Running on macOS 13.4

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
import TariCommon

final class HomeModel {

    // MARK: - View Model

    @Published private(set) var totalBalance: String = ""
    @Published private(set) var activeMiners: String = ""
    @Published private(set) var availableBalance: String = ""
    @Published private(set) var avatar: String = ""
    @Published private(set) var username: String = ""
    @Published private(set) var recentTransactions: [FormattedTransaction] = []
    @Published private(set) var selectedTransaction: Transaction?
    @Published private(set) var isMiningActive: Bool = false
    @Published private(set) var isSyncInProgress: Bool = false

    private var hasSyncedOnce: Bool {
        get { GroupUserDefaults.hasSyncedOnce ?? false }
        set { GroupUserDefaults.hasSyncedOnce = newValue }
    }

    // MARK: - Properties

    private let onContactUpdated = PassthroughSubject<Void, Never>()
    private var miningStatusTimer: Timer?

    private let contactsManager = ContactsManager()
    private let transactionFormatter = TransactionFormatter()
    private var recentWalletTransactions: [Transaction] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
        fetchMinerStats()
        startMiningStatusTimer()
    }

    deinit {
        miningStatusTimer?.invalidate()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        let monitor = AppConnectionHandler.shared.connectionMonitor

        Publishers.CombineLatest4(monitor.$networkConnection, monitor.$torConnection, monitor.$baseNodeConnection, monitor.$syncStatus)
            .sink { [weak self] in self?.handle(networkConnection: $0, torConnection: $1, baseNodeConnection: $2, syncStatus: $3) }
            .store(in: &cancellables)

        Tari.shared.wallet(.main).walletBalance.$balance
            .sink { [weak self] in self?.handle(walletBalance: $0) }
            .store(in: &cancellables)

        Tari.shared.wallet(.main).isWalletRunning.$value
            .filter { $0 }
            .sink { [weak self] _ in self?.updateAvatar() }
            .store(in: &cancellables)

        let transactionsPublisher = Tari.shared.wallet(.main).transactions.$all
            .map { $0.filterDuplicates() }
            .replaceError(with: [Transaction]())

        Publishers.CombineLatest(transactionsPublisher, onContactUpdated)
            .sink { [weak self] in self?.handle(transactions: $0.0) }
            .store(in: &cancellables)
    }

    private func updateContactsData() {
        Task {
            try await contactsManager.fetchModels()
            onContactUpdated.send(())
        }
    }

    private func startMiningStatusTimer() {
        // Initial check
        fetchMiningStatus()

        // Set up timer for periodic checks
        miningStatusTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.fetchMiningStatus()
        }
    }

    // MARK: - Actions

    func runManagers() {
        StagedWalletSecurityManager.shared.start()
    }

    func runNotifications(registerOnly: Bool, completion: @escaping () -> Void) {
        if registerOnly {
            NotificationManager.shared.registerPushToken { _ in
                completion()
            }
        } else {
            NotificationManager.shared.requestAuthorization { _ in
                completion()
            }
        }
    }

    func executeQueuedShortcut() {
        ShortcutsManager.executeQueuedShortcut()
    }

    func select(transactionID: UInt64) {
        selectedTransaction = try? recentWalletTransactions.first { try $0.identifier == transactionID }
    }

    func updateData() {
        updateContactsData()
    }

    // MARK: - Handlers

    private func handle(networkConnection: NetworkMonitor.Status, torConnection: TorConnectionStatus, baseNodeConnection: BaseNodeConnectivityStatus, syncStatus: TariValidationService.SyncStatus) {

        // Update sync status
        if !hasSyncedOnce {
            print("sync status:", syncStatus)
            isSyncInProgress = syncStatus != .synced
            if syncStatus == .synced {
                isSyncInProgress = false
                hasSyncedOnce = true
            }
        }
    }

    private func handle(walletBalance: WalletBalance) {
        let totalMicroTari = MicroTari(walletBalance.total)
        let availableMicroTari = MicroTari(walletBalance.available)
        totalBalance = totalMicroTari.formatted
        availableBalance = availableMicroTari.formatted
    }

    private func handle(transactions: [Transaction]) {
        Task {
            try? await transactionFormatter.updateContactsData()
            recentWalletTransactions = transactions
            recentTransactions = transactions.compactMap { try? transactionFormatter.model(transaction: $0) }
        }
    }

    func formatLargeNumber(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        } else {
            return "\(value)"
        }
    }

    func fetchMinerStats() {
        API.service.request(endpoint: "/miner/stats")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error fetching miner stats: \(error)")
                }
            }, receiveValue: { [weak self] (response: MinerStats) in
                self?.activeMiners = self?.formatLargeNumber(response.totalMiners) ?? "0"
            })
            .store(in: &cancellables)
    }

    func fetchMiningStatus() {
        guard let appId = NotificationManager.shared.appId else {
            isMiningActive = false
            return
        }

        print("Fetching mining status for appId: \(appId)")
        API.service.request(endpoint: "/miner/status/\(appId)")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error fetching mining status: \(error)")
                    // If there's an error (including unauthorized), set mining to inactive
                    self.isMiningActive = false
                }
            }, receiveValue: { [weak self] (response: MiningStatus) in
                print("Mining status response: \(response)")
                self?.isMiningActive = response.mining ?? false
            })
            .store(in: &cancellables)
    }

    private func updateAvatar() {
        guard let addressComponents = try? Tari.shared.wallet(.main).address.components else {
            avatar = ""
            username = ""
            return
        }

        avatar = addressComponents.coreAddressPrefix.firstOrEmpty
        username = addressComponents.formattedCoreAddress
    }
}
