//  SelectNetworkViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 26/08/2021
	Using Swift 5.0
	Running on macOS 12.0

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

final class SelectNetworkViewController: SettingsParentTableViewController {

    // MARK: - Properties

    private let model = SelectNetworkModel()
    private var tableDataSource: UITableViewDiffableDataSource<Int, SystemMenuTableViewCellItem>?
    private var cancelables = Set<AnyCancellable>()

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFeedbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.refreshData()
    }

    // MARK: - Setups

    override func setupViews() {
        super.setupViews()
        navigationBar.title = localized("select_network.title")
    }

    private func setupFeedbacks() {

        tableDataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: SystemMenuTableViewCell.self, indexPath: indexPath)
            cell.configure(model)
            return cell
        }

        tableView.dataSource = tableDataSource
        tableView.delegate = self

        model.viewModel.$networkModels
            .sink { [weak self] in self?.updateTableView(models: $0) }
            .store(in: &cancelables)
    }

    // MARK: - Updates

    private func updateTableView(models: [SelectNetworkModel.NetworkModel]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, SystemMenuTableViewCellItem>()

        let items = models
            .enumerated()
            .map { SystemMenuTableViewCellItem(title: $1.networkName, mark: $1.isSelected ? .scheduled : .none, hasArrow: false) }

        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)

        tableDataSource?.apply(snapshot, animatingDifferences: false)
    }
}

extension SelectNetworkViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 65.0 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard model.viewModel.selectedIndex != indexPath.row else { return }

        UserFeedback.shared.callToAction(title: localized("select_network.dialog.switch_network.title"), description: localized("select_network.dialog.switch_network.description"),
                                         actionTitle: localized("common.continue"), cancelTitle: localized("common.cancel")) { [weak self] in
            self?.model.update(selectedIndex: indexPath.row)
        }

    }
}
