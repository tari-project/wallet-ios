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
        case profile
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
            case .profileHeader: return ""
            case .securityHeader: return localized("settings.item.header.security")
            case .moreHeader: return localized("settings.item.header.more")
            case .advancedSettingsHeader: return localized("settings.item.header.advanced_settings")
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
        case bluetoothConfiguration
        case torBridgeConfiguration
        case selectNetwork
        case selectBaseNode
        case deleteWallet

        var rawValue: String {
            switch self {
            case .backUpWallet: return localized("settings.item.wallet_backups")
            case .dataCollection: return localized("settings.item.data_collection")

            case .selectTheme: return localized("settings.item.select_theme")
            case .screenRecording: return localized("settings.item.screen_recording_settings")
            case .bluetoothConfiguration: return localized("settings.item.bluetooth_settings")
            case .torBridgeConfiguration: return localized("settings.item.bridge_configuration")
            case .selectNetwork: return localized("settings.item.select_network")
            case .selectBaseNode: return localized("settings.item.select_base_node")
            case .deleteWallet: return localized("settings.item.delete_wallet")

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

    private let backUpWalletItem = SystemMenuTableViewCellItem(icon: .Icons.Settings.walletBackups, title: SettingsItemTitle.backUpWallet.rawValue, disableCellInProgress: false)
    private let screenRecordingItem = SystemMenuTableViewCellItem(icon: .Icons.Settings.camera, title: SettingsItemTitle.screenRecording.rawValue)

    private lazy var securitySectionItems: [SystemMenuTableViewCellItem] = [
        backUpWalletItem,
        SystemMenuTableViewCellItem(icon: .Icons.General.analytics, title: SettingsItemTitle.dataCollection.rawValue)
    ]

    private lazy var advancedSettingsSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(icon: .Icons.Settings.theme, title: SettingsItemTitle.selectTheme.rawValue),
        screenRecordingItem,
        SystemMenuTableViewCellItem(icon: .Icons.Settings.bluetooth, title: SettingsItemTitle.bluetoothConfiguration.rawValue),
        SystemMenuTableViewCellItem(icon: .Icons.Settings.bridgeConfig, title: SettingsItemTitle.torBridgeConfiguration.rawValue),
        SystemMenuTableViewCellItem(icon: .Icons.Settings.network, title: SettingsItemTitle.selectNetwork.rawValue),
        SystemMenuTableViewCellItem(icon: .Icons.Settings.baseNode, title: SettingsItemTitle.selectBaseNode.rawValue),
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

    private let profileIndexPath = IndexPath(row: 0, section: 0)
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

    private func onBluetoothSettingsAction() {
        let controller = BluetoothSettingsConstructor.buildScene()
        navigationController?.pushViewController(controller, animated: true)
    }

    private func onBridgeConfigurationAction() {
        let controller = TorBridgesConstructor.buildScene()
        navigationController?.pushViewController(controller, animated: true)
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

    private func onProfileAction() {
        let controller = ProfileViewController(backButtonType: .back)
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
        case .profile: return 1
        case .security: return securitySectionItems.count
        case .more: return moreSectionItems.count
        case .advancedSettings: return advancedSettingsSectionItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath == profileIndexPath {
            let cell = tableView.dequeueReusableCell(type: SettingsProfileCell.self, indexPath: indexPath)
            do {
                let name = UserSettingsManager.name
                let addressComponents = try Tari.shared.walletAddress.components
                let addressViewModel = AddressView.ViewModel(prefix: addressComponents.networkAndFeatures, text: .truncated(prefix: addressComponents.spendKeyPrefix, suffix: addressComponents.spendKeySuffix), isDetailsButtonVisible: false)
                cell.update(name: name, addressViewModel: addressViewModel)
            } catch {
                let message = ErrorMessageManager.errorModel(forError: error)
                PopUpPresenter.show(message: message)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(type: SystemMenuTableViewCell.self, indexPath: indexPath)

        guard let section = Section(rawValue: indexPath.section) else { return cell }
        switch section {
        case .profile:
            break
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
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath == profileIndexPath else { return 65.0 }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let section = Section(rawValue: indexPath.section) else { return nil }
        switch section {
        case .profile:
            switch indexPath.row {
            case 0:
                onProfileAction()
            default:
                break
            }
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
            switch SettingsItemTitle.allCases[indexPath.row + indexPath.section] {
            case .about:
                onAboutAction()
            case .reportBug:
                onReportBugAction()
            default:
                onLinkAction(indexPath: indexPath)
            }
        case .advancedSettings:
            switch indexPath.row {
            case 0:
                onSelectThemeAction()
            case 1:
                onScreenRecordingSettingsAction()
            case 2:
                onBluetoothSettingsAction()
            case 3:
                onBridgeConfigurationAction()
            case 4:
                onSelectNetworkAction()
            case 5:
                onSelectBaseNodeAction()
            case 6:
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
