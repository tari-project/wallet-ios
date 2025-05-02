//  BackupWalletSettingsViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 20/10/2022
	Using Swift 5.0
	Running on macOS 12.6

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

final class BackupWalletSettingsViewController: SecureViewController<BackupWalletSettingsView> {

    // MARK: - Properties

    private let model: BackupWalletSettingsModel
    private let seedWordsItem = SystemMenuTableViewCellItem(title: localized("backup_wallet_settings.item.with_recovery_phrase"))
    private let iCloudItem = SystemMenuTableViewCellItem(title: localized("backup_wallet_settings.item.icloud_backups"), hasSwitch: true)
    private let dropboxItem = SystemMenuTableViewCellItem(title: localized("backup_wallet_settings.item.dropbox_backups"), hasSwitch: true)
    private let passwordItem = SystemMenuTableViewCellItem(title: "")
    private let backupNowItem = SystemMenuTableViewCellItem(title: localized("backup_wallet_settings.item.backup_now"))
    private let onboardingItem = SystemMenuTableViewCellItem(title: localized("backup_wallet_settings.item.onboarding"))

    private var items: [SystemMenuTableViewCellItem] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: BackupWalletSettingsModel, backButtonType: NavigationBar.BackButtonType) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        mainView.navigationBar.backButtonType = backButtonType
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        BackupManager.shared.dropboxPresentationController = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.refreshData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$isSeedWordListVerified
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.seedWordsItem.mark = $0 ? .success : .attention }
            .store(in: &cancellables)

        model.$iCloudBackupState
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.update(switchItem: self.iCloudItem, backupState: $0) }
            .store(in: &cancellables)

        model.$iCloudLastBackupTime
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.update(item: self.iCloudItem, backupTimestamp: $0) }
            .store(in: &cancellables)

        model.$dropboxBackupState
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.update(switchItem: self.dropboxItem, backupState: $0) }
            .store(in: &cancellables)

        model.$dropboxLastBackupTime
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in self.update(item: self.dropboxItem, backupTimestamp: $0) }
            .store(in: &cancellables)

        Publishers.CombineLatest4(model.$iCloudBackupState, model.$dropboxBackupState, model.$isBackupSecuredByPassword, model.$isBackupOutOfSync)
            .sink { [weak self] in self?.updateListItems(isPasswordItemVisible: $0.isOn || $1.isOn, isBackupSecuredByPassword: $2, isBackupNowItemVisible: $3) }
            .store(in: &cancellables)

        iCloudItem.$isSwitchIsOn.eraseToAnyPublisher()
            .dropFirst()
            .sink { [weak self] in self?.handleICloudSwitch(isOn: $0) }
            .store(in: &cancellables)

        dropboxItem.$isSwitchIsOn
            .dropFirst()
            .sink { [weak self] in self?.model.update(isDropboxBackupOn: $0) }
            .store(in: &cancellables)

        mainView.onSelectRow = { [weak self] indexPath in

            guard let self else { return }

            let item = self.items[indexPath.row]

            switch item {
            case self.seedWordsItem:
                self.moveToSeedWordsList()
            case self.passwordItem:
                self.moveToSetPasswordForm()
            case self.backupNowItem:
                self.model.backupIfNeeded()
            case self.onboardingItem:
                self.moveToOnboarding()
            default:
                break
            }
        }
    }

    // MARK: - Handlers

    private func update(switchItem: SystemMenuTableViewCellItem, backupState: BackupWalletSettingsModel.BackupState) {

        switch backupState {
        case .off:
            switchItem.mark = .none
            switchItem.percent = 0.0
            switchItem.markDescription = ""
            guard switchItem.isSwitchIsOn == true else { return }
            switchItem.isSwitchIsOn = false
        case let .backupInProgress(progress):
            switchItem.mark = .progress
            switchItem.percent = progress
            switchItem.markDescription = localized("wallet_backup_state.in_progress")
        case .upToDate:
            switchItem.mark = .none
            switchItem.percent = 0.0
            switchItem.markDescription = ""
            guard switchItem.isSwitchIsOn == false else { return }
            switchItem.isSwitchIsOn = true
        case .backupFailed:
            switchItem.mark = .none
            switchItem.percent = 0.0
            switchItem.markDescription = localized("wallet_backup_state.out_to_date")
        }
    }

    private func update(item: SystemMenuTableViewCellItem, backupTimestamp: String?) {
        item.subtitle = backupTimestamp
    }

    private func updateListItems(isPasswordItemVisible: Bool, isBackupSecuredByPassword: Bool, isBackupNowItemVisible: Bool) {

        var items = [seedWordsItem]

        if !AppValues.general.isSimulator {
            items.append(iCloudItem)
        }

        if isPasswordItemVisible {
            passwordItem.title = isBackupSecuredByPassword ? localized("backup_wallet_settings.item.change_password") : localized("backup_wallet_settings.item.secure_your_backup")
            items.append(passwordItem)
        }

        if isBackupNowItemVisible {
            items.append(backupNowItem)
        }

        items.append(onboardingItem)

        self.items = items
        mainView.update(models: items)
    }

    private func handleICloudSwitch(isOn: Bool) {

        guard !isOn else {
            model.update(isCloudBackupOn: isOn)
            return
        }

        showDeleteBackupPopUp()
    }

    // MARK: - Actions

    private func showDeleteBackupPopUp() {

        let onAction: () -> Void = { [weak self] in
            self?.model.update(isCloudBackupOn: false)
        }

        let onCancel: () -> Void = { [weak self] in
            self?.iCloudItem.isSwitchIsOn = true
        }

        let model = PopUpDialogModel(
            title: localized("backup_wallet_settings.switch.warning.title"),
            message: localized("backup_wallet_settings.switch.warning.description"),
            buttons: [
                PopUpDialogButtonModel(title: localized("backup_wallet_settings.switch.warning.confirm"), type: .normal, callback: onAction),
                PopUpDialogButtonModel(title: localized("backup_wallet_settings.switch.warning.cancel"), type: .text, callback: onCancel)
            ],
            hapticType: .error
        )

        PopUpPresenter.showPopUp(model: model)
    }

    // MARK: - Navigation

    private func moveToSeedWordsList() {
        let controller = SeedWordsListConstructor.buildScene(backButtonType: .back)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func moveToSetPasswordForm() {
        let controller = model.isBackupSecuredByPassword ? PasswordVerificationViewController(variation: .change) : SecureBackupViewController(backButtonType: .back)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func moveToOnboarding() {
        let controller = OnboardingViewController()
        present(controller, animated: true)
    }
}
