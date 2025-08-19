//  Home+Actions.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 26.06.2025
	Using Swift 6.0
	Running on macOS 15.5

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

import SwiftUI

extension Home {
    func load() {
        fetchMinerStats()
        fetchMiningStatus()
        loadWalletState()
        ShortcutsManager.executeQueuedShortcut()
        StagedWalletSecurityManager.shared.start()
    }
    
    func transaction(for transaction: FormattedTransaction) -> Transaction? {
        Tari.mainWallet.transaction(id: transaction.id)
    }
    
    func update(walletBalance: WalletBalance) {
        totalBalance = MicroTari(walletBalance.total).formatted
        availableBalance = MicroTari(walletBalance.available).formatted
    }
    
    func update(transactions: [Transaction]) {
        isLoadingTransactions = true
        Task {
            // TODO: load first 10
            defer { isLoadingTransactions = false }
            let uniqueTransactions = transactions.filterDuplicates()
            let transactionFormatter = TransactionFormatter()
            try? await transactionFormatter.updateContactsData()
            recentTransactions = uniqueTransactions.compactMap { try? transactionFormatter.model(transaction: $0) }
        }
    }

    func showAmountHelp() {
        let popUpModel = PopUpDialogModel(
            title: localized("home.pop_up.amount_help.title"),
            message: localized("home.pop_up.amount_help.message"),
            buttons: [
                PopUpDialogButtonModel(title: localized("home.pop_up.amount_help.buttons.open_url"), type: .normal) {
                    guard let url = URL(string: TariSettings.shared.tariLabsUniversityUrl) else { return }
                    UIApplication.shared.open(url)
                },
                PopUpDialogButtonModel(title: localized("common.close"), type: .text)
            ],
            hapticType: .none
        )
        PopUpPresenter.showPopUp(model: popUpModel)
    }
}

private extension Home {
    var shouldShowWelcomeOverlay: Bool {
        get { UserDefaults.standard.bool(forKey: "ShouldShowWelcomeOverlay") }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: "ShouldShowWelcomeOverlay") }
    }
    
    func fetchMinerStats() {
        Task {
            let stats = await API.service.minerStats()
            activeMiners = formatLargeNumber(stats?.totalMiners ?? 0)
        }
    }

    func fetchMiningStatus() {
        guard let appId = NotificationManager.shared.appId else {
            isMining = false
            return
        }
        print("Fetching mining status for appId: \(appId)")
        Task {
            let status = await API.service.minerStatus(appId: appId)
            isMining = status?.mining ?? false
            
            // Check mining status periodically
            Task(after: 10) {
                fetchMiningStatus()
            }
        }
    }
    
    // TODO: extract into a formatter
    func formatLargeNumber(_ value: Int) -> String {
        if 1_000_000 <= value {
            String(format: "%.1fM", Double(value) / 1_000_000)
        } else if 1_000 <= value {
            String(format: "%.1fK", Double(value) / 1_000)
        } else {
            "\(value)"
        }
    }

    func loadWalletState() {
        // Only when a wallet is explicitly created or restored AND flag is true, show welcome overlay
        if shouldShowWelcomeOverlay {
            if walletState == .newRestored {
                showOverlay(for: .restored)
                shouldShowWelcomeOverlay = false
            } else if walletState == .newSynced {
                showOverlay(for: .synced)
                shouldShowWelcomeOverlay = false
            } else {
                NotificationManager.shared.shouldPromptForNotifications { shouldPrompt in
                    Task { @MainActor in
                        if shouldPrompt {
                            showOverlay(for: .notifications)
                        } else {
                            NotificationManager.shared.registerWithAPNS()
                        }
                    }
                }
            }
        }
    }
    
    func showOverlay(for overlay: Overlay) {
        let overlayViewController = OverlayViewController()

        overlayViewController.onCloseButtonTap = {
            overlayViewController.dismiss(animated: true)
        }
        overlayViewController.onPromptButtonTap = {
            runNotifications(registerOnly: false) {
                Task { @MainActor in
                    overlayViewController.dismiss(animated: true)
                }
            }
        }
        overlayViewController.onNoPromptClose = {
            runNotifications(registerOnly: true) {
                Task { @MainActor in
                    overlayViewController.dismiss(animated: true)
                }
            }
        }
        overlayViewController.onStartMiningButtonTap = {
            overlayViewController.dismiss(animated: true)
            if let url = URL(string: "https://tari.com/") {
                UIApplication.shared.open(url)
            }
        }
        overlayViewController.activeOverlay = overlay
        if overlay == .disclaimer {
            overlayViewController.totalBalance = totalBalance
            overlayViewController.availableBalance = availableBalance
        }
        overlayViewController.transitioningDelegate = overlayViewController
        overlayViewController.modalPresentationStyle = .custom
        
        UIApplication.shared.topController?.present(overlayViewController, animated: false)
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
}
