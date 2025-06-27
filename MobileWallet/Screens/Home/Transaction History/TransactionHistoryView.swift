//  TransactionHistoryView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 05/07/2023
	Using Swift 5.0
	Running on macOS 13.4

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

import TariCommon
import Combine

final class TransactionHistoryView: BaseNavigationContentView {

    struct ViewModel {
        let sectionTitle: String?
        let items: [TransactionHistoryCell.ViewModel]
    }

    // MARK: - Subviews

    @TariView private var searchTextField: SearchField = {
        let view = SearchField()
        view.placeholder = localized("transaction_history.search_field.placeholder")
        return view
    }()

    @TariView private var tableView: UITableView = {
        let view = UITableView()
        view.showsVerticalScrollIndicator = false
        view.estimatedRowHeight = 44.0
        view.rowHeight = UITableView.automaticDimension
        view.separatorInset = UIEdgeInsets(top: 0.0, left: 22.0, bottom: 0.0, right: 22.0)
        view.keyboardDismissMode = .interactive
        view.sectionHeaderTopPadding = .zero
        view.register(type: TransactionHistoryCell.self)
        view.register(headerFooterType: MenuTableHeaderView.self)
        return view
    }()

    // MARK: - Properties

    var searchText: AnyPublisher<String, Never> { searchTextSubject.eraseToAnyPublisher() }

    var onCellTap: ((_ id: UInt64) -> Void)?

    private let searchTextSubject = CurrentValueSubject<String, Never>("")
    private var viewModels: [ViewModel] = []
    private var dataSource: UITableViewDiffableDataSource<Int, TransactionHistoryCell.ViewModel>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupNavigationBar()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupNavigationBar() {
        navigationBar.title = localized("transaction_history.title")
    }

    private func setupConstraints() {

        [searchTextField, tableView].forEach(addSubview)

        let constraints = [
            searchTextField.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 20.0),
            searchTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30.0),
            searchTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30.0),
            tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20.0),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, viewModel in
            let cell = tableView.dequeueReusableCell(type: TransactionHistoryCell.self, indexPath: indexPath)

            cell.onContentChange = { [weak self] in
                self?.updateCells(indexPath: indexPath)
            }

            cell.update(viewModel: viewModel)

            return cell
        }

        tableView.dataSource = dataSource
        tableView.delegate = self

        searchTextField.bind(withSubject: searchTextSubject, storeIn: &cancellables)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
        tableView.backgroundColor = theme.backgrounds.primary
    }

    func update(transactions: [ViewModel]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, TransactionHistoryCell.ViewModel>()

        transactions.enumerated().forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($1.items)
        }

        viewModels = transactions
        dataSource?.applySnapshotUsingReloadData(snapshot)
    }

    private func updateCells(indexPath: IndexPath) {
        guard tableView.indexPathsForVisibleRows?.first(where: { $0 == indexPath }) != nil else { return }
        tableView.resizeCellsWithoutAnimation()
    }
}

extension TransactionHistoryView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = viewModels[indexPath.section].items[indexPath.row].id
        onCellTap?(identifier)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(type: MenuTableHeaderView.self)
        view.title = viewModels[section].sectionTitle
        return view
    }
}
