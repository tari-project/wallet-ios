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
import Combine

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

        case about
        case reportBug
        case visitTari
        case contributeToTariAurora
        case userAgreement
        case privacyPolicy
        case disclaimer
        case blockExplorer

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

            case .about: return localized("settings.item.about")
            case .reportBug: return localized("settings.item.report_bug")
            case .visitTari: return localized("settings.item.visit_tari")
            case .contributeToTariAurora: return localized("settings.item.contribute_to_tari")
            case .userAgreement: return localized("settings.item.user_agreement")
            case .privacyPolicy: return localized("settings.item.privacy_policy")
            case .disclaimer: return localized("settings.item.disclaimer")
            case .blockExplorer: return localized("settings.item.block_explorer")
            }
        }
    }
    
    private let backUpWalletItem = SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsWalletBackupsIcon, title: SettingsItemTitle.backUpWallet.rawValue, disableCellInProgress: false)

    private lazy var securitySectionItems: [SystemMenuTableViewCellItem] = [backUpWalletItem]

    private let advancedSettingsSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsBridgeConfigIcon, title: SettingsItemTitle.torBridgeConfiguration.rawValue),
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsNetworkIcon, title: SettingsItemTitle.selectNetwork.rawValue),
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsBaseNodeIcon, title: SettingsItemTitle.selectBaseNode.rawValue),
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsDeleteIcon, title: SettingsItemTitle.deleteWallet.rawValue, isDestructive: true)
    ]

    private let moreSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsAboutIcon, title: SettingsItemTitle.about.rawValue),
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsReportBugIcon, title: SettingsItemTitle.reportBug.rawValue),
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsVisitTariIcon, title: SettingsItemTitle.visitTari.rawValue),
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsContributeIcon, title: SettingsItemTitle.contributeToTariAurora.rawValue),
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsUserAgreementIcon, title: SettingsItemTitle.userAgreement.rawValue),
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsPrivacyPolicyIcon, title: SettingsItemTitle.privacyPolicy.rawValue),
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsDisclaimerIcon, title: SettingsItemTitle.disclaimer.rawValue),
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsBlockExplorerIcon, title: SettingsItemTitle.blockExplorer.rawValue)
    ]

    private let yatSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(icon: Theme.shared.images.settingsYatIcon, title: SettingsItemTitle.connectYats.rawValue)
    ]

    private let links: [SettingsItemTitle: URL?] = [
        .visitTari: URL(string: TariSettings.shared.tariUrl),
        .contributeToTariAurora: URL(string: TariSettings.shared.contributeUrl),
        .userAgreement: URL(string: TariSettings.shared.userAgreementUrl),
        .privacyPolicy: URL(string: TariSettings.shared.privacyPolicyUrl),
        .disclaimer: URL(string: TariSettings.shared.disclaimer),
        .blockExplorer: URL(string: TariSettings.shared.blockExplorerUrl)
    ]
    
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = SettingsViewFooter()
        setupCallbacks()
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
    
    private func setupCallbacks() {
        BackupManager.shared.$syncState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateItems(syncStatus: $0) }
            .store(in: &cancellables)
    }

    private func onBackupWalletAction() {
        localAuth.authenticateUser(reason: .userVerification, showFailedDialog: false) { [weak self] in
            let controller = BackupWalletSettingsConstructor.buildScene()
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    private func onAboutAction() {
        let controller = AboutViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

    private func onReportBugAction() {
        let controller = BugReportingConstructor.buildScene()
        present(controller, animated: true)
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
        
        guard let link = links[item], let url = link else { return }
        WebBrowserPresenter.open(url: url)
    }

    private func onConnectYatAction() {
        
        let address: String
        
        do {
            address = try Tari.shared.walletAddress.byteVector.hex
        } catch {
            showNoConnectionError()
            return
        }
        
        Yat.integration.showOnboarding(onViewController: self, records: [
            YatRecordInput(tag: .XTRAddress, value: address)
        ])
    }
    
    private func showNoConnectionError() {
        PopUpPresenter.show(message: MessageModel(title: localized("common.error"), message: localized("settings.error.connect_yats_no_connection"), type: .error))
    }
    
    private func updateItems(syncStatus: BackupManager.BackupSyncState) {
        
        backUpWalletItem.percent = 0.0
        
        switch syncStatus {
        case .disabled:
            backUpWalletItem.mark = .attention
            backUpWalletItem.markDescription = ""
        case .outOfSync:
            backUpWalletItem.mark = .attention
            backUpWalletItem.markDescription = localized("wallet_backup_state.out_to_date")
        case let .inProgress(progress):
            backUpWalletItem.mark = .progress
            backUpWalletItem.percent = progress * 100.0
            backUpWalletItem.markDescription = localized("wallet_backup_state.in_progress")
        case .synced:
            backUpWalletItem.mark = .success
            backUpWalletItem.markDescription = localized("wallet_backup_state.up_to_date")
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
        case .security, .advancedSettings, .yat, .more:
            header.heightAnchor.constraint(equalToConstant: 70).isActive = true
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
            switch SettingsItemTitle.allCases[indexPath.row + indexPath.section] {
            case .about:
                onAboutAction()
            case .reportBug:
                onReportBugAction()
            default:
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

        let popUpModel = PopUpDialogModel(
            title: localized("settings.pasteboard.custom_base_node.pop_up.title"),
            message: localized("settings.pasteboard.custom_base_node.pop_up.message", arguments: pasteboardText),
            buttons: [
                PopUpDialogButtonModel(title: localized("settings.pasteboard.custom_base_node.pop_up.button.confirm"), type: .normal, callback: { [weak self] in self?.update(baseNode: baseNode) }),
                PopUpDialogButtonModel(title: localized("settings.pasteboard.custom_base_node.pop_up.button.cancel"), type: .text, callback: { UIPasteboard.general.string = "" })
            ],
            hapticType: .none
        )
        
        PopUpPresenter.showPopUp(model: popUpModel)
    }

    private func update(baseNode: BaseNode) {
        do {
            try Tari.shared.connection.select(baseNode: baseNode)
            UIPasteboard.general.string = ""
        } catch {
            PopUpPresenter.show(message: MessageModel(title: localized("settings.pasteboard.custom_base_node.error.title"), message: localized("settings.pasteboard.custom_base_node.error.message"), type: .error))
        }
    }
}
