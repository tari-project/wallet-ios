//  StagedWalletSecurityManager.swift

/*
	Package MobileWallet
	Created by Browncoat on 23/01/2023
	Using Swift 5.0
	Running on macOS 13.0

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

final class StagedWalletSecurityManager {

    // MARK: - Constants

    static let minimumStageOneBalance: MicroTari = MicroTari(tariValue: 10000)
    static let stageTwoThresholdBalance: MicroTari = MicroTari(tariValue: 100000)
    static let safeHotWalletBalance: MicroTari = MicroTari(tariValue: 500000000)
    static let maxHotWalletBalance: MicroTari = MicroTari(tariValue: 1000000000)

    // MARK: - Properties

    static let shared = StagedWalletSecurityManager()

    private var hasVerifiedSeedPhrase: Bool { TariSettings.shared.walletSettings.hasVerifiedSeedPhrase }
    private var isBackupOn: Bool { TariSettings.shared.walletSettings.iCloudDocsBackupStatus.isOn || TariSettings.shared.walletSettings.dropboxBackupStatus.isOn }
    private var isBackupPasswordSet: Bool { AppKeychainWrapper.backupPassword != nil }
    private var disabledTimestampSinceNow: Date { Date(timeIntervalSinceNow: 60 * 60 * 24 * 7) }

    private var disabledActionsTimestamps: [WalletSettings.WalletSecurityStage: Date] {
        get { TariSettings.shared.walletSettings.delayedWalletSecurityStagesTimestamps }
        set { TariSettings.shared.walletSettings.delayedWalletSecurityStagesTimestamps = newValue }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    private init() {}

    // MARK: - Setups

    private func setupCallbacks() {
        Tari.shared.wallet(.main).walletBalance.$balance
            .sink { [weak self] in self?.handle(balance: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func start() {
        guard cancellables.isEmpty else { return }
        setupCallbacks()
    }

    func stop() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    @MainActor private func showPopUp(securityStage: WalletSettings.WalletSecurityStage) {
        switch securityStage {
        case .stage1A:
            showStage1APopUp()
        case .stage1B:
            showStage1BPopUp()
        case .stage2:
            showStage2PopUp()
        case .stage3:
            showStage3PopUp()
        }
    }

    @MainActor private func showStage1APopUp() {

        let messageParts = [
            localized("staged_wallet_security.stages.1a.message.part1"),
            localized("staged_wallet_security.stages.1a.message.part2.bold"),
            localized("staged_wallet_security.stages.1a.message.part3"),
            localized("staged_wallet_security.stages.1a.message.part4.bold"),
            localized("staged_wallet_security.stages.1a.message.part5")
        ]

        let message = messageParts.joined()
        let messageBoldRanges = [
            NSRange(location: messageParts[0].count, length: messageParts[1].count),
            NSRange(location: messageParts[0...2].joined().count, length: messageParts[3].count)
        ]

        showPopUp(
            title: localized("staged_wallet_security.stages.1a.title"),
            subtitle: localized("staged_wallet_security.stages.1a.subtitle"),
            message: message,
            messageBoldRanges: messageBoldRanges,
            mainActionTitle: localized("staged_wallet_security.stages.1a.buttons.navigate"),
            mainActionCallback: { AppRouter.presentVerifiySeedPhrase() },
            helpActionCallback: { [weak self] in self?.show(onbardingPage: .page1) }
        )
    }

    @MainActor private func showStage1BPopUp() {
        showPopUp(
            title: localized("staged_wallet_security.stages.1b.title"),
            subtitle: localized("staged_wallet_security.stages.1b.subtitle"),
            message: localized("staged_wallet_security.stages.1b.message"),
            mainActionTitle: localized("staged_wallet_security.stages.1b.buttons.navigate"),
            mainActionCallback: { AppRouter.presentBackupSettings() },
            helpActionCallback: { [weak self] in self?.show(onbardingPage: .page2) }
        )
    }

    @MainActor private func showStage2PopUp() {
        showPopUp(
            title: localized("staged_wallet_security.stages.2.title"),
            subtitle: localized("staged_wallet_security.stages.2.subtitle"),
            message: localized("staged_wallet_security.stages.2.message"),
            mainActionTitle: localized("staged_wallet_security.stages.2.buttons.navigate"),
            mainActionCallback: { AppRouter.presentBackupPasswordSettings() },
            helpActionCallback: { [weak self] in self?.show(onbardingPage: .page3) }
        )
    }

    @MainActor private func showStage3PopUp() {
        showPopUp(
            title: localized("staged_wallet_security.stages.3.title"),
            subtitle: localized("staged_wallet_security.stages.3.subtitle"),
            message: localized("staged_wallet_security.stages.3.message"),
            mainActionTitle: localized("staged_wallet_security.stages.3.buttons.navigate"),
            mainActionCallback: {},
            helpActionCallback: {}
        )
    }

    @MainActor private func showPopUp(title: String, subtitle: String, message: String, messageBoldRanges: [NSRange] = [], mainActionTitle: String,
                                      mainActionCallback: @escaping () -> Void, helpActionCallback: @escaping () -> Void) {
        let headerSection = PopUpStagedWalletSecurityHeaderView(title: title, subtitle: subtitle)
        let contentSection = PopUpDescriptionContentView()
        let buttonsSection = PopUpComponentsFactory.makeButtonsView(models: [
            PopUpDialogButtonModel(title: mainActionTitle, type: .normal, callback: { DispatchQueue.main.async { mainActionCallback() }}),
            PopUpDialogButtonModel(title: localized("staged_wallet_security.buttons.remind_me_later"), type: .text)
        ])

        headerSection.onHelpButtonPress = {
            helpActionCallback()
        }

        if messageBoldRanges.isEmpty {
            contentSection.label.text = message
        } else {
            let attributedMessage = NSMutableAttributedString(string: message)
            messageBoldRanges.forEach { attributedMessage.addAttribute(.font, value: UIFont.Avenir.black.withSize(14.0), range: $0) }
            contentSection.label.attributedText = attributedMessage
        }

        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popUp)
    }

    private func show(onbardingPage viewModel: OnboardingPageView.ViewModel) {
        PopUpPresenter.dismissPopup {
            DispatchQueue.main.async {

                let controller = OnboardingPageViewController()
                controller.viewModel = viewModel

                let parentController = ContentNavigationViewController()
                parentController.add(childController: controller, containerView: parentController.contentView)
                parentController.navigationBar.backButtonType = .close
                parentController.navigationBar.isSeparatorVisible = false

                parentController.onLayoutChange = { [weak controller, weak parentController] in
                    guard let controller else { return }
                    controller.contentHeight = parentController?.contentView.frame.height ?? 0.0
                    controller.footerHeight = OnboardingPageView.ViewModel.calculateFooterHeight(forView: controller.view)
                }

                AppRouter.present(controller: parentController)
            }
        }
    }

    // MARK: - Handlers

    private func handle(balance: WalletBalance) {
        Logger.log(message: "Balance Change Detected", domain: .stagedWalletSecurity, level: .info)
        guard let securityStage = securityStage(balance: balance) else { return }
        Logger.log(message: "Stage Selected: \(securityStage)", domain: .stagedWalletSecurity, level: .info)
        guard !isActionDiabled(securityStage: securityStage) else { return }
        guard securityStage != .stage3 else { return } // FIXME: Stage 3 is currently disabled
        updateTimestamp(securityStage: securityStage)
        Task { @MainActor in
            showPopUp(securityStage: securityStage)
        }
    }

    private func updateTimestamp(securityStage: WalletSettings.WalletSecurityStage) {
        let newTimestamp = disabledTimestampSinceNow
        disabledActionsTimestamps[securityStage] = newTimestamp
        Logger.log(message: "Timestamp updated \(newTimestamp) for \(securityStage)", domain: .stagedWalletSecurity, level: .info)
    }

    // MARK: - Helpers

    private func securityStage(balance: WalletBalance) -> WalletSettings.WalletSecurityStage? {
        switch balance.available {
        case (Self.minimumStageOneBalance.rawValue + 1)... where !hasVerifiedSeedPhrase:
            return .stage1A
        case (Self.minimumStageOneBalance.rawValue + 1)... where !isBackupOn:
            return .stage1B
        case (Self.stageTwoThresholdBalance.rawValue + 1)... where !isBackupPasswordSet:
            return .stage2
        case (Self.safeHotWalletBalance.rawValue + 1)...:
            return .stage3
        default:
            return nil
        }
    }

    private func isActionDiabled(securityStage: WalletSettings.WalletSecurityStage) -> Bool {
        guard let timestamp = disabledActionsTimestamps[securityStage] else { return false }
        guard timestamp < Date() else {
            Logger.log(message: "Action disabled until \(timestamp) for \(securityStage)", domain: .stagedWalletSecurity, level: .info)
            return true
        }

        disabledActionsTimestamps[securityStage] = nil
        return false
    }
}
