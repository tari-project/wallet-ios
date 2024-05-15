//  PopUpButtonsTableView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 18/10/2022
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

import TariCommon

final class PopUpButtonsTableView: DynamicThemeView {

    struct Model: Identifiable, Hashable {
        let id: UUID
        let title: String
        let textAlignment: NSTextAlignment
        let isArrowVisible: Bool
    }

    // MARK: - Subviews

    @View private var tableView: PopUpTableView = {
        let view = PopUpTableView()
        view.register(type: PopUpButtonCell.self)
        return view
    }()

    @View private var footerLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .Avenir.medium.withSize(15.0)
        return view
    }()

    // MARK: - Properties

    var onSelectedRow: ((IndexPath) -> Void)?
    private var dataSource: UITableViewDiffableDataSource<Int, Model>?

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

        [tableView, footerLabel].forEach { addSubview($0) }

        let constraints = [
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerLabel.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20.0),
            footerLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        dataSource = UITableViewDiffableDataSource<Int, Model>(tableView: tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: PopUpButtonCell.self, indexPath: indexPath)
            cell.text = model.title
            cell.textAlignment = model.textAlignment
            cell.isArrowVisible = model.isArrowVisible
            return cell
        }

        tableView.onSelectRow = { [weak self] in
            self?.onSelectedRow?($0)
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        footerLabel.textColor = theme.text.body
    }

    func update(options: [Model]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, Model>()
        snapshot.appendSections([0])
        snapshot.appendItems(options)

        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    func update(footer: String?) {
        footerLabel.text = footer
    }
}

private final class PopUpButtonCell: DynamicThemeCell {

    // MARK: - Subviews

    @View private var label: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = .Avenir.medium.withSize(15.0)
        return view
    }()

    @View private var arrowView: UIImageView = {
        let view = UIImageView()
        view.image = Theme.shared.images.forwardArrow
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        return view
    }()

    @View private var separatorLine = UIView()

    // MARK: - Properties

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    var textAlignment: NSTextAlignment {
        get { label.textAlignment }
        set { label.textAlignment = newValue }
    }

    var isArrowVisible: Bool {
        get { !arrowView.isHidden }
        set { arrowView.isHidden = !newValue }
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
        isArrowVisible = false
    }

    private func setupConstraints() {

        [stackView, separatorLine].forEach(contentView.addSubview)
        [label, arrowView].forEach(stackView.addArrangedSubview)

        let constraints = [
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22.0),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 22.0),
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.heading
        arrowView.tintColor = theme.text.heading
        separatorLine.backgroundColor = theme.backgrounds.secondary
    }
}
