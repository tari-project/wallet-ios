//  BackupWalletSettingsViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 28.05.2020
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

class BackupWalletSettingsViewController: SettingsParentTableViewController {

    private enum Section: Int {
        case settings
        case backupNow
    }

    private enum BackupSender {
        case none
        case uiSwitch
        case button
    }

    private var backupSender: BackupSender = .none

    private lazy var settingsSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: BackupWalletSettingsItem.iCloudBackups.rawValue, hasArrow: false, hasSwitch: true, switchIsOn: iCloudBackup.iCloudBackupsIsOn),
        SystemMenuTableViewCellItem(title: BackupWalletSettingsItem.setupPassword.rawValue)
    ]

    private let backupNowSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: BackupWalletSettingsItem.backupNow.rawValue, hasArrow: false)
    ]

    private var iCloudBackupsItem: SystemMenuTableViewCellItem?
    private var kvoiCloudBackupsToken: NSKeyValueObservation?

    private var backupNowButtonWalletBackup: Bool = false

    private enum BackupWalletSettingsItem: CaseIterable {
        case iCloudBackups
        case setupPassword
        case backupNow
        case backUpWithRecoveryPhrase

        var rawValue: String {
            switch self {
            case .iCloudBackups: return NSLocalizedString("backup_wallet_settings.item.icloud_backups", comment: "BackupWalletSettings view")
            case .setupPassword:
                if ICloudBackup.shared.lastBackup?.isEncrypted == true {
                    return NSLocalizedString("backup_wallet_settings.item.change_password", comment: "BackupWalletSettings view")
                } else {
                    return NSLocalizedString("backup_wallet_settings.item.secure_your_backup", comment: "BackupWalletSettings view")
                }
            case .backupNow: return NSLocalizedString("backup_wallet_settings.item.backup_now", comment: "BackupWalletSettings view")
            case .backUpWithRecoveryPhrase: return NSLocalizedString("backup_wallet_settings.item.with_recovery_phrase", comment: "BackupWalletSettings view")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        backUpWalletItem = backupNowSectionItems.first(where: { $0.title == BackupWalletSettingsItem.backupNow.rawValue })
        iCloudBackupsItem = settingsSectionItems.first(where: { $0.title == BackupWalletSettingsItem.iCloudBackups.rawValue })

        tableView.delegate = self
        tableView.dataSource = self
        observeICloudBackupsSwitch()
    }

    private func onBackupNowAction() {
        backupSender = .button
        createWalletBackup()
    }

    private func onChangePasswordAction() {
        if iCloudBackup.lastBackup?.isEncrypted == true {
            navigationController?.pushViewController(PasswordVerificationViewController(variation: .change), animated: true)
        } else {
            navigationController?.pushViewController(SecureBackupViewController(), animated: true)
        }
    }

    private func onBackupWithRecoveryPhraseAction() {
        navigationController?.pushViewController(SeedPhraseViewController(), animated: true)
    }

    private func observeICloudBackupsSwitch() {
        guard let iCloudBackupsItem = self.iCloudBackupsItem else { return }
        kvoiCloudBackupsToken = iCloudBackupsItem.observe(\.isSwitchIsOn, options: .new) { [weak self] (item, change) in
            if change.newValue == change.oldValue { return }
            if item.isSwitchIsOn {
                self?.backupSender = .uiSwitch
                self?.iCloudBackup.iCloudBackupsIsOn = true
                self?.createWalletBackup()
            } else {
                UserFeedback.shared.callToAction(
                    title: NSLocalizedString("backup_wallet_settings.switch.warning.title", comment: "BackupWalletSettings view"),
                    boldedTitle: nil,
                    description: NSLocalizedString("backup_wallet_settings.switch.warning.description", comment: "BackupWalletSettings view"),
                    actionTitle: NSLocalizedString("backup_wallet_settings.switch.warning.confirm", comment: "BackupWalletSettings view"),
                    cancelTitle: NSLocalizedString("backup_wallet_settings.switch.warning.cancel", comment: "BackupWalletSettings view"),
                    onAction: { [weak self] in
                            BPKeychainWrapper.removeBackupPasswordFromKeychain()
                            self?.iCloudBackup.iCloudBackupsIsOn = false
                            self?.iCloudBackup.removeCurrentWalletBackup()
                            self?.reloadTableViewWithAnimation()
                    },
                    onCancel: { [weak self] in
                        self?.iCloudBackup.iCloudBackupsIsOn = true
                        self?.kvoiCloudBackupsToken?.invalidate()
                        self?.kvoiCloudBackupsToken = nil
                        self?.iCloudBackupsItem?.isSwitchIsOn = true
                        self?.observeICloudBackupsSwitch()
                })
            }
        }
    }

    private func createWalletBackup() {
        TariLib.shared.waitIfWalletIsRestarting { [weak self] (_) in
            do {
                let password = BPKeychainWrapper.loadBackupPasswordFromKeychain()
                try ICloudBackup.shared.createWalletBackup(password: password)
            } catch {
                self?.failedToCreateBackup(error: error)
            }
            self?.reloadTableViewWithAnimation()
        }
    }

    override func failedToCreateBackup(error: Error) {
        super.failedToCreateBackup(error: error)
        if iCloudBackup.isLastBackupFailed && !iCloudBackup.isValidBackupExists() && backupSender == .uiSwitch {
            iCloudBackup.iCloudBackupsIsOn = false
            kvoiCloudBackupsToken?.invalidate()
            kvoiCloudBackupsToken = nil
            iCloudBackupsItem?.isSwitchIsOn = false
            reloadTableViewWithAnimation()
            observeICloudBackupsSwitch()
        }
    }

    override func reloadTableViewWithAnimation() {
        super.reloadTableViewWithAnimation()
        if let securePasswordItem = settingsSectionItems.last {
            securePasswordItem.title = BackupWalletSettingsItem.setupPassword.rawValue
        }
    }

    override func updateMarks() {
        super.updateMarks()

        if numberOfSections() == 1 {
            if iCloudBackup.inProgress {
                iCloudBackupsItem?.mark = .progress
                iCloudBackupsItem?.markDescription = ICloudBackupState.inProgress.rawValue
                iCloudBackupsItem?.percent = iCloudBackup.progressValue
            } else {
                iCloudBackupsItem?.mark = .none
            }
        } else {
            iCloudBackupsItem?.mark = .none
        }
    }

    override func onUploadProgress(percent: Double, started: Bool, completed: Bool, error: Error?) {
        super.onUploadProgress(percent: percent, started: started, completed: completed, error: error)
        if completed { backupSender = .none }
    }

    deinit {
        kvoiCloudBackupsToken?.invalidate()
    }
}

// MARK: Setup subviews
extension BackupWalletSettingsViewController {
    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.title = NSLocalizedString("backup_wallet_settings.title", comment: "BackupWalletSettings view")
    }
}

extension BackupWalletSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    private func numberOfSections() -> Int {
        if (!iCloudBackup.isValidBackupExists() && iCloudBackup.iCloudBackupsIsOn && !iCloudBackup.inProgress) ||
            (iCloudBackup.iCloudBackupsIsOn && BackupScheduler.shared.isBackupScheduled) {
            return 2
        } else {
            return 1
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .settings:
            if iCloudBackup.iCloudBackupsIsOn && !iCloudBackup.inProgress {
                return settingsSectionItems.count
            } else {
                return settingsSectionItems.count - 1
            }
        case .backupNow: return backupNowSectionItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SystemMenuTableViewCell.self), for: indexPath) as! SystemMenuTableViewCell
        guard let section = Section(rawValue: indexPath.section) else { return cell }

        switch section {
        case .settings: cell.configure(settingsSectionItems[indexPath.row])
        case .backupNow: cell.configure(backupNowSectionItems[indexPath.row])
        }

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        65
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let lastSuccessful = iCloudBackup.lastBackup != nil && !iCloudBackup.inProgress && !iCloudBackup.isLastBackupFailed
        if tableView.numberOfSections - 1 == section && lastSuccessful {
            return 50.0
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableView.numberOfSections - 1 != section || !iCloudBackup.iCloudBackupsIsOn {
            return nil
        }

        if let lastBackupString = ICloudBackup.shared.lastBackup?.dateCreationString {
            let footer = UIView()
            footer.backgroundColor = .clear

            let lastBackupLabel =  UILabel()
            lastBackupLabel.font = Theme.shared.fonts.settingsTableViewLastBackupDate
            lastBackupLabel.textColor =  Theme.shared.colors.settingsTableViewLastBackupDate

            lastBackupLabel.text = String(format: NSLocalizedString("settings.last_successful_backup.with_param", comment: "Settings view"), lastBackupString)

            footer.addSubview(lastBackupLabel)

            lastBackupLabel.translatesAutoresizingMaskIntoConstraints = false
            lastBackupLabel.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 25).isActive = true
            lastBackupLabel.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -25).isActive = true
            lastBackupLabel.topAnchor.constraint(equalTo: footer.topAnchor, constant: 8).isActive = true
            lastBackupLabel.lineBreakMode = .byTruncatingMiddle

            return footer
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = Section(rawValue: section) else { return nil }

        if section == .backupNow {
            return nil
        }

        let header = UIView()
        header.backgroundColor = .clear

        let label = UILabel()
        label.font = Theme.shared.fonts.settingsViewHeader
        label.text = NSLocalizedString("backup_wallet_settings.header.title", comment: "BackupWalletSettings view")

        header.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 25).isActive = true
        label.topAnchor.constraint(equalTo: header.topAnchor, constant: 30).isActive = true

        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = Theme.shared.fonts.settingsSeedPhraseDescription
        descriptionLabel.textColor = Theme.shared.colors.settingsViewDescription
        descriptionLabel.text = NSLocalizedString("backup_wallet_settings.header.description", comment: "BackupWalletSettings view")

        header.addSubview(descriptionLabel)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 15).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 25).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -25).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -25).isActive = true

        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .settings:
            let item = BackupWalletSettingsItem.allCases[indexPath.row]
            if item == .setupPassword {
                onChangePasswordAction()
            }
        case .backupNow:
            let item = BackupWalletSettingsItem.allCases[indexPath.row + settingsSectionItems.count]
            if item == .backupNow {
                onBackupNowAction()
            }
        }
    }
}
