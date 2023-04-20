//  ContactTransactionListView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 18/04/2023
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

final class ContactTransactionListView: BaseNavigationContentView {

    // MARK: - Subviews

    private let headerView = ContactTransactionListHeaderView()

    @View private var tableView: UITableView = {
        let view = UITableView()
        view.register(type: TxTableViewCell.self)
        view.estimatedRowHeight = 300.0
        view.rowHeight = UITableView.automaticDimension
        view.separatorStyle = .none
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()

    @View private var placeholder = ContactTransactionListPlaceholder()

    // MARK: - Properties

    var name: String = "" {
        didSet {
            headerView.name = name
            placeholder.name = name
        }
    }

    var onSelectRow: ((_ indexPath: IndexPath) -> Void)?
    var onSendButtonTap: (() -> Void)?

    private var dataSource: UITableViewDiffableDataSource<Int, TxTableViewModel>?

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
        navigationBar.title = localized("contact_book.transaction_list.title")
        tableView.tableHeaderView = headerView
    }

    private func setupConstraints() {

        [tableView, placeholder].forEach(addSubview)

        let constraints = [
            tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            placeholder.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            placeholder.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholder.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholder.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: TxTableViewCell.self, indexPath: indexPath)
            cell.configure(with: model)
            model.downloadGif()
            cell.updateCell = {
                DispatchQueue.main.async {
                    tableView.reloadRows(at: [indexPath], with: .fade)
                }
            }
            return cell
        }

        tableView.delegate = self

        placeholder.onButtonTap = { [weak self] in
            self?.onSendButtonTap?()
        }
    }

    // MARK: - Actions

    func update(models: [TxTableViewModel]) {

        placeholder.isHidden = !models.isEmpty

        var snapshot = NSDiffableDataSourceSnapshot<Int, TxTableViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(models)
        dataSource?.apply(snapshot: snapshot)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.updateHeaderFrame()
    }
}

extension ContactTransactionListView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelectRow?(indexPath)
    }
}
