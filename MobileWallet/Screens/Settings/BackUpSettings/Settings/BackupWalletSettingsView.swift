//  BackupWalletSettingsView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 20/10/2022
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
import TariCommon

final class BackupWalletSettingsView: BaseNavigationContentView {

    // MARK: - Subviews

    @TariView private var tableView: BaseMenuTableView = {
        let view = BaseMenuTableView()
        view.register(type: SystemMenuTableViewCell.self)
        return view
    }()

    // MARK: - Properties

    var onSelectRow: ((IndexPath) -> Void)?

    private var dataSource: UITableViewDiffableDataSource<Int, SystemMenuTableViewCellItem>?

    // MARK: - Initializers

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
        navigationBar.title = localized("backup_wallet_settings.title")
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
            let cell = tableView.dequeueReusableCell(type: SystemMenuTableViewCell.self, indexPath: indexPath)
            cell.configure(model)
            return cell
        }

        tableView.delegate = self
    }

    // MARK: - Actions

    func update(models: [SystemMenuTableViewCellItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, SystemMenuTableViewCellItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(models)
        dataSource?.apply(snapshot)
    }
}

extension BackupWalletSettingsView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        BackupWalletSettingsHeaderView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelectRow?(indexPath)
    }
}
