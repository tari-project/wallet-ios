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

import TariCommon

final class ContactBookContactListView: DynamicThemeView {

    struct Section {
        let title: String?
        let items: [ContactBookCell.ViewModel]
    }

    // MARK: - Subviews

    @View private var tableView: UITableView = {
        let view = UITableView()
        view.estimatedRowHeight = 44.0
        view.rowHeight = UITableView.automaticDimension
        view.keyboardDismissMode = .interactive
        view.register(type: ContactBookCell.self)
        view.register(headerFooterType: MenuTableHeaderView.self)
        view.separatorInset = UIEdgeInsets(top: 0.0, left: 22.0, bottom: 0.0, right: 22.0)
        view.allowsSelectionDuringEditing = true
        return view
    }()

    @View private var placeholderView = ContactBookListPlaceholder()

    private let tableFooterView = ContactBookContactListFooter()

    // MARK: - Properties

    var viewModels: [Section] = [] {
        didSet { update(sections: viewModels) }
    }

    var placeholderViewModel: ContactBookListPlaceholder.ViewModel? {
        didSet { update(placeholderViewModel: placeholderViewModel) }
    }

    var isPlaceholderVisible: Bool = false {
        didSet { updatePlaceholders() }
    }

    var isFooterVisible: Bool = false {
        didSet { tableView.tableFooterView = isFooterVisible ? tableFooterView : nil }
    }

    var isInSharingMode: Bool = false {
        didSet { updateViewsContentMode() }
    }

    var selectedRows = Set<UUID>() {
        didSet { updateSelectedRows() }
    }

    var onContactRowTap: ((_ identifier: UUID, _ isEditing: Bool) -> Void)?

    var onFooterTap: (() -> Void)? {
        get { tableFooterView.onTap }
        set { tableFooterView.onTap = newValue }
    }

    private var dataSource: UITableViewDiffableDataSource<Int, ContactBookCell.ViewModel>?
    private var placeholderConstraints: [NSLayoutConstraint] = []

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

        placeholderConstraints = [
            placeholderView.topAnchor.constraint(equalTo: topAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholderView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupTableView() {

        let dataSource = UITableViewDiffableDataSource<Int, ContactBookCell.ViewModel>(tableView: tableView) { [weak self] tableView, indexPath, model in
            self?.makeContactCell(model: model, tableView: tableView, indexPath: indexPath)
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

    private func update(sections: [Section]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, ContactBookCell.ViewModel>()

        sections
            .enumerated()
            .forEach {
                snapshot.appendSections([$0])
                snapshot.appendItems($1.items)
            }

        dataSource?.apply(snapshot: snapshot)
    }

    private func update(placeholderViewModel: ContactBookListPlaceholder.ViewModel?) {
        guard let placeholderViewModel else { return }
        placeholderView.update(viewModel: placeholderViewModel)
    }

    private func updatePlaceholders() {

        if isPlaceholderVisible {
            tableView.backgroundView = placeholderView
            NSLayoutConstraint.activate(placeholderConstraints)
        } else {
            NSLayoutConstraint.deactivate(placeholderConstraints)
            tableView.backgroundView = nil
        }

        tableView.bounces = !isPlaceholderVisible
    }

    private func updateSelectedRows() {
        tableView.visibleCells
            .compactMap { $0 as? ContactBookCell }
            .forEach {
                guard let elementID = $0.elementID else {
                    $0.isTickSelected = false
                    return
                }
                $0.isTickSelected = self.selectedRows.contains(elementID)
            }
    }

    private func updateViewsContentMode() {
        tableView.setEditing(isInSharingMode, animated: true)
    }

    // MARK: - Factories

    private func makeContactCell(model: ContactBookCell.ViewModel, tableView: UITableView, indexPath: IndexPath) -> ContactBookCell {
        let cell = tableView.dequeueReusableCell(type: ContactBookCell.self, indexPath: indexPath)
        cell.update(viewModel: model)
        cell.isTickSelected = selectedRows.contains(model.id) == true
        return cell
    }

    // MARK: - Handlers

    private func handle(contactBookCell: ContactBookCell) {
        guard let elementID = contactBookCell.elementID else { return }
        onContactRowTap?(elementID, tableView.isEditing)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.updateFooterFrame()
    }
}

extension ContactBookContactListView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard let title = viewModels[section].title else { return nil }

        let headerView = tableView.dequeueReusableHeaderFooterView(type: MenuTableHeaderView.self)
        headerView.label.text = title
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        viewModels[section].title == nil ? 0.0 : UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ContactBookCell else { return }
        handle(contactBookCell: cell)
    }
}

private class ContactBookContactListFooter: UIView {

    // MARK: - Subiews

    @View private var button: TextButton = {
        let view = TextButton()
        view.setVariation(.secondary)
        view.setTitle(localized("contact_book.section.list.placeholder.button"), for: .normal)
        return view
    }()

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Properties

    var onTap: (() -> Void)?

    // MARK: - Setups

    private func setupConstraints() {

        addSubview(button)

        let constraints = [
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        button.onTap = { [weak self] in self?.onTap?() }
    }
}
