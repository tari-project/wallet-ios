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

    private lazy var iCloudBackup: ICloudBackup = {
        let backup = ICloudBackup.shared
        backup.addObserver(self)
        return backup
    }()

    private let items: [SystemMenuTableViewCellItem] = [SystemMenuTableViewCellItem(title: BackupWalletSettingsItem.backUpToiCloud.rawValue, mark: .attention)]
        // SystemMenuTableViewCellItem(title: BackupWalletSettingsItem.backUpWithRecoveryPhrase.localized(), mark: .attention)]

    private lazy var iCloudBackupItem: SystemMenuTableViewCellItem = {
        return self.items.first(where: { $0.title == BackupWalletSettingsItem.backUpToiCloud.rawValue })!
    }()

    private enum BackupWalletSettingsItem: CaseIterable {
        case backUpToiCloud
        case backUpWithRecoveryPhrase

        var rawValue: String {
            switch self {
            case .backUpToiCloud: return NSLocalizedString("Back up to iCloud", comment: "BackupWalletSettingsItem")
            case .backUpWithRecoveryPhrase: return NSLocalizedString("Back up with recovery phrase", comment: "BackupWalletSettingsItem")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        NotificationCenter.default.addObserver(self, selector: #selector(updateMarks), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMarks()
    }

    private func onBackupToiCloudAction() {
        let localAuth = LAContext()
        localAuth.authenticateUser(reason: .userVerification) { [weak self] in
            do {
                try self?.iCloudBackup.createWalletBackup()
                self?.iCloudBackupItem.mark = .progress
            } catch {
                UserFeedback.shared.error(title: NSLocalizedString("Failed to create backup", comment: "Backup wallet settings"), description: "", error: error)
                self?.iCloudBackupItem.mark = .attention
            }
        }
    }

    private func onBackupWithRecoveryPhraseAction() {
        navigationController?.pushViewController(SeedPhraseViewController(), animated: true)
    }

    @objc private func updateMarks() {
        if iCloudBackup.inProgress {
            iCloudBackupItem.mark = .progress
            iCloudBackupItem.percent = iCloudBackup.progressValue
            return
        }

        iCloudBackupItem.mark = iCloudBackup.backupExists() ? .success : .attention
    }
}

extension BackupWalletSettingsViewController: ICloudBackupObserver {
    func onUploadProgress(percent: Double, completed: Bool, error: Error?) {
        if error != nil {
            UserFeedback.shared.error(title: NSLocalizedString("Failed to create backup", comment: "Backup wallet settings"), description: "", error: error)
            iCloudBackupItem.mark = .attention
            return
        }

        iCloudBackupItem.percent = percent

        if completed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.iCloudBackupItem.mark = .success
                self?.iCloudBackupItem.percent = 0.0
            }
        }
    }
}

extension BackupWalletSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SystemMenuTableViewCell.self), for: indexPath) as! SystemMenuTableViewCell
        cell.configure(items[indexPath.row])
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        65
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear

        let label = UILabel()
        label.font = Theme.shared.fonts.settingsTableViewHeader
        label.text = NSLocalizedString("Back Up Wallet", comment: "Back Up Waallet header")

        header.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 25).isActive = true
        label.topAnchor.constraint(equalTo: header.topAnchor, constant: 30).isActive = true

        let desctiptionLabel = UILabel()
        desctiptionLabel.numberOfLines = 0
        desctiptionLabel.font = Theme.shared.fonts.settingsSeedPhraseDescription
        desctiptionLabel.textColor = Theme.shared.colors.settingsSeedPhraseDescription
        desctiptionLabel.text = NSLocalizedString("By backing up your wallet, you’ll ensure that you don’t lose your tXTR if your phone is lost or broken.", comment: "Back Up Waallet header description")

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
        let item = BackupWalletSettingsItem.allCases[indexPath.row + indexPath.section]
        switch item {
        case .backUpToiCloud: onBackupToiCloudAction()
        case .backUpWithRecoveryPhrase: onBackupWithRecoveryPhraseAction()
        }
    }
}
