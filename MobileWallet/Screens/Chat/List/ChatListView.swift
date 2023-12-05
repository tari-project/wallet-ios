//  ChatListView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 11/09/2023
	Using Swift 5.0
	Running on macOS 13.5

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

final class ChatListView: BaseNavigationContentView {

    struct Section {
        let title: String
        let rows: [ChatListCell.Model]
    }

    // MARK: - Subviews

    @View private var tableView: UITableView = {
        let view = UITableView()
        view.rowHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            view.sectionHeaderTopPadding = 0.0
        } else {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.register(type: ChatListCell.self)
        view.register(headerFooterType: MenuTableHeaderView.self)
        view.backgroundColor = .clear
        return view
    }()

    @View private var unreadMessagesLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(14.0)
        view.textAlignment = .center
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()

    @View private var placeholderView = ChatListPlaceholder()

    // MARK: - Properties

    var viewModels: [Section] = [] {
        didSet { update(viewModels: viewModels) }
    }

    var onStartConversationButtonTap: (() -> Void)?
    var onSelectRow: ((String) -> Void)?

    private var dataSource: UITableViewDiffableDataSource<Int, ChatListCell.Model>?
    private var unreadMessagesLabelBottomConstraint: NSLayoutConstraint?

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
        navigationBar.backButtonType = .none
        navigationBar.title = localized("chat.list.title")
        navigationBar.update(rightButton: NavigationBar.ButtonModel(image: UIImage(systemName: "plus.bubble"), callback: { [weak self] in self?.onStartConversationButtonTap?() }))
    }

    private func setupConstraints() {

        navigationBar.bottomContentView.addSubview(unreadMessagesLabel)
        [tableView, placeholderView].forEach(addSubview)

        unreadMessagesLabelBottomConstraint = unreadMessagesLabel.bottomAnchor.constraint(equalTo: navigationBar.bottomContentView.bottomAnchor, constant: -9.0)

        let constraints = [
            tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            placeholderView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            placeholderView.centerYAnchor.constraint(equalTo: centerYAnchor),
            unreadMessagesLabel.topAnchor.constraint(equalTo: navigationBar.bottomContentView.topAnchor),
            unreadMessagesLabel.leadingAnchor.constraint(equalTo: navigationBar.bottomContentView.leadingAnchor),
            unreadMessagesLabel.trailingAnchor.constraint(equalTo: navigationBar.bottomContentView.trailingAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: ChatListCell.self, indexPath: indexPath)
            cell.update(model: model)
            return cell
        }

        tableView.dataSource = dataSource
        tableView.delegate = self
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        unreadMessagesLabel.textColor = theme.text.body
        backgroundColor = theme.backgrounds.secondary
    }

    private func update(viewModels: [Section]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatListCell.Model>()

        viewModels
            .enumerated()
            .forEach {
                snapshot.appendSections([$0.offset])
                snapshot.appendItems($0.element.rows)
            }

        dataSource?.applySnapshotUsingReloadData(snapshot)

        tableView.isHidden = viewModels.isEmpty
        placeholderView.isHidden = !viewModels.isEmpty
    }

    func update(unreadMessagesCount: Int) {

        let isLabelVisible = unreadMessagesCount > 0

        switch unreadMessagesCount {
        case 0:
            break
        case 1:
            unreadMessagesLabel.text = localized("chat.list.lables.unread_messages.singular", arguments: unreadMessagesCount)
        default:
            unreadMessagesLabel.text = localized("chat.list.lables.unread_messages.plural", arguments: unreadMessagesCount)
        }

        unreadMessagesLabelBottomConstraint?.isActive = isLabelVisible

        UIView.animate(withDuration: 0.3) {
            self.unreadMessagesLabel.alpha = isLabelVisible ? 1.0 : 0.0
            self.navigationBar.layoutIfNeeded()
        }
    }
}

extension ChatListView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(type: MenuTableHeaderView.self)
        headerView.title = viewModels[section].title
        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ChatListCell, let identifier = cell.identifier else { return }
        onSelectRow?(identifier)
    }
}
