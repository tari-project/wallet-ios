//  ContactBookContactListView.swift

/*
	Package MobileWallet
	Created by Browncoat on 21/02/2023
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

final class ContactBookContactListView: DynamicThemeView {

    struct ViewModel: Identifiable, Hashable {
        let id: UUID
        let name: String
        let avatar: String
        let isFavorite: Bool
        let menuItems: [ContactCapsuleMenu.ButtonViewModel]
    }

    // MARK: - Subviews

    @View private var tableView: UITableView = {
        let view = UITableView()
        view.estimatedRowHeight = 44.0
        view.rowHeight = UITableView.automaticDimension
        view.keyboardDismissMode = .interactive
        view.register(type: ContactBookCell.self)
        view.separatorInset = UIEdgeInsets(top: 0.0, left: 22.0, bottom: 0.0, right: 22.0)
        return view
    }()

    // MARK: - Properties

    var viewModels: [ViewModel] = [] {
        didSet { update(viewModels: viewModels) }
    }

    var onButtonTap: ((UUID, UInt) -> Void)?

    private var expandedIndex: IndexPath? {
        didSet { updateCellsState() }
    }

    private var dataSource: UITableViewDiffableDataSource<Int, ViewModel>?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
        setupTableView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        addSubview(tableView)

        let constraints = [
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupTableView() {

        let dataSource = UITableViewDiffableDataSource<Int, ViewModel>(tableView: tableView) { [weak self] tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: ContactBookCell.self, indexPath: indexPath)
            cell.update(name: model.name, avatar: model.avatar, isFavorite: model.isFavorite, menuItems: model.menuItems)
            cell.isExpanded = indexPath == self?.expandedIndex
            cell.onButtonTap = { self?.onButtonTap?(model.id, $0) }
            cell.onExpand = { [weak self] in self?.expandedIndex = indexPath }
            return cell
        }

        tableView.delegate = self
        tableView.dataSource = dataSource

        self.dataSource = dataSource
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        tableView.backgroundColor = theme.backgrounds.primary
        tableView.separatorColor = theme.neutral.secondary
    }

    private func update(viewModels: [ViewModel]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, ViewModel>()

        snapshot.appendSections([0])
        snapshot.appendItems(viewModels)

        dataSource?.apply(snapshot: snapshot)
    }

    private func updateCellsState() {
        tableView.visibleCells
            .compactMap { $0 as? ContactBookCell }
            .forEach { [weak self] in
                guard let index = self?.tableView.indexPath(for: $0), index != self?.expandedIndex else { return }
                $0.isExpanded = false
            }
    }
}

extension ContactBookContactListView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? ContactBookCell
        cell?.isExpanded.toggle()
    }
}
