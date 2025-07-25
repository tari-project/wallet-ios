//  RestoreWalletViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 27.05.2020
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
import Combine

class SimpleMenuTableViewCellItem: DynamicThemeCell {

}

final class RestoreWalletViewController: SettingsParentTableViewController, UITableViewDelegate, UITableViewDataSource, OverlayPresentable {

    private enum EndFlowAction {
        case none
        case navigateBack
        case navigateBackAndStartWallet
    }

    private let localAuth = LAContext()

    private let model = RestoreWalletModel()
    private let pendingView = PendingView(title: localized("restore_pending_view.title"),
                                          definition: localized("restore_pending_view.description"),
                                          longDefinition: localized("restore_pending_view.description_long"))
    private let items: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: RestoreCellTitle.syncWithDesktop.rawValue),
        SystemMenuTableViewCellItem(title: RestoreCellTitle.iCloudRestore.rawValue),
        SystemMenuTableViewCellItem(title: RestoreCellTitle.phraseRestore.rawValue)
    ]

    private var cancellables = Set<AnyCancellable>()

    private enum RestoreCellTitle: CaseIterable {
        case syncWithDesktop
        case iCloudRestore
        case phraseRestore

        var rawValue: String {
            switch self {
            case .syncWithDesktop: return localized("restore_wallet.item.desktop_restore")
            case .iCloudRestore: return localized("restore_wallet.item.iCloud_restore")
            case .phraseRestore: return localized("restore_wallet.item.phrase_restore")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        tableView.tableHeaderView = .none
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$action
            .compactMap { $0 }
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        model.$error
            .compactMap { $0 }
            .sink { [weak self] in self?.handle(recoveryErrorMessage: $0) }
            .store(in: &cancellables)

        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: - Actions

    private func showPasswordScreen(onCompletion: @escaping ((String?) -> Void)) {
        let controller = PasswordVerificationViewController(variation: .restore, restoreWalletAction: onCompletion)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func showRecoveryOverlay() {
        let overlay = SeedWordsRecoveryProgressViewController()

        // Set flag to show welcome overlay for restored wallet
        UserDefaults.standard.set(true, forKey: "ShouldShowWelcomeOverlay")

        overlay.onSuccess = {
            // Always show the same wallet creation screens as for a new wallet
            AppRouter.transitionToOnboardingScreen(startFromLocalAuth: false)
        }

        overlay.onFailure = { [weak self] in
            self?.model.removeWallet()
        }

        show(overlay: overlay)
    }

    private func showPaperWalletPasswordForm() {
        FormOverlayPresenter.showRecoveryPasswordForm(presenter: self) { [weak self] in
            self?.model.enter(paperWalletPassword: $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(type: SystemMenuTableViewCell.self, indexPath: indexPath)
        let item = items[indexPath.row]
        cell.configure(item)
        cell.preservesSuperviewLayoutMargins = false

        cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        cell.layoutMargins = .zero
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        63
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let item = RestoreCellTitle.allCases[indexPath.row + indexPath.section]
        switch item {
        case .syncWithDesktop:
            onPaperWalletRestoreAction()
        case .iCloudRestore: oniCloudRestoreAction()
        case .phraseRestore: onPhraseRestoreAction()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return .none
    }

    private func oniCloudRestoreAction() {
        // Commenting out iCloud restore
        // authenticateUserAndRestoreWallet(from: .iCloud)
    }

    private func onPhraseRestoreAction() {
        let viewController = RestoreWalletFromSeedsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func onPaperWalletRestoreAction() {
        let disabledDataTypes: [QRCodeScannerModel.DataType] = [.deeplink(.contacts), .deeplink(.profile), .deeplink(.transactionSend), .torBridges]
        AppRouter.presentQrCodeScanner(expectedDataTypes: [.deeplink(.paperWallet)], disabledDataTypes: disabledDataTypes) { [weak self] in
            self?.handle(qrCodeData: $0)
        }
    }

    private func authenticateUserAndRestoreWallet(from service: BackupManager.Service) {
        localAuth.authenticateUser(reason: .userVerification) { [weak self] in
            Task(after: 1) { @MainActor in
                self?.restoreWallet(from: service, password: nil)
            }
        }
    }

    private func restoreWallet(from service: BackupManager.Service, password: String?) {
        // Set flag to show welcome overlay for restored wallet
        UserDefaults.standard.set(true, forKey: "ShouldShowWelcomeOverlay")

        pendingView.showPendingView { [weak self] in
            guard let self else { return }
            BackupManager.shared.backupService(service).restoreBackup(password: password)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    switch completion {
                    case .finished:
                        BackupManager.shared.password = password
                        let action: EndFlowAction = password == nil ? .navigateBack : .navigateBackAndStartWallet
                        self?.endFlow(action: action)
                    case let .failure(error):
                        self?.handle(error: error, service: service)
                    }
                } receiveValue: { _ in }
                .store(in: &self.cancellables)
        }
    }

    private func showPasswordScreen(service: BackupManager.Service) {
        pendingView.hidePendingView { [weak self] in
            self?.showPasswordScreen { password in
                self?.restoreWallet(from: service, password: password)
            }
        }
    }

    private func showRecoveryFromPaperWalletPopUp() {

        let model = PopUpDialogModel(
            title: localized("restore_wallet.pop_up.paper_wallet.confirmation.title"),
            message: String(format: localized("restore_wallet.pop_up.paper_wallet.confirmation.message"), NetworkManager.shared.currencySymbol),
            buttons: [
                PopUpDialogButtonModel(title: localized("restore_wallet.pop_up.paper_wallet.confirmation.buttons.ok"), type: .normal, callback: { [weak self] in self?.model.confirmWalletRecovery() }),
                PopUpDialogButtonModel(title: localized("restore_wallet.pop_up.paper_wallet.confirmation.buttons.cancel"), type: .text, callback: { [weak self] in self?.model.cancelWalletRecovery() })
            ],
            hapticType: .none
        )

        PopUpPresenter.showPopUp(model: model)
    }

    private func endFlow(action: EndFlowAction) {
        pendingView.hidePendingView { [weak self] in
            self?.handle(endFlowAction: action)
        }
    }

    private func handle(endFlowAction: EndFlowAction) {
        switch endFlowAction {
        case .none:
            return
        case .navigateBack:
            AppRouter.transitionToSplashScreen(isWalletConnected: true)
        case .navigateBackAndStartWallet:
            // Always show creation screens for imported wallets, similar to create wallet flow
            AppRouter.transitionToOnboardingScreen(startFromLocalAuth: false)
        }
    }

    private func handle(error: Error, service: BackupManager.Service) {
        var errorMessage: String?

        switch error {
        case let error as BackupError where error == .passwordRequired:
            showPasswordScreen(service: service)
            return
        case let error as BackupError where error == .noRemoteBackup:
            errorMessage = localized("iCloud_backup.error.no_backup_exists")
        case let error as ICloudBackupService.ICloudBackupError:
            guard let walletError = error.internalError as? WalletError else { break }

            guard walletError == .cantRecover else {
                errorMessage = ErrorMessageManager.errorMessage(forError: walletError)
                break
            }

            errorMessage = localized("error.wallet.702.recovery")

        default:
            errorMessage = ErrorMessageManager.errorMessage(forError: error)
        }

        if let errorMessage {
            let model = MessageModel(title: localized("iCloud_backup.error.title.restore_wallet"), message: errorMessage, type: .error)
            PopUpPresenter.show(message: model)
        }

        endFlow(action: .none)
    }

    private func handle(action: RestoreWalletModel.Action) {
        switch action {
        case .showPaperWalletConfirmation:
            showRecoveryFromPaperWalletPopUp()
        case .showPaperWalletRecoveryProgress:
            showRecoveryOverlay()
        case .showPaperWalletPasswordForm:
            showPaperWalletPasswordForm()
        }
    }

    private func handle(recoveryErrorMessage: MessageModel) {
        PopUpPresenter.show(message: recoveryErrorMessage)
    }

    private func handle(qrCodeData: QRCodeData) {
        switch qrCodeData {
        case let .deeplink(deeplink):
            guard let deeplink = deeplink as? PaperWalletDeeplink else { return }
            model.requestWalletRecovery(paperWalletDeeplink: deeplink)
        case .bridges:
            break
        case .base64Address:
            break
        }
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)

        view.backgroundColor = .Background.secondary
    }
}

// MARK: Setup subviews
extension RestoreWalletViewController {
    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.backgroundColor = .Background.secondary
        navigationBar.title = localized("restore_wallet.title")
    }

    override func setupNavigationBarSeparator() {
        return
    }
}
