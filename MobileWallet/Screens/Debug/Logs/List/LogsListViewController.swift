//  LogsListViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 17/10/2022
	Using Swift 5.0
	Running on macOS 12.6

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

final class LogsListViewController: SecureViewController<LogsListView> {

    // MARK: - Properties

    private let model: LogsListModel
    private var tableDataSource: UITableViewDiffableDataSource<Int, String>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: LogsListModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupCallbacks()
        model.refreshLogsList()
    }

    // MARK: - Setups

    private func setupTableView() {
        mainView.tableView.register(type: LogsListCell.self)
    }

    private func setupCallbacks() {

        model.$logTitles
            .sink { [weak self] in self?.update(items: $0) }
            .store(in: &cancellables)

        model.$selectedRowFileURL
            .compactMap { $0 }
            .sink { [weak self] in self?.moveToLogDetails(url: $0) }
            .store(in: &cancellables)

        model.$errorMessage
            .compactMap { $0 }
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)

        tableDataSource = UITableViewDiffableDataSource(tableView: mainView.tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: LogsListCell.self, indexPath: indexPath)
            cell.update(title: model)
            return cell
        }

        mainView.tableView.dataSource = tableDataSource
        mainView.tableView.delegate = self
    }

    // MARK: - Actions

    private func update(items: [String]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)

        tableDataSource?.apply(snapshot)
    }

    private func moveToLogDetails(url: URL) {
        let controller = LogConstructor.buildScene(fileURL: url)
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension LogsListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        model.select(row: indexPath.row)
    }
}
