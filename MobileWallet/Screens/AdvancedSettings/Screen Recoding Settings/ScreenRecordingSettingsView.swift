//  ScreenRecordingSettingsView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 23/02/2024
	Using Swift 5.0
	Running on macOS 14.2

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
import Combine

final class ScreenRecordingSettingsView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var descriptionLabel: UILabel = {
        let view = UILabel()
        view.text = localized("screen_recording.label.description")
        view.font = .Avenir.medium.withSize(14.0)
        view.numberOfLines = 0
        return view
    }()

    @View private var tableView: UITableView = {
        let view = UITableView()
        view.backgroundColor = .clear
        view.register(type: SwitchMenuCell.self)
        return view
    }()

    // MARK: - Properties

    var onSwitchValueChange: ((Bool) -> Void)?

    private let dynamicModel = SwitchMenuCell.DynamicModel()
    private var dataSource: UITableViewDiffableDataSource<Int, UInt>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
        setupCells()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        navigationBar.title = localized("screen_recording.title")
    }

    private func setupConstraints() {

        [descriptionLabel, tableView].forEach(addSubview)

        let constraints = [
            descriptionLabel.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 33.0),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            tableView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 15.0),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, index in
            let cell = tableView.dequeueReusableCell(type: SwitchMenuCell.self, indexPath: indexPath)
            cell.viewModel = SwitchMenuCell.ViewModel(
                id: index,
                title: localized("screen_recording.label.confirmation"),
                isArrowVisible: false,
                isDestructive: false
            )
            cell.dynamicModel = self?.dynamicModel
            return cell
        }

        dynamicModel.$switchValue
            .removeDuplicates()
            .sink { [weak self] in self?.onSwitchValueChange?($0) }
            .store(in: &cancellables)

        tableView.dataSource = dataSource
    }

    private func setupCells() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UInt>()
        snapshot.appendSections([0])
        snapshot.appendItems([0])
        dataSource?.apply(snapshot: snapshot)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
        descriptionLabel.textColor = theme.text.body
    }

    func update(switchValue: Bool) {
        dynamicModel.switchValue = switchValue
    }
}
