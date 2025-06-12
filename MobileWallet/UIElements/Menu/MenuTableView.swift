//  MenuTableView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 27/02/2023
	Using Swift 5.0
	Running on macOS 13.0

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

final class MenuTableView: DynamicThemeTableView {

    struct Section {
        let title: String?
        let items: [MenuCell.ViewModel]
    }

    // MARK: - Properties

    var viewModel: [Section] = [] {
        didSet { update(viewModel: viewModel) }
    }

    var onSelectRow: ((_ id: UInt) -> Void)?

    private var tableDataSource: UITableViewDiffableDataSource<Int, MenuCell.ViewModel>?

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero, style: .grouped)
        registerReusableViews()
        setupView()
        setupTableView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func registerReusableViews() {
        register(type: MenuCell.self)
        register(headerFooterType: MenuTableHeaderView.self)
    }

    private func setupView() {
        showsVerticalScrollIndicator = false
        rowHeight = UITableView.automaticDimension
    }

    private func setupTableView() {

        tableDataSource = UITableViewDiffableDataSource(tableView: self, cellProvider: { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: MenuCell.self, indexPath: indexPath)
            cell.viewModel = model
            return cell
        })

        delegate = self
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        backgroundColor = theme.backgrounds.secondary
        separatorColor = theme.neutral.secondary
    }

    private func update(viewModel: [Section]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, MenuCell.ViewModel>()

        viewModel
            .enumerated()
            .forEach {
                snapshot.appendSections([$0])
                snapshot.appendItems($1.items)
        }

        tableDataSource?.applySnapshotUsingReloadData(snapshot)
    }
}

extension MenuTableView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard let title = viewModel[section].title else { return nil }

        let headerView = tableView.dequeueReusableHeaderFooterView(type: MenuTableHeaderView.self)
        headerView.title = title
        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? MenuCell, let cellID = cell.viewModel?.id else { return }
        onSelectRow?(cellID)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        viewModel[section].title == nil ? 0.0 : UITableView.automaticDimension
    }
}
