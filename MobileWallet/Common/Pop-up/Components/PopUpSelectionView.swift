//  PopUpSelectionView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 28/06/2022
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

final class PopUpSelectionView: UIView {

    private struct Model: Identifiable, Hashable {
        let id: UUID
        let title: String
    }

    // MARK: - Subviews

    @View private var tableView: PopUpTableView = {
        let view = PopUpTableView()
        view.register(type: PopUpSelectionCell.self)
        return view
    }()

    // MARK: - Properties

    private(set) var selectedIndex: Int = 0
    private var dataSource: UITableViewDiffableDataSource<Int, Model>?

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
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

        let dataSource = UITableViewDiffableDataSource<Int, Model>(tableView: tableView) { [weak self] tableView, indexPath, model in
            guard let self = self else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(type: PopUpSelectionCell.self, indexPath: indexPath)
            cell.text = model.title
            cell.isSelected = indexPath.row == self.selectedIndex
            return cell
        }

        self.dataSource = dataSource

        tableView.onSelectRow = { [weak self] selectedIndexPath in
            self?.tableView.visibleCells.forEach { $0.isSelected = false }
            self?.tableView.cellForRow(at: selectedIndexPath)?.isSelected = true
            self?.selectedIndex = selectedIndexPath.row
        }
    }

    // MARK: - Actions

    func update(options: [String], selectedIndex: Int) {

        self.selectedIndex = selectedIndex

        let models = options.map { Model(id: UUID(), title: $0) }

        var snapshot = NSDiffableDataSourceSnapshot<Int, Model>()
        snapshot.appendSections([0])
        snapshot.appendItems(models)

        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

private class PopUpSelectionCell: DynamicThemeCell {

    // MARK: - Subviews

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = .Poppins.Medium.withSize(15.0)
        return view
    }()

    @View private var tickIcon: UIImageView = {
        let view = UIImageView()
        view.image = .Icons.General.tick
        view.contentMode = .scaleAspectFit
        view.alpha = 0.0
        return view
    }()

    // MARK: - Properties

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    override var isSelected: Bool {
        didSet { tickIcon.alpha = isSelected ? 1.0 : 0.0 }
    }

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
    }

    private func setupConstraints() {

        [label, tickIcon].forEach(contentView.addSubview)

        let constraints = [
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22.0),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -22.0),
            tickIcon.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8.0),
            tickIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tickIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tickIcon.widthAnchor.constraint(equalToConstant: 14.0),
            tickIcon.heightAnchor.constraint(equalToConstant: 14.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.heading
        tickIcon.tintColor = theme.brand.purple
    }
}
