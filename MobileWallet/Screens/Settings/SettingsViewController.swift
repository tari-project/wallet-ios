//  SettingsViewController.swift

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

class SettingsViewController: SettingsParentTableViewController {

    private enum Section: Int, CaseIterable {
        case security
        case more
    }

    private enum SettingsHeaderTitle {
        case securityHeader
        case moreHeader

        var rawValue: String {
            switch self {
            case .securityHeader: return NSLocalizedString("settings.item.header.security", comment: "Settings view")
            case .moreHeader: return NSLocalizedString("settings.item.header.more", comment: "Settings view")
            }
        }
    }

    private enum SettingsItemTitle: CaseIterable {
        case backUpWallet

        case visitTari
        case contributeToTariAurora
        case userAgreement
        case privacyPolicy
        case disclaimer

        var rawValue: String {
            switch self {
            case .backUpWallet: return NSLocalizedString("settings.item.backup_wallet", comment: "Settings view")

            case .visitTari: return NSLocalizedString("settings.item.visit_tari", comment: "Settings view")
            case .contributeToTariAurora: return NSLocalizedString("settings.item.contribute_to_tari", comment: "Settings view")
            case .userAgreement: return NSLocalizedString("settings.item.user_agreement", comment: "Settings view")
            case .privacyPolicy: return NSLocalizedString("Privacy Policy", comment: "Settings view")
            case .disclaimer: return NSLocalizedString("settings.item.disclaimer", comment: "Settings view")
            }
        }
    }

    private let headers: [SettingsHeaderTitle] = [.securityHeader, .moreHeader]
    private let securitySectionItems: [SystemMenuTableViewCellItem] = [SystemMenuTableViewCellItem(title: SettingsItemTitle.backUpWallet.rawValue, disableCellInProgress: false)]

    private let moreSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: SettingsItemTitle.visitTari.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.contributeToTariAurora.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.userAgreement.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.privacyPolicy.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.disclaimer.rawValue)]

    private let links: [SettingsItemTitle: URL?] = [
        .visitTari: URL(string: TariSettings.shared.tariUrl),
        .contributeToTariAurora: URL(string: TariSettings.shared.contributeUrl),
        .userAgreement: URL(string: TariSettings.shared.userAgreementUrl),
        .privacyPolicy: URL(string: TariSettings.shared.privacyPolicyUrl),
        .disclaimer: URL(string: TariSettings.shared.disclaimer)]

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let backupItem = securitySectionItems.first(where: { $0.title == SettingsItemTitle.backUpWallet.rawValue }) else { return }
        backUpWalletItem = backupItem
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func onBackupWalletAction() {
        let localAuth = LAContext()
        localAuth.authenticateUser(reason: .userVerification) { [weak self] in
            self?.navigationController?.pushViewController(BackupWalletSettingsViewController(), animated: true)
        }
    }

    private func onLinkAction(indexPath: IndexPath) {
        let item = SettingsItemTitle.allCases[indexPath.row + indexPath.section]
        if let url = links[item] {
            UserFeedback.shared.openWebBrowser(url: url!)
        }
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .security: return securitySectionItems.count
        case .more: return moreSectionItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SystemMenuTableViewCell.self), for: indexPath) as! SystemMenuTableViewCell

        guard let section = Section(rawValue: indexPath.section) else { return cell }
        switch section {
        case .security: cell.configure(securitySectionItems[indexPath.row])
        case .more: cell.configure(moreSectionItems[indexPath.row])
        }

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        let sec = Section(rawValue: section)

        switch sec {
        case .security:
            header.heightAnchor.constraint(equalToConstant: 70).isActive = true
        case .more:
            if iCloudBackup.backupExists(), let lastBackupString = ICloudBackup.shared.lastBackupString {
                header.heightAnchor.constraint(equalToConstant: 101).isActive = true

                let lastBackupLabel =  UILabel()
                lastBackupLabel.font = Theme.shared.fonts.settingsTableViewLastBackupDate
                lastBackupLabel.textColor =  Theme.shared.colors.settingsTableViewLastBackupDate

                lastBackupLabel.text = NSLocalizedString("Last successful backup: \(lastBackupString)", comment: "Settings view")

                header.addSubview(lastBackupLabel)

                lastBackupLabel.translatesAutoresizingMaskIntoConstraints = false
                lastBackupLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 25).isActive = true
                lastBackupLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 8).isActive = true
            } else {
                header.heightAnchor.constraint(equalToConstant: 70).isActive = true
            }
        default: break
        }

        let label = UILabel()
        label.font = Theme.shared.fonts.settingsViewHeader
        label.text = headers[section].rawValue

        header.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 25).isActive = true
        label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -15).isActive = true

        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard let section = Section(rawValue: indexPath.section) else { return }
        switch section {
        case .security: onBackupWalletAction()
        case .more: onLinkAction(indexPath: indexPath)
        }
    }
}

// MARK: Setup subviews
extension SettingsViewController {
    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.backButton.isHidden = true
        navigationBar.rightButtonAction = { [weak self] in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }

        let title = NSLocalizedString("settings.done", comment: "Settings view")
        navigationBar.rightButton.setTitle(title, for: .normal)
        navigationBar.rightButton.setTitleColor(Theme.shared.colors.settingsDoneButtonTitle, for: .normal)
        navigationBar.rightButton.titleLabel?.font = Theme.shared.fonts.settingsDoneButton
    }
}
