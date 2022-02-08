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
import YatLib

class SettingsViewController: SettingsParentTableViewController {
    private let localAuth = LAContext()

    private enum Section: Int, CaseIterable {
        case security
        case more
        case yat
        case advancedSettings
    }

    private enum SettingsHeaderTitle: CaseIterable {
        case securityHeader
        case moreHeader
        case yatHeader
        case advancedSettingsHeader

        var rawValue: String {
            switch self {
            case .securityHeader: return localized("settings.item.header.security")
            case .moreHeader: return localized("settings.item.header.more")
            case .yatHeader: return localized("settings.item.header.yat")
            case .advancedSettingsHeader: return localized("settings.item.header.advanced_settings")
            }
        }
    }

    private enum SettingsItemTitle: CaseIterable {
        case backUpWallet

        case reportBug
        case visitTari
        case contributeToTariAurora
        case userAgreement
        case privacyPolicy
        case disclaimer

        case connectYats

        case torBridgeConfiguration
        case selectNetwork
        case selectBaseNode
        case deleteWallet

        var rawValue: String {
            switch self {
            case .backUpWallet: return localized("settings.item.wallet_backups")

            case .torBridgeConfiguration: return localized("settings.item.bridge_configuration")
            case .selectNetwork: return localized("settings.item.select_network")
            case .selectBaseNode: return localized("settings.item.select_base_node")
            case .deleteWallet: return localized("settings.item.delete_wallet")

            case .connectYats: return localized("settings.item.connect_yats")

            case .reportBug: return localized("settings.item.report_bug")
            case .visitTari: return localized("settings.item.visit_tari")
            case .contributeToTariAurora: return localized("settings.item.contribute_to_tari")
            case .userAgreement: return localized("settings.item.user_agreement")
            case .privacyPolicy: return localized("settings.item.privacy_policy")
            case .disclaimer: return localized("settings.item.disclaimer")
            }
        }
    }

    private let securitySectionItems: [SystemMenuTableViewCellItem] = [SystemMenuTableViewCellItem(title: SettingsItemTitle.backUpWallet.rawValue, disableCellInProgress: false)]

    private let advancedSettingsSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: SettingsItemTitle.torBridgeConfiguration.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.selectNetwork.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.selectBaseNode.rawValue),
        SystemMenuTableViewCellItem(
            title: SettingsItemTitle.deleteWallet.rawValue,
            isDestructive: true
        )
    ]

    private let moreSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: SettingsItemTitle.reportBug.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.visitTari.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.contributeToTariAurora.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.userAgreement.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.privacyPolicy.rawValue),
        SystemMenuTableViewCellItem(title: SettingsItemTitle.disclaimer.rawValue)]

    private let yatSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: SettingsItemTitle.connectYats.rawValue)
    ]

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
        tableView.tableFooterView = SettingsViewFooter()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkClipboardForBaseNode()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let footerView = tableView.tableFooterView else { return }
        
        let width = tableView.bounds.width
        let size = footerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))
        
        guard footerView.bounds.height != size.height else { return }
        
        footerView.bounds.size.height = size.height
        tableView.tableFooterView = footerView
    }

    private func onBackupWalletAction() {
        localAuth.authenticateUser(reason: .userVerification, showFailedDialog: false) { [weak self] in
            self?.navigationController?.pushViewController(BackupWalletSettingsViewController(), animated: true)
        }
    }

    private func onBridgeConfigurationAction() {
        let bridgesConfigurationViewController = BridgesConfigurationViewController()
        navigationController?.pushViewController(bridgesConfigurationViewController, animated: true)
    }

    private func onSelectNetworkAction() {
        navigationController?.pushViewController(SelectNetworkViewController(), animated: true)
    }

    private func onSelectBaseNodeAction() {
        navigationController?.pushViewController(SelectBaseNodeViewController(), animated: true)
    }

    private func onDeleteWalletAction() {
        let deleteWalletViewController = DeleteWalletViewController()
        navigationController?.pushViewController(deleteWalletViewController, animated: true)
    }

    private func onLinkAction(indexPath: IndexPath) {
        let item = SettingsItemTitle.allCases[indexPath.row + indexPath.section]
        if let url = links[item] {
            UserFeedback.shared.openWebBrowser(url: url!)
        }
    }

    private func onConnectYatAction() {
        
        guard let publicKey = TariLib.shared.tariWallet?.publicKey.0?.hex.0 else {
            showNoConnectionError()
            return
        }
        
        Yat.integration.showOnboarding(onViewController: self, records: [
            YatRecordInput(tag: .XTRAddress, value: publicKey)
        ])
    }
    
    private func showNoConnectionError() {
        UserFeedback.showError(title: localized("common.error"), description: localized("settings.error.connect_yats_no_connection"))
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
        case .yat: return yatSectionItems.count
        case .advancedSettings: return advancedSettingsSectionItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(type: SystemMenuTableViewCell.self, indexPath: indexPath)

        guard let section = Section(rawValue: indexPath.section) else { return cell }
        switch section {
        case .security:
            cell.configure(securitySectionItems[indexPath.row])
        case .more:
            cell.configure(moreSectionItems[indexPath.row])
        case .yat:
            cell.configure(yatSectionItems[indexPath.row])
            break
        case .advancedSettings:
            cell.configure(advancedSettingsSectionItems[indexPath.row])
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
        case .security, .advancedSettings, .yat:
            header.heightAnchor.constraint(equalToConstant: 70).isActive = true
        case .more:
            let lastSuccessful = iCloudBackup.lastBackup != nil && !iCloudBackup.inProgress && !iCloudBackup.isLastBackupFailed
            if lastSuccessful, let lastBackupString = ICloudBackup.shared.lastBackup?.dateCreationString {
                header.heightAnchor.constraint(equalToConstant: 101).isActive = true

                let lastBackupLabel =  UILabel()
                lastBackupLabel.font = Theme.shared.fonts.settingsTableViewLastBackupDate
                lastBackupLabel.textColor =  Theme.shared.colors.settingsTableViewLastBackupDate

                lastBackupLabel.text = String(format: localized("settings.last_successful_backup.with_param"), lastBackupString)

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

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let section = Section(rawValue: indexPath.section) else { return nil }
        switch section {
        case .security: onBackupWalletAction()
        case .more:
            if SettingsItemTitle.allCases[indexPath.row + indexPath.section] == .reportBug {
                onSendFeedback()
            } else {
                onLinkAction(indexPath: indexPath)
            }
        case .yat:
            switch indexPath.row {
            case 0:
                onConnectYatAction()
            default:
                break
            }
        case .advancedSettings:
            switch indexPath.row {
            case 0:
                onBridgeConfigurationAction()
            case 1:
                onSelectNetworkAction()
            case 2:
                onSelectBaseNodeAction()
            case 3:
                onDeleteWalletAction()
            default:
                break
            }
        }

        return nil
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

        let title = localized("settings.done")
        navigationBar.rightButton.setTitle(title, for: .normal)
        navigationBar.rightButton.setTitleColor(Theme.shared.colors.settingsDoneButtonTitle, for: .normal)
        navigationBar.rightButton.titleLabel?.font = Theme.shared.fonts.settingsDoneButton
    }

    private func checkClipboardForBaseNode() {
        guard let pasteboardText = UIPasteboard.general.string, let baseNode = try? BaseNode(name: "From Pasteboard", peer: pasteboardText) else { return }

        UserFeedback.shared.callToAction(
            title: localized("Set custom base node"),
            description: localized("We found a base node peer in your clipboard, would you like to use this instead of the default?\n\n\(pasteboardText)"),
            actionTitle: localized("Set"),
            cancelTitle: localized("Keep default"),
            onAction: { [weak self] in self?.update(baseNode: baseNode) },
            onCancel: { UIPasteboard.general.string = "" }
        )
    }

    private func update(baseNode: BaseNode) {
        do {
            try TariLib.shared.update(baseNode: baseNode, syncAfterSetting: true)
            UIPasteboard.general.string = ""
        } catch {
            UserFeedback.showError(
                title: localized("Base node error"),
                description: localized("Failed to set custom base node from clipboard")
            )
        }
    }
}
