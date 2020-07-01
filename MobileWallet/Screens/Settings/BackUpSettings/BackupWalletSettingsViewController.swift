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
import LocalAuthentication

class BackupWalletSettingsViewController: SettingsParentTableViewController {

    private enum Section: Int {
        case settings
        case backUpNow
    }

    private let settingsSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: BackupWalletSettingsItem.iCloudBackups.rawValue),
        SystemMenuTableViewCellItem(title: BackupWalletSettingsItem.changePassword.rawValue)
    ]

    private let backupNowSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: BackupWalletSettingsItem.backUpNow.rawValue, mark: .attention)
    ]

    private enum BackupWalletSettingsItem: CaseIterable {
        case iCloudBackups
        case changePassword
        case backUpNow
        case backUpWithRecoveryPhrase

        var rawValue: String {
            switch self {
            case .iCloudBackups: return NSLocalizedString("backup_wallet_settings.item.icloud_backups", comment: "BackupWalletSettings view")
            case .changePassword: return NSLocalizedString("backup_wallet_settings.item.change_password", comment: "BackupWalletSettings view")
            case .backUpNow: return NSLocalizedString("backup_wallet_settings.item.backup_now", comment: "BackupWalletSettings view")
            case .backUpWithRecoveryPhrase: return NSLocalizedString("backup_wallet_settings.item.with_recovery_phrase", comment: "BackupWalletSettings view")

            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let backupItem = backupNowSectionItems.first(where: { $0.title == BackupWalletSettingsItem.backUpNow.rawValue }) else { return }
        backUpWalletItem = backupItem
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func onBackupNowAction() {
        let localAuth = LAContext()
        localAuth.authenticateUser(reason: .userVerification) { [weak self] in
            do {
                try self?.iCloudBackup.createWalletBackup()
            } catch {
                UserFeedback.shared.error(title: NSLocalizedString("iCloud_backup.error.title", comment: "iCloudBackup error"), description: "", error: error)
            }
            self?.updateMarks()
        }
    }

    private func onChangePasswordAction() {

    }

    private func onBackupWithRecoveryPhraseAction() {
        navigationController?.pushViewController(SeedPhraseViewController(), animated: true)
    }
}

extension BackupWalletSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return iCloudBackup.backupExists() ? 1 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .settings: return settingsSectionItems.count
        case .backUpNow: return backupNowSectionItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SystemMenuTableViewCell.self), for: indexPath) as! SystemMenuTableViewCell
        guard let section = Section(rawValue: indexPath.section) else { return cell }

        switch section {
        case .settings: cell.configure(settingsSectionItems[indexPath.row])
        case .backUpNow: cell.configure(backupNowSectionItems[indexPath.row])
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
        if tableView.numberOfSections - 1 == section && iCloudBackup.backupExists() {
            return 50.0
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableView.numberOfSections - 1 != section {
            return nil
        }

        if let lastBackupString = ICloudBackup.shared.lastBackupString {
            let footer = UIView()
            footer.backgroundColor = .clear

            let lastBackupLabel =  UILabel()
            lastBackupLabel.font = Theme.shared.fonts.settingsTableViewLastBackupDate
            lastBackupLabel.textColor =  Theme.shared.colors.settingsTableViewLastBackupDate

            lastBackupLabel.text = NSLocalizedString("Last successful backup: \(lastBackupString)", comment: "Settings view")

            footer.addSubview(lastBackupLabel)

            lastBackupLabel.translatesAutoresizingMaskIntoConstraints = false
            lastBackupLabel.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 25).isActive = true
            lastBackupLabel.topAnchor.constraint(equalTo: footer.topAnchor, constant: 8).isActive = true

            return footer
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = Section(rawValue: section) else { return nil }

        if section == .backUpNow {
            return nil
        }

        let header = UIView()
        header.backgroundColor = .clear

        let label = UILabel()
        label.font = Theme.shared.fonts.settingsTableViewHeader
        label.text = NSLocalizedString("backup_wallet_settings.header.title", comment: "BackupWalletSettings view")

        header.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 25).isActive = true
        label.topAnchor.constraint(equalTo: header.topAnchor, constant: 30).isActive = true

        let desctiptionLabel = UILabel()
        desctiptionLabel.numberOfLines = 0
        desctiptionLabel.font = Theme.shared.fonts.settingsSeedPhraseDescription
        desctiptionLabel.textColor = Theme.shared.colors.settingsSeedPhraseDescription
        desctiptionLabel.text = NSLocalizedString("backup_wallet_settings.header.description", comment: "BackupWalletSettings view")

        header.addSubview(desctiptionLabel)

        desctiptionLabel.translatesAutoresizingMaskIntoConstraints = false
        desctiptionLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 25).isActive = true
        desctiptionLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 25).isActive = true
        desctiptionLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -25).isActive = true
        desctiptionLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -25).isActive = true

        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .settings:
            let item = BackupWalletSettingsItem.allCases[indexPath.row]
            if item == .changePassword {
                onChangePasswordAction()
            }
        case .backUpNow:
            let item = BackupWalletSettingsItem.allCases[indexPath.row + settingsSectionItems.count]
            if item == .backUpNow {
                onBackupNowAction()
            }
        }
    }
}
