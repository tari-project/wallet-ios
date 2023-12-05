//  ChatConversationView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 14/09/2023
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

final class ChatConversationView: BaseNavigationContentView {

    struct Model {
        let avatar: RoundedAvatarView.Avatar
        let isOnline: Bool
        let name: String?
    }

    struct Section {
        let title: String
        let messages: [ChatConversationCell.Model]
    }

    // MARK: - Subviews

    @View private var navigationBarContentView = ChatNavigationContentView()
    @View private var contentView = KeyboardAvoidingContentView()
    @View private var placeholder = CentredPlaceholder()

    @View private var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.separatorStyle = .none
        view.backgroundColor = .clear
        view.register(type: ChatConversationCell.self)
        let footer = UIView()
        footer.frame.size.height = 0.1
        view.tableFooterView = footer
        return view
    }()

    @View private var textInputBar = ChatInputMessageView()

    @View private var placeholderImageView: PaintBackgroundImageView = {
        let view = PaintBackgroundImageView()
        view.image = .Images.Chat.Placeholders.conversation
        return view
    }()

    // MARK: - Properties

    var interactableViews: [UIView] { [navigationBar, tableView, placeholder] }

    var isPlaceholderVisible: Bool = false {
        didSet { updatePlaceholderState() }
    }

    var onNavigationBarTap: (() -> Void)?
    var onSendButtonTap: ((String?) -> Void)?

    private var sections: [Section] = []
    private var dataSource: UITableViewDiffableDataSource<Int, ChatConversationCell.Model>?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
        setupCallbacks()
        updatePlaceholderState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        placeholder.setup(placeholderView: placeholderImageView)
        navigationBar.centerContentView.addSubview(navigationBarContentView)
        [tableView, textInputBar].forEach(contentView.addSubview)
        [placeholder, contentView].forEach(addSubview)

        sendSubviewToBack(placeholder)

        let constraints = [
            navigationBarContentView.topAnchor.constraint(equalTo: navigationBar.centerContentView.topAnchor),
            navigationBarContentView.leadingAnchor.constraint(equalTo: navigationBar.centerContentView.leadingAnchor),
            navigationBarContentView.trailingAnchor.constraint(equalTo: navigationBar.centerContentView.trailingAnchor),
            navigationBarContentView.bottomAnchor.constraint(equalTo: navigationBar.centerContentView.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            placeholder.topAnchor.constraint(equalTo: topAnchor),
            placeholder.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholder.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholder.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.topAnchor.constraint(equalTo: contentView.contentView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentView.contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.contentView.trailingAnchor),
            textInputBar.topAnchor.constraint(equalTo: tableView.bottomAnchor),
            textInputBar.leadingAnchor.constraint(equalTo: contentView.contentView.leadingAnchor),
            textInputBar.trailingAnchor.constraint(equalTo: contentView.contentView.trailingAnchor),
            textInputBar.bottomAnchor.constraint(equalTo: contentView.contentView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        navigationBarContentView.onTap = { [weak self] in
            self?.onNavigationBarTap?()
        }

        textInputBar.onSendButtonTap = { [weak self] in
            self?.onSendButtonTap?($0)
        }

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: ChatConversationCell.self, indexPath: indexPath)
            cell.update(model: model)
            return cell
        }

        tableView.delegate = self
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
    }

    func update(model: Model) {
        navigationBarContentView.avatar = model.avatar
        navigationBarContentView.isOnline = model.isOnline
        navigationBarContentView.username = model.name
    }

    func update(sections: [Section]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatConversationCell.Model>()

        sections
            .enumerated()
            .forEach {
                snapshot.appendSections([$0])
                snapshot.appendItems($1.messages)
            }

        self.sections = sections
        dataSource?.applySnapshotUsingReloadData(snapshot)
        scrollToBottom()
    }

    private func updatePlaceholderState() {
        placeholder.isHidden = !isPlaceholderVisible
        tableView.isHidden = isPlaceholderVisible
    }

    private func scrollToBottom() {
        DispatchQueue.main.async {
            guard let lastRowIndex = self.sections.last?.messages.count else { return }
            let lastSectionIndex = self.sections.count - 1
            let lastIndexPath = IndexPath(row: lastRowIndex - 1, section: lastSectionIndex)
            self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
        }
    }
}

extension ChatConversationView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ChatConversationSectionHeaderView()
        header.text = sections[section].title
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.0 }
}
