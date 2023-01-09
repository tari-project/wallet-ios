//  BridgesConfigurationViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 01.09.2020
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
import Combine

final class BridgesConfigurationViewController: SettingsParentTableViewController, CustomBridgesHandable {

    typealias BridgesType = OnionSettings.BridgesType

    private lazy var bridgesConfiguration: BridgesConfiguration = {
        OnionSettings.currentlyUsedBridgesConfiguration
    }()

    private enum Section: Int {
        case chooseBridge = 1
    }

    private var cancellables = Set<AnyCancellable>()

    private enum BridgesConfigurationItemTitle: CaseIterable {
        case requestBridgesFromTorproject
        case noBridges
        case custom

        var rawValue: String {
            switch self {
            case .requestBridgesFromTorproject: return localized("bridges_configuration.item.request_bridges_from_torproject")

            case .noBridges: return localized("bridges_configuration.item.noBridges")
            case .custom: return localized("bridges_configuration.item.custom")
            }
        }
    }

    private lazy var chooseBridgeSectionItems: [SystemMenuTableViewCellItem] = {
        getBridgeSectionItems()
    }()

    private func getBridgeSectionItems() -> [SystemMenuTableViewCellItem] {
        [
            SystemMenuTableViewCellItem(title: BridgesConfigurationItemTitle.noBridges.rawValue, mark: Tari.shared.torBridgesConfiguration.bridgesType == BridgesType.none ? .scheduled : .none, hasArrow: false),
            SystemMenuTableViewCellItem(title: BridgesConfigurationItemTitle.custom.rawValue, mark: Tari.shared.torBridgesConfiguration.bridgesType == BridgesType.custom ? .scheduled : .none)
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        setupCustomBridgeProgressHandler()
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        chooseBridgeSectionItems = getBridgeSectionItems()
        tableView.reloadData()
    }
}

// MARK: Setup subviews
extension BridgesConfigurationViewController {
    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.title = localized("bridges_configuration.title")
        navigationBar.rightButton.isEnabled = false
        navigationBar.onRightButtonAction = { [weak self] in
            guard let self = self else { return }
            self.navigationBar.progress = 0.0
            self.navigationBar.rightButton.isEnabled = false
            self.view.isUserInteractionEnabled = false
            Task { [weak self] in
                do {
                    guard let self = self else { return }
                    try await Tari.shared.update(torBridgesConfiguration: self.bridgesConfiguration)
                    self.onCustomBridgeSuccessAction()
                } catch {
                    self?.onCustomBridgeFailureAction(error: error)
                }
            }
        }

        let title = localized("bridges_configuration.connect")
        navigationBar.rightButton.setTitle(title, for: .normal)
        navigationBar.rightButton.titleLabel?.font = Theme.shared.fonts.settingsDoneButton
    }
}

extension BridgesConfigurationViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .chooseBridge:
            return chooseBridgeSectionItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SystemMenuTableViewCell.self), for: indexPath) as! SystemMenuTableViewCell
        guard let section = Section(rawValue: indexPath.section) else { return cell }

        switch section {
        case .chooseBridge: cell.configure(chooseBridgeSectionItems[indexPath.row])
        }

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        65
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0.0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let section = Section(rawValue: section), section == .chooseBridge  else { return nil }
        return BridgesConfigurationFooterView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .chooseBridge:
            let raw = BridgesConfigurationItemTitle.allCases[indexPath.section + indexPath.row]

            switch raw {
            case .noBridges:
                bridgesConfiguration.bridgesType = BridgesType.none
                bridgesConfiguration.customBridges = nil

            case .custom:
                bridgesConfiguration.bridgesType = OnionSettings.currentlyUsedBridgesConfiguration.bridgesType
                bridgesConfiguration.customBridges = OnionSettings.currentlyUsedBridgesConfiguration.customBridges
                navigationController?.pushViewController(CustomBridgesViewController(bridgesConfiguration: bridgesConfiguration), animated: true)
            default:
                return
            }

            navigationBar.rightButton.isEnabled = OnionSettings.currentlyUsedBridgesConfiguration.bridgesType != bridgesConfiguration.bridgesType && bridgesConfiguration.bridgesType != .custom

            chooseBridgeSectionItems.forEach { (item) in
                item.mark = .none
            }
            chooseBridgeSectionItems[indexPath.row].mark = .scheduled
        }
    }
}
