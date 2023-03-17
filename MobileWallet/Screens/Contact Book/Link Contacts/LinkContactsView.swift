//  LinkContactsView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 07/03/2023
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
import Combine

final class LinkContactsView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private(set) var infoLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.textAlignment = .center
        view.normalFont = .Avenir.medium.withSize(14.0)
        view.boldFont = .Avenir.heavy.withSize(14.0)
        view.numberOfLines = 0
        return view
    }()

    @View private(set) var searchTextField: SearchTextField = {
        let view = SearchTextField()
        view.placeholder = localized("contact_book.link_contacts.text_field.search")
        return view
    }()

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

    var name: String = "" {
        didSet { updateInfoLabel(name: name) }
    }

    var viewModels: [ContactBookCell.ViewModel] = [] {
        didSet { update(viewModels: viewModels) }
    }

    var searchText: AnyPublisher<String, Never> { searchTextSubject.eraseToAnyPublisher() }
    var onSelectRow: ((IndexPath) -> Void)?

    private var dataSource: UITableViewDiffableDataSource<Int, ContactBookCell.ViewModel>?
    private let searchTextSubject = CurrentValueSubject<String, Never>("")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupSubviews()
        setupConstraints()
        setupTableView()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupSubviews() {
        navigationBar.title = localized("contact_book.link_contacts.title")
    }

    private func setupConstraints() {

        [infoLabel, searchTextField, tableView].forEach(addSubview)

        let constraints = [
            infoLabel.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 22.0),
            infoLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            infoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            searchTextField.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20.0),
            searchTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            searchTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20.0),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupTableView() {

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: ContactBookCell.self, indexPath: indexPath)
            cell.update(viewModel: model)
            return cell
        }

        tableView.dataSource = dataSource
        tableView.delegate = self
    }

    private func setupCallbacks() {
        searchTextField.bind(withSubject: searchTextSubject, storeIn: &cancellables)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
        tableView.backgroundColor = theme.backgrounds.primary
        tableView.separatorColor = theme.neutral.secondary
        infoLabel.textColor = theme.text.body
    }

    func updateInfoLabel(name: String) {
        infoLabel.textComponents = [
            StylizedLabel.StylizedText(text: localized("contact_book.link_contacts.lables.info.part1") + " ", style: .normal),
            StylizedLabel.StylizedText(text: name, style: .bold),
            StylizedLabel.StylizedText(text: ".", style: .normal)
        ]
    }

    func update(viewModels: [ContactBookCell.ViewModel]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, ContactBookCell.ViewModel>()

        snapshot.appendSections([0])
        snapshot.appendItems(viewModels)

        dataSource?.apply(snapshot: snapshot)
    }
}

extension LinkContactsView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelectRow?(indexPath)
    }
}
