//  BackupPrompts.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/07/13
	Using Swift 5.0
	Running on macOS 10.15

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
import LocalAuthentication

private class BackupPrompts {
    struct TriggerRequirements {
        let numberOfIncomingTxs: Int
        let totalBalance: MicroTari
        let hasConnectediCloud: Bool
        let backupIsEncrypted: Bool
    }

    struct ModalContent {
        let title: String
        let boldTitle: String
        let description: String
        let ctaButton: String
        let cancelButton: String
    }

    enum PromptType: CaseIterable {
        case first
        case second
        case third

        var triggers: TriggerRequirements {
            switch self {
            case .first:
                return TriggerRequirements(
                    numberOfIncomingTxs: 3,
                    totalBalance: MicroTari(0),
                    hasConnectediCloud: false,
                    backupIsEncrypted: false
                )
            case .second:
                return TriggerRequirements(
                    numberOfIncomingTxs: 4,
                    totalBalance: MicroTari(tariValue: 8000),
                    hasConnectediCloud: false,
                    backupIsEncrypted: false
                )
            case .third:
                return TriggerRequirements(
                    numberOfIncomingTxs: 5,
                    totalBalance: MicroTari(tariValue: 25000),
                    hasConnectediCloud: true,
                    backupIsEncrypted: false
                )
            }
        }

        var userDefaultsKey: String {
            switch self {
            case .first:
                return "has-shown-backup-prompt-1"
            case .second:
                return "has-shown-backup-prompt-2"
            case .third:
                return "has-shown-backup-prompt-3"
            }
        }

        var content: ModalContent {
            switch self {
            case .first:
                return ModalContent(
                    title: localized("wallet_backup.prompt_1.title"),
                    boldTitle: localized("wallet_backup.prompt_1.title_bold"),
                    description: localized("wallet_backup.prompt_1.description"),
                    ctaButton: localized("wallet_backup.prompt_1.cta_button"),
                    cancelButton: localized("wallet_backup.prompt_1.cancel_button")
                )
            case .second:
                return ModalContent(
                    title: localized("wallet_backup.prompt_2.title"),
                    boldTitle: localized("wallet_backup.prompt_2.title_bold"),
                    description: localized("wallet_backup.prompt_2.description"),
                    ctaButton: localized("wallet_backup.prompt_2.cta_button"),
                    cancelButton: localized("wallet_backup.prompt_2.cancel_button")
                )
            case .third:
                return ModalContent(
                    title: localized("wallet_backup.prompt_3.title"),
                    boldTitle: localized("wallet_backup.prompt_3.title_bold"),
                    description: localized("wallet_backup.prompt_3.description"),
                    ctaButton: localized("wallet_backup.prompt_3.cta_button"),
                    cancelButton: localized("wallet_backup.prompt_3.cancel_button")
                )
            }
        }
    }

    static let shared = BackupPrompts()

    private init () {}

    func check(_ vc: UIViewController) {
        guard let wallet = TariLib.shared.tariWallet else {
            return
        }

        for type in PromptType.allCases.reversed() {
            // If they have been shown this once, skip over this prompt
            guard UserDefaults.standard.bool(forKey: type.userDefaultsKey) == false else {
                continue
            }

            var incomingTxs = wallet.pendingInboundTxs.0?.count.0 ?? 0
            let completedTxs: [CompletedTx] = (wallet.completedTxs.0?.list.0 ?? [])
            completedTxs.forEach { (tx) in
                if tx.direction == .inbound {
                    incomingTxs += 1
                }
            }

            let balance = wallet.totalMicroTari.0 ?? MicroTari(0)

            let triggers = type.triggers

            guard incomingTxs >= triggers.numberOfIncomingTxs &&
            balance.rawValue >= triggers.totalBalance.rawValue &&
                ICloudBackup.shared.isValidBackupExists() == triggers.hasConnectediCloud &&
                (ICloudBackup.shared.lastBackup?.isEncrypted ?? false) == triggers.backupIsEncrypted &&
                !ICloudBackup.shared.iCloudBackupsIsOn
            else {
                continue
            }

            setAsShown(type)
            let content = type.content
            UserFeedback.shared.callToAction(
                title: content.title,
                boldedTitle: content.boldTitle,
                description: content.description,
                actionTitle: content.ctaButton,
                cancelTitle: content.cancelButton,
                onAction: {
                    UIApplication.shared.menuTabBarController?.setTab(.settings)
            }
            )
            break
        }
    }

    /// Sets all triggers as "shown" if it matches the passed trigger and/or is below the passed trigger. i.e. The second tigger will set the first and second as shown.
    /// - Parameter type: Prompt type (first, second, third)
    private func setAsShown(_ type: PromptType) {
        var setAsShown: Bool = false
        for t in PromptType.allCases.reversed() {
            if t == type {
                setAsShown = true
            }

            UserDefaults.standard.set(setAsShown, forKey: t.userDefaultsKey)
        }
    }

    /// For testing in debug only
    func resetTriggers() {
        guard TariSettings.shared.environment == .debug else {  return }
        for type in PromptType.allCases {
            UserDefaults.standard.set(false, forKey: type.userDefaultsKey)
        }
    }
}

extension UIViewController {
    func checkBackupPrompt(delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            BackupPrompts.shared.check(self)
        }
    }
}
