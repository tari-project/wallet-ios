//  UTXOsWalletTextListView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 08/06/2022
	Using Swift 5.0
	Running on macOS 12.3

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
import Combine

final class UTXOsWalletTextListView: DynamicThemeView {

    // MARK: - Subviews

    @TariView private var tableView: UITableView = {
        let view = UITableView()
        view.separatorInset = UIEdgeInsets(top: 0.0, left: 30.0, bottom: 0.0, right: 30.0)
        view.backgroundColor = .clear
        view.register(type: UTXOsWalletTextListViewCell.self)
        return view
    }()

    // MARK: - Properties

    @Published var models: [UTXOsWalletTextListViewCell.Model] = []
    @Published var verticalContentInset: CGFloat = 0.0
    @Published var isEditingEnabled: Bool = false
    @Published var selectedElements: Set<UUID> = []
    @Published private(set) var verticalContentOffset: CGFloat = 0.0

    var onTapOnCell: ((UUID) -> Void)?

    private var dataSource: UITableViewDiffableDataSource<Int, UTXOsWalletTextListViewCell.Model>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
        setupCallbacks()
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

    private func setupCallbacks() {

        $models
            .sink { [weak self] in self?.updateCells(models: $0) }
            .store(in: &cancellables)

        $verticalContentInset
            .map { UIEdgeInsets(top: $0, left: 0.0, bottom: 0.0, right: 0.0) }
            .sink { [weak self] in
                self?.tableView.contentInset = $0
                self?.tableView.scrollToTop(animated: false)
            }
            .store(in: &cancellables)

        $isEditingEnabled
            .sink { [weak self] in self?.updateCellsState(isEditing: $0) }
            .store(in: &cancellables)

        $selectedElements
            .sink { [weak self] in self?.update(selectedElements: $0) }
            .store(in: &cancellables)

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, model in

            guard let self = self else { return UITableViewCell() }

            let cell = tableView.dequeueReusableCell(type: UTXOsWalletTextListViewCell.self, indexPath: indexPath)

            cell.update(model: model)
            cell.update(isSelectable: model.isSelectable, isEditingEnabled: self.isEditingEnabled, animated: false)
            cell.isTickSelected = self.selectedElements.contains(model.id)

            return cell
        }

        dataSource?.defaultRowAnimation = .fade
        tableView.delegate = self
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        tableView.backgroundColor = theme.backgrounds.primary
        tableView.separatorColor = theme.neutral.secondary
    }

    private func update(selectedElements: Set<UUID>) {
        tableView.visibleCells
            .compactMap { $0 as? UTXOsWalletTextListViewCell }
            .forEach {
                guard let elementID = $0.elementID else { return }
                $0.isTickSelected = selectedElements.contains(elementID)
            }
    }

    private func updateCells(models: [UTXOsWalletTextListViewCell.Model]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UTXOsWalletTextListViewCell.Model>()
        snapshot.appendSections([0])
        snapshot.appendItems(models, toSection: 0)
        dataSource?.apply(snapshot)
    }

    private func updateCellsState(isEditing: Bool) {
        tableView.visibleCells
            .compactMap { $0 as? UTXOsWalletTextListViewCell }
            .forEach { cell in
                guard let isSelectable = models.first(where: { $0.id == cell.elementID })?.isSelectable else { return }
                cell.update(isSelectable: isSelectable, isEditingEnabled: isEditing, animated: true)
            }
    }
}

extension UTXOsWalletTextListView: UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        verticalContentOffset = scrollView.contentOffset.y
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onTapOnCell?(models[indexPath.row].id)
    }
}

private extension UTXOsWalletTextListViewCell {

    func update(isSelectable: Bool, isEditingEnabled: Bool, animated: Bool) {
        updateTickBox(isVisible: isSelectable && isEditingEnabled, animated: animated)
        updateBackground(isSemitransparent: !isSelectable && isEditingEnabled, animated: animated)
    }
}
