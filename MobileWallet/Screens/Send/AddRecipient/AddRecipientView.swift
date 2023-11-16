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

final class AddRecipientView: DynamicThemeView {

    struct Section {
        let title: String?
        let items: [ItemType]
    }

    enum ItemType: Hashable {
        case bluetooth
        case contact(model: ContactBookCell.ViewModel)
    }

    // MARK: - Subviews

    @View private var searchViewToolbar = BaseToolbar()

    @View private var topStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 10.0
        return view
    }()

    @View private(set) var searchView: ContactSearchView = {
        let view = ContactSearchView()
        view.textField.placeholder = localized("add_recipient.inputbox.placeholder")
        view.textField.returnKeyType = .done
        return view
    }()

    @View private var errorMessageView: ErrorView = {
        let view = ErrorView()
        view.isHidden = true
        view.alpha = 0.0
        return view
    }()

    @View private var tableView: UITableView = {
        let view = UITableView()
        view.estimatedRowHeight = 44.0
        view.rowHeight = UITableView.automaticDimension
        view.separatorInset = UIEdgeInsets(top: 0.0, left: 22.0, bottom: 0.0, right: 22.0)
        view.register(type: ContactBookBluetoothCell.self)
        view.register(type: ContactBookCell.self)
        view.register(headerFooterType: MenuTableHeaderView.self)
        return view
    }()

    @View private var continueButtonToolbar = BaseToolbar()

    @View private var continueButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("common.continue"), for: .normal)
        return view
    }()

    // MARK: - Properties

    var viewModels: [Section] = [] {
        didSet { update(sections: viewModels) }
    }

    var isPreviewButtonVisible: Bool = false {
        didSet { updateSearchFieldState() }
    }

    var isContinueButtonEnabled: Bool = false {
        didSet { continueButton.variation = isContinueButtonEnabled ? .normal : .disabled }
    }

    var errorMessage: String? {
        didSet { update(errorMessage: errorMessage) }
    }

    var onQrCodeScannerButtonTap: (() -> Void)?
    var onYatPreviewButtonTap: (() -> Void)?
    var onBluetoothRowTap: (() -> Void)?
    var onRowTap: ((_ identifier: UUID) -> Void)?
    var onContinueButtonTap: (() -> Void)?

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

        [searchView, errorMessageView].forEach(topStackView.addArrangedSubview)
        searchViewToolbar.addSubview(topStackView)
        continueButtonToolbar.addSubview(continueButton)
        [tableView, searchViewToolbar, continueButtonToolbar].forEach(addSubview)

        let constraints = [
            searchViewToolbar.topAnchor.constraint(equalTo: topAnchor),
            searchViewToolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchViewToolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            topStackView.topAnchor.constraint(equalTo: searchViewToolbar.topAnchor, constant: 20.0),
            topStackView.leadingAnchor.constraint(equalTo: searchViewToolbar.leadingAnchor, constant: 22.0),
            topStackView.trailingAnchor.constraint(equalTo: searchViewToolbar.trailingAnchor, constant: -22.0),
            topStackView.bottomAnchor.constraint(equalTo: searchViewToolbar.bottomAnchor, constant: -20.0),
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            continueButtonToolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            continueButtonToolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            continueButtonToolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            continueButton.topAnchor.constraint(equalTo: continueButtonToolbar.topAnchor, constant: 25.0),
            continueButton.leadingAnchor.constraint(equalTo: continueButtonToolbar.leadingAnchor, constant: 25.0),
            continueButton.trailingAnchor.constraint(equalTo: continueButtonToolbar.trailingAnchor, constant: -25.0),
            continueButton.bottomAnchor.constraint(equalTo: continueButtonToolbar.bottomAnchor, constant: -25.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        dataSource = UITableViewDiffableDataSource<Int, ItemType>(tableView: tableView) { [weak self] tableView, indexPath, model in
            switch model {
            case .bluetooth:
                return self?.makeBluetoothCell(tableView: tableView, indexPath: indexPath)
            case let .contact(model):
                return self?.makeContactCell(model: model, tableView: tableView, indexPath: indexPath)
            }
        }

        tableView.dataSource = dataSource
        tableView.delegate = self

        searchView.qrButton.onTap = { [weak self] in
            self?.onQrCodeScannerButtonTap?()
        }

        searchView.yatPreviewButton.onTap = { [weak self] in
            self?.searchView.textField.resignFirstResponder()
            self?.onYatPreviewButtonTap?()
        }

        searchView.textField.delegate = self

        continueButton.onTap = { [weak self] in
            self?.onContinueButtonTap?()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        tableView.backgroundColor = theme.backgrounds.secondary
        tableView.separatorColor = theme.neutral.secondary
    }

    private func update(sections: [Section]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, ItemType>()

        sections
            .enumerated()
            .forEach {
                snapshot.appendSections([$0])
                snapshot.appendItems($1.items)
            }

        dataSource?.apply(snapshot: snapshot)
    }

    private func updateSearchFieldState() {
        searchView.isPreviewButtonVisible = isPreviewButtonVisible
    }

    private func updateToolbarsAlpha(scrollView: UIScrollView) {
        let maxAlpha = 0.9
        updateSearchViewToolbarAlpha(scrollView: scrollView, maxAlpha: maxAlpha)
        updateContinueButtonToolbarAlpha(scrollView: scrollView, maxAlpha: maxAlpha)
    }

    private func updateSearchViewToolbarAlpha(scrollView: UIScrollView, maxAlpha: CGFloat) {
        let searchViewToolbarHeight = searchViewToolbar.bounds.height
        guard searchViewToolbarHeight > 0.0 else { return }
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        searchViewToolbar.backgroundAlpha =  min(offset, searchViewToolbarHeight) / searchViewToolbarHeight * maxAlpha
    }

    private func updateContinueButtonToolbarAlpha(scrollView: UIScrollView, maxAlpha: CGFloat) {
        let continueButtonToolbarHeight = continueButtonToolbar.bounds.height
        guard continueButtonToolbarHeight > 0.0 else { return }
        let offset = scrollView.contentSize.height - scrollView.bounds.height - scrollView.contentOffset.y + scrollView.contentInset.bottom
        continueButtonToolbar.backgroundAlpha = min(offset, continueButtonToolbarHeight) / continueButtonToolbarHeight * maxAlpha
    }

    private func update(errorMessage: String?) {
        if let errorMessage {
            errorMessageView.message = errorMessage
            Task {
                await UIView.animate(duration: 0.3) {
                    self.errorMessageView.isHidden = false
                    self.topStackView.layoutIfNeeded()
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
                    self.topStackView.layoutIfNeeded()
                }
            }
        }
    }

    // MARK: - Factories

    private func makeBluetoothCell(tableView: UITableView, indexPath: IndexPath) -> ContactBookBluetoothCell {
        tableView.dequeueReusableCell(type: ContactBookBluetoothCell.self, indexPath: indexPath)
    }

    private func makeContactCell(model: ContactBookCell.ViewModel, tableView: UITableView, indexPath: IndexPath) -> ContactBookCell {
        let cell = tableView.dequeueReusableCell(type: ContactBookCell.self, indexPath: indexPath)
        cell.update(viewModel: model)
        return cell
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let topInset = searchViewToolbar.frame.maxY
        let bottomInset = bounds.height - continueButtonToolbar.frame.minY
        tableView.contentInset = UIEdgeInsets(top: topInset, left: 0.0, bottom: bottomInset, right: 0.0)
        updateToolbarsAlpha(scrollView: tableView)
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
        case is ContactBookBluetoothCell:
            onBluetoothRowTap?()
        case let contactBookCell as ContactBookCell:
            guard let elementID = contactBookCell.elementID else { return }
            onRowTap?(elementID)
        default:
            break
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateToolbarsAlpha(scrollView: scrollView)
    }
}

extension AddRecipientView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
