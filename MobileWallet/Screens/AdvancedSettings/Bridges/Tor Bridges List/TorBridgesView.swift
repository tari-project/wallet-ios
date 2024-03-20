//  TorBridgesView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 04/09/2023
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

final class TorBridgesView: BaseNavigationContentView {

    enum Row: Int, CaseIterable {
        case noBridges
        case customBridges
    }

    // MARK: - Subviews

    @View private var tableView: BaseMenuTableView = {
        let view = BaseMenuTableView()
        view.register(type: AccessoryImageMenuCell.self)
        view.register(headerFooterType: TorBridgesFooterView.self)
        return view
    }()

    // MARK: - Properties

    var isConnectButtonEnabled: Bool {
        get { navigationBar.rightButton(index: 0)?.isEnabled ?? false }
        set { navigationBar.rightButton(index: 0)?.isEnabled = newValue }
    }

    var onSelectedRow: ((Row) -> Void)?
    var onConnectButtonTap: (() -> Void)?

    private var dataSource: UITableViewDiffableDataSource<Int, AccessoryImageMenuCell.ViewModel>?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupNavigationBar()
        setupConstraints()
        setupCallbacks()
        setupCells(selectedRow: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupNavigationBar() {
        navigationBar.title = localized("bridges_configuration.title")
        navigationBar.update(rightButton: NavigationBar.ButtonModel(title: localized("bridges_configuration.connect"), callback: { [weak self] in
            self?.onConnectButtonTap?()
        }))
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

        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, viewModel in
            let cell = tableView.dequeueReusableCell(type: AccessoryImageMenuCell.self, indexPath: indexPath)
            cell.update(viewModel: viewModel)
            return cell
        })

        tableView.delegate = self
    }

    private func setupCells(selectedRow: Row?) {

        let items = Row
            .allCases
            .map {
                AccessoryImageMenuCell.ViewModel(
                    baseModel: MenuCell.ViewModel(
                        id: UInt($0.rawValue),
                        title: $0.title,
                        isArrowVisible: $0.isArrorVisible,
                        isDestructive: false
                    ),
                    accessoryImage: selectedRow == $0 ? Theme.shared.images.scheduledIcon : nil
                )
            }

        var snapshot = NSDiffableDataSourceSnapshot<Int, AccessoryImageMenuCell.ViewModel>()

        snapshot.appendSections([0])
        snapshot.appendItems(items)

        dataSource?.applySnapshotUsingReloadData(snapshot)
    }

    // MARK: - Actions

    func select(row: Row) {
        setupCells(selectedRow: row)
    }
}

extension TorBridgesView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = Row(rawValue: indexPath.row) else { return }
        onSelectedRow?(row)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        tableView.dequeueReusableHeaderFooterView(type: TorBridgesFooterView.self)
    }
}

private extension TorBridgesView.Row {

    var title: String {
        switch self {
        case .noBridges:
            return localized("bridges_configuration.item.noBridges")
        case .customBridges:
            return localized("bridges_configuration.item.custom")
        }
    }

    var isArrorVisible: Bool {
        switch self {
        case .noBridges:
            return false
        case .customBridges:
            return true
        }
    }
}
