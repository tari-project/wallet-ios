//  CustomTorBridgesView.swift

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

final class CustomTorBridgesView: BaseNavigationContentView {

    enum Row: UInt {
        case input
        case requestBridges
        case scanQRCode
        case uploadQRCode
    }

    // MARK: - Subviews

    @View private var tableView: BaseMenuTableView = {
        let view = BaseMenuTableView()
        view.register(type: CustomTorBridgesInputCell.self)
        view.register(type: MenuCell.self)
        view.register(headerFooterType: CustomTorBridgesHeaderView.self)
        return view
    }()

    // MARK: - Properties

    private var text: String?

    var isConnectButtonEnabled: Bool {
        get { navigationBar.rightButton(index: 0)?.isEnabled ?? false }
        set { navigationBar.rightButton(index: 0)?.isEnabled = newValue }
    }

    var onSelectRow: ((Row) -> Void)?
    var onConnectButtonTap: (() -> Void)?
    var onTextUpdate: ((String) -> Void)?

    private var dataSource: UITableViewDiffableDataSource<Int, Row>?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
        setupRows()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        navigationBar.title = localized("custom_bridges.title")
        navigationBar.update(rightButton: NavigationBar.ButtonModel(title: localized("custom_bridges.connect"), callback: { [weak self] in
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

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, model in
            guard let self else { return UITableViewCell() }
            return self.cell(tableView: tableView, indexPath: indexPath, row: model)
        }

        tableView.delegate = self
    }

    private func setupRows() {

        var snapshot = NSDiffableDataSourceSnapshot<Int, Row>()

        snapshot.appendSections([0, 1, 2])
        snapshot.appendItems([.input], toSection: 0)
        snapshot.appendItems([.requestBridges], toSection: 1)
        snapshot.appendItems([.scanQRCode, .uploadQRCode], toSection: 2)

        dataSource?.applySnapshotUsingReloadData(snapshot)
    }

    // MARK: - Updates

    func update(torBridgesText: String?) {
        guard text != torBridgesText else { return }
        text = torBridgesText
        setupRows()
    }

    // MARK: - Constructors

    private func cell(tableView: UITableView, indexPath: IndexPath, row: Row) -> UITableViewCell {

        switch row {
        case .input:

            let cell = tableView.dequeueReusableCell(type: CustomTorBridgesInputCell.self, indexPath: indexPath)
            cell.text = text
            cell.onTextUpdate = { [weak self] in
                self?.text = $0
                self?.onTextUpdate?($0)
            }

            return cell
        case .requestBridges:
            let cell = tableView.dequeueReusableCell(type: MenuCell.self, indexPath: indexPath)
            cell.viewModel = MenuCell.ViewModel(id: row.rawValue, title: localized("custom_bridges.item.request_bridges_from_torproject"), isArrowVisible: true, isDestructive: false)
            return cell
        case .scanQRCode:
            let cell = tableView.dequeueReusableCell(type: MenuCell.self, indexPath: indexPath)
            cell.viewModel = MenuCell.ViewModel(id: row.rawValue, title: localized("custom_bridges.item.scan_QR_code"), isArrowVisible: true, isDestructive: false)
            return cell
        case .uploadQRCode:
            let cell = tableView.dequeueReusableCell(type: MenuCell.self, indexPath: indexPath)
            cell.viewModel = MenuCell.ViewModel(id: row.rawValue, title: localized("custom_bridges.item.upload_QR_code"), isArrowVisible: true, isDestructive: false)
            return cell
        }
    }
}

extension CustomTorBridgesView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? MenuCell, let identifier = cell.viewModel?.id, let row = Row(rawValue: identifier) else { return }
        onSelectRow?(row)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        return tableView.dequeueReusableHeaderFooterView(type: CustomTorBridgesHeaderView.self)
    }
}
