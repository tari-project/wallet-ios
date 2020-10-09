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
    private let localAuth = LAContext()

    private enum Section: Int, CaseIterable {
        case security
        case advancedSettings
        case more
    }

    private enum SettingsHeaderTitle: CaseIterable {
        case securityHeader
        case advancedSettingsHeader
        case moreHeader

        var rawValue: String {
            switch self {
            case .securityHeader: return NSLocalizedString("settings.item.header.security", comment: "Settings view")
            case .advancedSettingsHeader: return NSLocalizedString("settings.item.header.advanced_settings", comment: "Settings view")
            case .moreHeader: return NSLocalizedString("settings.item.header.more", comment: "Settings view")
            }
        }
    }

    private enum SettingsItemTitle: CaseIterable {
        case backUpWallet

        case advancedSettings

        case reportBug
        case visitTari
        case contributeToTariAurora
        case userAgreement
        case privacyPolicy
        case disclaimer

        var rawValue: String {
            switch self {
            case .backUpWallet: return NSLocalizedString("settings.item.wallet_backups", comment: "Settings view")

            case .advancedSettings:return NSLocalizedString("settings.item.bridge_configuration", comment: "Settings view")

            case .reportBug: return NSLocalizedString("settings.item.report_bug", comment: "Settings view")
            case .visitTari: return NSLocalizedString("settings.item.visit_tari", comment: "Settings view")
            case .contributeToTariAurora: return NSLocalizedString("settings.item.contribute_to_tari", comment: "Settings view")
            case .userAgreement: return NSLocalizedString("settings.item.user_agreement", comment: "Settings view")
            case .privacyPolicy: return NSLocalizedString("Privacy Policy", comment: "Settings view")
            case .disclaimer: return NSLocalizedString("settings.item.disclaimer", comment: "Settings view")
            }
        }
    }

    private let securitySectionItems: [SystemMenuTableViewCellItem] = [SystemMenuTableViewCellItem(title: SettingsItemTitle.backUpWallet.rawValue, disableCellInProgress: false)]

    private let advancedSettingsSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: SettingsItemTitle.advancedSettings.rawValue)]

    private let moreSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: SettingsItemTitle.reportBug.rawValue),
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkClipboardForBaseNode()
    }

    func onBackupWalletAction() {
        localAuth.authenticateUser(reason: .userVerification, showFailedDialog: false) { [weak self] in
            self?.navigationController?.pushViewController(BackupWalletSettingsViewController(), animated: true)
        }
    }

    func onBridgeConfigurationAction() {
        let bridgesConfigurationViewController = BridgesConfigurationViewController()
        navigationController?.pushViewController(bridgesConfigurationViewController, animated: true)
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
        case .advancedSettings: return advancedSettingsSectionItems.count
        case .more: return moreSectionItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SystemMenuTableViewCell.self), for: indexPath) as! SystemMenuTableViewCell

        guard let section = Section(rawValue: indexPath.section) else { return cell }
        switch section {
        case .security: cell.configure(securitySectionItems[indexPath.row])
        case .advancedSettings: cell.configure(advancedSettingsSectionItems[indexPath.row])
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
        case .security, .more:
            header.heightAnchor.constraint(equalToConstant: 70).isActive = true
        case .advancedSettings:
            let lastSuccessful = iCloudBackup.lastBackup != nil && !iCloudBackup.inProgress && !iCloudBackup.isLastBackupFailed
            if lastSuccessful, let lastBackupString = ICloudBackup.shared.lastBackup?.dateCreationString {
                header.heightAnchor.constraint(equalToConstant: 101).isActive = true

                let lastBackupLabel =  UILabel()
                lastBackupLabel.font = Theme.shared.fonts.settingsTableViewLastBackupDate
                lastBackupLabel.textColor =  Theme.shared.colors.settingsTableViewLastBackupDate

                lastBackupLabel.text = String(format: NSLocalizedString("settings.last_successful_backup.with_param", comment: "Settings view"), lastBackupString)

                header.addSubview(lastBackupLabel)

                lastBackupLabel.translatesAutoresizingMaskIntoConstraints = false
                lastBackupLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 25).isActive = true
                lastBackupLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -25).isActive = true
                lastBackupLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 8).isActive = true
                lastBackupLabel.lineBreakMode = .byTruncatingMiddle
            } else {
                header.heightAnchor.constraint(equalToConstant: 70).isActive = true
            }
        default: break
        }

        let label = UILabel()
        label.font = Theme.shared.fonts.settingsViewHeader
        label.text = SettingsHeaderTitle.allCases[section].rawValue

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
        case .advancedSettings: onBridgeConfigurationAction()
        case .more:
            if SettingsItemTitle.allCases[indexPath.row + indexPath.section] == .reportBug {
                onSendFeedback()
            } else {
                onLinkAction(indexPath: indexPath)
            }
        }
    }
}

// MARK: Setup subviews
extension SettingsViewController {
    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.backButton.isHidden = true
        if modalPresentationStyle != .popover { return }
        navigationBar.rightButtonAction = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        let title = NSLocalizedString("settings.done", comment: "Settings view")
        navigationBar.rightButton.setTitle(title, for: .normal)
        navigationBar.rightButton.setTitleColor(Theme.shared.colors.settingsDoneButtonTitle, for: .normal)
        navigationBar.rightButton.titleLabel?.font = Theme.shared.fonts.settingsDoneButton
    }

    fileprivate func checkClipboardForBaseNode() {
        let pasteboardString: String? = UIPasteboard.general.string
        guard let clipboardText = pasteboardString else { return }

        do {
            let baseNode = try BaseNode(clipboardText)

            UserFeedback.shared.callToAction(
                title: NSLocalizedString("Set custom base node", comment: "Custom base node in clipboard call to action"),
                description: String(
                    format: NSLocalizedString(
                        "We found a base node peer in your clipboard, would you like to use this instead of the default?\n\n%@",
                        comment: "Custom base node in clipboard call to action"
                    ),
                    clipboardText
                ),
                actionTitle: NSLocalizedString("Set", comment: "Custom base node in clipboard call to action"),
                cancelTitle: NSLocalizedString("Keep default", comment: "Custom base node in clipboard call to action"),
                onAction: {
                    do {
                        try TariLib.shared.setBasenode(baseNode)
                        UIPasteboard.general.string = ""
                    } catch {
                        UserFeedback.shared.error(
                            title: NSLocalizedString("Base node error", comment: "Add base node peer error"),
                            description: NSLocalizedString("Failed to set custom base node from clipboard", comment: "Custom base node in clipboard call to action"),
                            error: error
                        )
                    }
                },
                onCancel: {
                    UIPasteboard.general.string = ""
                }
            )
        } catch {
            //No valid peer string found in clipboard
        }
    }
}
