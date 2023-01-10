//  LogViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 17/10/2022
	Using Swift 5.0
	Running on macOS 12.6

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
import Combine
import TariCommon

final class LogViewController: UIViewController {

    // MARK: - Properties

    private let model: LogModel
    private let mainView = LogView()
    private var tableDataSource: UITableViewDiffableDataSource<Int, LogLineModel>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: LogModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupCallbacks()
        model.refreshData()
    }

    // MARK: - Setups

    private func setupTableView() {
        mainView.tableView.register(type: LogCell.self)
    }

    private func setupCallbacks() {

        model.$filename
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.title = $0 }
            .store(in: &cancellables)

        model.$logLineModels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.update(items: $0) }
            .store(in: &cancellables)

        model.$filterModels
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showFiltersPopUp(options: $0) }
            .store(in: &cancellables)

        model.$isUpdateInProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.isSpinnerVisible = $0 }
            .store(in: &cancellables)

        tableDataSource = UITableViewDiffableDataSource(tableView: mainView.tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: LogCell.self, indexPath: indexPath)
            cell.update(text: model.text)
            return cell
        }

        mainView.tableView.dataSource = tableDataSource

        mainView.onFilterButtonTap = { [weak self] in
            self?.model.generateFilterModels()
        }
    }

    // MARK: - Actions

    private func update(items: [LogLineModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, LogLineModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        tableDataSource?.apply(snapshot: snapshot)
    }

    private func showFiltersPopUp(options: [LogFilterModel]) {

        let headerSection = PopUpComponentsFactory.makeHeaderView(title: localized("debug.logs.details.filters.title"))

        let contentSection = PopUpSwitchListView()
        contentSection.update(options: options)

        let buttonsSection = PopUpComponentsFactory.makeButtonsView(models: [
            PopUpDialogButtonModel(title: localized("debug.logs.details.filters.buttons.apply"), type: .normal, callback: { [weak self, contentSection] in self?.applyFilters(selectedUUIDs: contentSection.selectedUUIDs) }),
            PopUpDialogButtonModel(title: localized("common.cancel"), type: .text)
        ])

        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popUp, configuration: .dialog(hapticType: .none))
    }

    private func applyFilters(selectedUUIDs: Set<UUID>) {
        model.applyFilters(selectedUUIDs: selectedUUIDs)
    }
}

private final class PopUpSwitchListView: UIView {

    // MARK: - Subviews

    @View private var tableView: PopUpTableView = {
        let view = PopUpTableView()
        view.register(type: PopUpSwitchListViewCell.self)
        return view
    }()

    // MARK: - Properties

    private(set) var selectedUUIDs = Set<UUID>()
    private var dataSource: UITableViewDiffableDataSource<Int, LogFilterModel>?

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

        dataSource = UITableViewDiffableDataSource<Int, LogFilterModel>(tableView: tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: PopUpSwitchListViewCell.self, indexPath: indexPath)
            cell.update(title: model.title, isSelected: model.isSelected)

            cell.onTapOnSwitch = { [weak self] in
                self?.update(switchState: $0, uuid: model.id)
            }

            return cell
        }
    }

    // MARK: - Updates

    func update(options: [LogFilterModel]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, LogFilterModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(options)

        let selectedUUIDs = options
            .filter { $0.isSelected }
            .map { $0.id }

        self.selectedUUIDs = Set(selectedUUIDs)

        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func update(switchState: Bool, uuid: UUID) {
        guard switchState else {
            selectedUUIDs.remove(uuid)
            return
        }
        selectedUUIDs.insert(uuid)
    }
}

private class PopUpSwitchListViewCell: DynamicThemeCell {

    // MARK: - Subviews

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(15.0)
        return view
    }()

    @View private var switchView = UISwitch()

    // MARK: - Properties

    var onTapOnSwitch: ((Bool) -> Void)?

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupView() {
        selectionStyle = .none
        backgroundColor = .clear
    }

    private func setupConstraints() {

        [label, switchView].forEach { contentView.addSubview($0) }

        let constraints = [
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15.0),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15.0),
            switchView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8.0),
            switchView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
            switchView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        switchView.addTarget(self, action: #selector(onSwitch), for: .valueChanged)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.heading
        switchView.onTintColor = theme.brand.purple
    }

    func update(title: String?, isSelected: Bool) {
        label.text = title
        switchView.isOn = isSelected
    }

    // MARK: - Target Actions

    @objc private func onSwitch(_ switchView: UISwitch) {
        onTapOnSwitch?(switchView.isOn)
    }
}
