//  BluetoothSettingsView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 20/04/2023
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
import TariCommon

final class BluetoothSettingsView: BaseNavigationContentView {

    struct Section {
        let header: String?
        let items: [SelectableCell.ViewModel]
    }

    // MARK: - Subview

    @View private var tableView: BaseMenuTableView = {
        let view = BaseMenuTableView()
        view.register(type: SelectableCell.self)
        return view
    }()

    // MARK: - Properties

    var viewModels: [Section] = [] {
        didSet { update(sections: viewModels) }
    }

    var onSelectRow: ((UUID) -> Void)?

    private var dataSource: UITableViewDiffableDataSource<Int, SelectableCell.ViewModel>?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        navigationBar.title = localized("bluetooth_settings.title")
    }

    private func setupConstraints() {

        addSubview(tableView)

        let constraints = [
            tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: SelectableCell.self, indexPath: indexPath)
            cell.update(model: model)
            return cell
        }

        tableView.delegate = self
    }

    // MARK: - Updates

    private func update(sections: [Section]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, SelectableCell.ViewModel>()

        sections
            .enumerated()
            .forEach {
                snapshot.appendSections([$0])
                snapshot.appendItems($1.items)
            }

        dataSource?.applySnapshotUsingReloadData(snapshot)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.updateHeaderFrame()
    }
}

extension BluetoothSettingsView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < viewModels.count else { return nil }
        let model = viewModels[section]

        let headerView = tableView.dequeueReusableHeaderFooterView(type: BluetoothSettingsHeaderView.self)
        headerView.text = model.header

        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < viewModels.count, indexPath.row < viewModels[indexPath.section].items.count else { return }
        let model = viewModels[indexPath.section].items[indexPath.row]
        onSelectRow?(model.id)
    }
}
