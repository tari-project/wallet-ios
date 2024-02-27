//  SelectBaseNodeViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 16/07/2021
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

final class SelectBaseNodeViewController: SettingsParentTableViewController {

    // MARK: - Properties

    private let model = SelectBaseNodeModel()
    private var dataSource: UITableViewDiffableDataSource<Int, SelectBaseNodeModel.NodeModel>?
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.refreshData()
    }

    // MARK: - Setups

    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.title = localized("select_base_node.title")
        navigationBar.update(rightButton: NavigationBar.ButtonModel(image: UIImage(systemName: "plus.bubble"), callback: { [weak self] in self?.presentAddBaseNodeScreen() }))
    }

    override func setupViews() {
        super.setupViews()
        tableView.register(type: SelectBaseNodeCell.self)
    }

    private func setupCallbacks() {

        tableView.delegate = self

        dataSource = UITableViewDiffableDataSource<Int, SelectBaseNodeModel.NodeModel>(tableView: tableView) { [weak self] tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: SelectBaseNodeCell.self, indexPath: indexPath)
            var accessoryType: SelectBaseNodeCell.AccessoryType = model.isSelected ? .tick : .none

            if model.canBeRemoved {
                accessoryType = .deleteButton
            }

            cell.update(
                title: model.title,
                subtitle: model.subtitle,
                accessoryType: accessoryType
            )

            cell.onDeleteButtonTap = {
                self?.model.deleteNode(index: indexPath.row)
            }

            return cell
        }

        tableView.dataSource = dataSource

        model.$nodes
            .sink { [weak self] models in
                var snapshot = NSDiffableDataSourceSnapshot<Int, SelectBaseNodeModel.NodeModel>()
                snapshot.appendSections([0])
                snapshot.appendItems(models, toSection: 0)
                self?.dataSource?.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &cancellables)

        model.$errorMessaage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func presentAddBaseNodeScreen() {
        let controller = AddBaseNodeViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension SelectBaseNodeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { model.selectNode(index: indexPath.row) }
}
