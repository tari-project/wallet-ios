//  AddRecipientView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 21/07/2023
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

final class AddRecipientView: BaseNavigationContentView {

    struct Section {
        let title: String?
        let items: [ItemType]
    }

    enum ItemType: Hashable {
        case contact(model: ContactBookCell.ViewModel)
    }

    // MARK: - Subviews

    @TariView private(set) var searchView: ContactSearchView = {
        let view = ContactSearchView()
        view.textField.placeholder = localized("add_recipient.inputbox.placeholder")
        view.textField.returnKeyType = .done
        return view
    }()

    @TariView private var errorMessageView: ErrorView = {
        let view = ErrorView()
        view.isHidden = true
        view.alpha = 0.0
        return view
    }()

    @TariView private var tableView: UITableView = {
        let view = UITableView()
        view.estimatedRowHeight = 44.0
        view.rowHeight = UITableView.automaticDimension
        view.separatorInset = UIEdgeInsets(top: 0.0, left: 22.0, bottom: 0.0, right: 22.0)
        view.register(type: ContactBookCell.self)
        view.register(headerFooterType: MenuTableHeaderView.self)
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - Properties

    var viewModels: [Section] = [] {
        didSet { update(sections: viewModels) }
    }

    var isYatLogoVisible: Bool {
        get { searchView.isYatLogoVisible }
        set { searchView.isYatLogoVisible = newValue }
    }

    var isPreviewButtonVisible: Bool {
        get { searchView.isPreviewButtonVisible }
        set { searchView.isPreviewButtonVisible = newValue }
    }

    var errorMessage: String? {
        didSet { update(errorMessage: errorMessage) }
    }

    var onQrCodeScannerButtonTap: (() -> Void)?
    var onYatPreviewButtonTap: (() -> Void)?
    var onBluetoothRowTap: (() -> Void)?
    var onRowTap: ((_ identifier: UUID) -> Void)?

    private var dataSource: UITableViewDiffableDataSource<Int, ItemType>?

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
        tableView.backgroundColor = .clear
        [searchView, errorMessageView, tableView].forEach(addSubview)

        let constraints = [
            searchView.topAnchor.constraint(equalTo: topAnchor, constant: 110),
            searchView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            searchView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            errorMessageView.topAnchor.constraint(equalTo: searchView.bottomAnchor, constant: 8),
            errorMessageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            errorMessageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: errorMessageView.bottomAnchor, constant: 8),
            tableView.leftAnchor.constraint(equalTo: leftAnchor),
            tableView.rightAnchor.constraint(equalTo: rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        dataSource = UITableViewDiffableDataSource<Int, ItemType>(tableView: tableView) { [weak self] tableView, indexPath, model in
            switch model {
            case let .contact(model):
                return self?.makeContactCell(model: model, tableView: tableView, indexPath: indexPath)
            }
        }

        tableView.dataSource = dataSource
        tableView.delegate = self

        searchView.qrButton.onTap = { [weak self] in
            self?.onQrCodeScannerButtonTap?()
        }

        searchView.textField.delegate = self
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = .Background.secondary
        tableView.backgroundColor = .clear
        tableView.separatorColor = .Elevation.outlined
    }

    private func update(sections: [Section]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, ItemType>()

        sections
            .enumerated()
            .forEach {
                snapshot.appendSections([$0])
                snapshot.appendItems($1.items)
            }

        dataSource?.applySnapshotUsingReloadData(snapshot)
    }

    private func update(errorMessage: String?) {
        if let errorMessage {
            errorMessageView.message = errorMessage
            Task {
                await UIView.animate(duration: 0.3) {
                    self.errorMessageView.isHidden = false
                }
                UIView.animate(withDuration: 0.3) {
                    self.errorMessageView.alpha = 1.0
                }
            }
        } else {
            Task {
                await UIView.animate(duration: 0.3) {
                    self.errorMessageView.alpha = 0.0
                }
                UIView.animate(withDuration: 0.3) {
                    self.errorMessageView.isHidden = true
                }
            }
        }
    }

    // MARK: - Factories

    private func makeContactCell(model: ContactBookCell.ViewModel, tableView: UITableView, indexPath: IndexPath) -> ContactBookCell {
        let cell = tableView.dequeueReusableCell(type: ContactBookCell.self, indexPath: indexPath)
        cell.update(viewModel: model)
        return cell
    }
}

extension AddRecipientView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard let title = viewModels[section].title else { return nil }

        let headerView = tableView.dequeueReusableHeaderFooterView(type: MenuTableHeaderView.self)
        headerView.title = title
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        viewModels[section].title == nil ? 0.0 : UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        switch cell {
        case let contactBookCell as ContactBookCell:
            guard let elementID = contactBookCell.elementID else { return }
            onRowTap?(elementID)
        default:
            break
        }
    }

}

extension AddRecipientView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
