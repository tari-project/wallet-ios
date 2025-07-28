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

import LocalAuthentication
import Combine
import TariCommon

final class SettingsViewController: SettingsParentTableViewController {
    private let localAuth = LAContext()

    private enum Section: Int, CaseIterable {
        case security
        case more
        case advancedSettings
    }

    private enum SettingsHeaderTitle: CaseIterable {
        case profileHeader
        case securityHeader
        case moreHeader
        case advancedSettingsHeader

        var rawValue: String {
            switch self {
            case .profileHeader: ""
            case .securityHeader: localized("settings.item.header.security")
            case .moreHeader: localized("settings.item.header.more")
            case .advancedSettingsHeader: localized("settings.item.header.advanced_settings")
            }
        }
    }

    private enum SettingsItemTitle: CaseIterable {
        case backUpWallet
        case dataCollection

        case about
        case reportBug
        case visitTari
        case contributeToTariAurora
        case userAgreement
        case privacyPolicy
        case disclaimer
        case blockExplorer

        case selectTheme
        case screenRecording
        case selectNetwork
        case selectBaseNode
        case deleteWallet

        var rawValue: String {
            switch self {
            case .backUpWallet: localized("settings.item.wallet_backups")
            case .dataCollection: localized("settings.item.data_collection")
            case .selectTheme: localized("settings.item.select_theme")
            case .screenRecording: localized("settings.item.screen_recording_settings")
            case .selectNetwork: localized("settings.item.select_network")
            case .selectBaseNode: localized("settings.item.select_base_node")
            case .deleteWallet: localized("settings.item.delete_wallet")

            case .about: localized("settings.item.about")
            case .reportBug: localized("settings.item.report_bug")
            case .visitTari: localized("settings.item.visit_tari")
            case .contributeToTariAurora: localized("settings.item.contribute_to_tari")
            case .userAgreement: localized("settings.item.user_agreement")
            case .privacyPolicy: localized("settings.item.privacy_policy")
            case .disclaimer: localized("settings.item.disclaimer")
            case .blockExplorer: localized("settings.item.block_explorer")
            }
        }
    }

    private let backUpWalletItem = SystemMenuTableViewCellItem(icon: .Icons.Settings.walletBackups, title: SettingsItemTitle.backUpWallet.rawValue, disableCellInProgress: false)
    private let screenRecordingItem = SystemMenuTableViewCellItem(icon: .Icons.Settings.camera, title: SettingsItemTitle.screenRecording.rawValue)

    private lazy var securitySectionItems: [SystemMenuTableViewCellItem] = [
        backUpWalletItem,
        SystemMenuTableViewCellItem(icon: .Icons.General.analytics, title: SettingsItemTitle.dataCollection.rawValue)
    ]

    private lazy var advancedSettingsSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(icon: .Icons.Settings.theme, title: SettingsItemTitle.selectTheme.rawValue),
        screenRecordingItem,
        SystemMenuTableViewCellItem(icon: .Icons.Settings.network, title: SettingsItemTitle.selectNetwork.rawValue),
        SystemMenuTableViewCellItem(icon: .Icons.Settings.delete, title: SettingsItemTitle.deleteWallet.rawValue, isDestructive: true)
    ]

    private let moreSectionItems: [SystemMenuTableViewCellItem] = {

        var items = [
            SystemMenuTableViewCellItem(icon: .Icons.Settings.about, title: SettingsItemTitle.about.rawValue),
            SystemMenuTableViewCellItem(icon: .Icons.Settings.reportBug, title: SettingsItemTitle.reportBug.rawValue),
            SystemMenuTableViewCellItem(icon: .Icons.Settings.visitTari, title: SettingsItemTitle.visitTari.rawValue),
            SystemMenuTableViewCellItem(icon: .Icons.Settings.contribute, title: SettingsItemTitle.contributeToTariAurora.rawValue),
            SystemMenuTableViewCellItem(icon: .Icons.Settings.userAgreement, title: SettingsItemTitle.userAgreement.rawValue),
            SystemMenuTableViewCellItem(icon: .Icons.Settings.privacyPolicy, title: SettingsItemTitle.privacyPolicy.rawValue),
            SystemMenuTableViewCellItem(icon: .Icons.Settings.disclaimer, title: SettingsItemTitle.disclaimer.rawValue),
        ]

        if NetworkManager.shared.selectedNetwork.isBlockExplorerAvailable {
            items.append(SystemMenuTableViewCellItem(icon: .Icons.Settings.blockExplorer, title: SettingsItemTitle.blockExplorer.rawValue))
        }

        return items
    }()

    private let links: [SettingsItemTitle: URL?] = [
        .visitTari: URL(string: TariSettings.shared.tariUrl),
        .contributeToTariAurora: URL(string: TariSettings.shared.contributeUrl),
        .userAgreement: URL(string: TariSettings.shared.userAgreementUrl),
        .privacyPolicy: URL(string: TariSettings.shared.privacyPolicyUrl),
        .disclaimer: URL(string: TariSettings.shared.disclaimer),
        .blockExplorer: NetworkManager.shared.selectedNetwork.blockExplorerURL
    ]
    
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = SettingsViewFooter()
        tableView.register(type: SettingsProfileCell.self)
        setupCallbacks()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.updateFooterFrame()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TrackingConsentManager.handleTrackingConsent()
    }

    private func setupCallbacks() {

        BackupManager.shared.$syncState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateItems(syncStatus: $0) }
            .store(in: &cancellables)

        SecurityManager.shared.$areScreenshotsDisabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.screenRecordingItem.mark = $0 ? .none : .attention }
            .store(in: &cancellables)
    }

    private func onBackupWalletAction() {
        localAuth.authenticateUser(reason: .userVerification, showFailedDialog: false) { [weak self] in
            let controller = BackupWalletSettingsConstructor.buildScene(backButtonType: .back)
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func onDataCollectionAction() {
        let controller = DataCollectionSettingsConstructor.buildScene()
        navigationController?.pushViewController(controller, animated: true)
    }

    private func onAboutAction() {
        let controller = AboutViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

    private func onReportBugAction() {
        let controller = BugReportingConstructor.buildScene()
        present(controller, animated: true)
    }

    private func onSelectThemeAction() {
        let controller = ThemeSettingsConstructor.buildScene()
        navigationController?.pushViewController(controller, animated: true)
    }

    private func onScreenRecordingSettingsAction() {
        let controller = ScreenRecordingSettingsConstructor.buildScene(backButtonType: .back)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func onSelectNetworkAction() {
        navigationController?.pushViewController(SelectNetworkViewController(), animated: true)
    }

    private func onDeleteWalletAction() {
        let deleteWalletViewController = DeleteWalletViewController()
        navigationController?.pushViewController(deleteWalletViewController, animated: true)
    }

    private func onLinkAction(indexPath: IndexPath) {
        let item = SettingsItemTitle.allCases[indexPath.row + indexPath.section + 1]

        guard let link = links[item], let url = link else { return }
        WebBrowserPresenter.open(url: url)
    }

    private func onProfileAction() {
        let controller = ProfileViewController()
        navigationController?.pushViewController(controller, animated: true)
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
        case .advancedSettings:
            cell.configure(advancedSettingsSectionItems[indexPath.row])
        }

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sec = Section(rawValue: section)

        switch sec {
        case .security, .advancedSettings, .more:
            break
        default:
            return nil
        }

        let header = MenuTableHeaderView()
        header.title = SettingsHeaderTitle.allCases[section].rawValue

        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let section = Section(rawValue: indexPath.section) else { return nil }
        switch section {
        case .security:
            switch indexPath.row {
            case 0:
                onBackupWalletAction()
            case 1:
                onDataCollectionAction()
            default:
                break
            }
        case .more:
            let item = moreSectionItems[indexPath.row]
            switch item.title {
            case SettingsItemTitle.about.rawValue:
                onAboutAction()
            case SettingsItemTitle.reportBug.rawValue:
                onReportBugAction()
            case SettingsItemTitle.visitTari.rawValue,
                 SettingsItemTitle.contributeToTariAurora.rawValue,
                 SettingsItemTitle.userAgreement.rawValue,
                 SettingsItemTitle.privacyPolicy.rawValue,
                 SettingsItemTitle.disclaimer.rawValue,
                 SettingsItemTitle.blockExplorer.rawValue:
                 
                onLinkAction(indexPath: indexPath)
            default:
                break
            }
        case .advancedSettings:
            switch indexPath.row {
            case 0:
                onSelectThemeAction()
            case 1:
                onScreenRecordingSettingsAction()
            case 2:
                onSelectNetworkAction()
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
        navigationBar.backButtonType = .none
    }
}
