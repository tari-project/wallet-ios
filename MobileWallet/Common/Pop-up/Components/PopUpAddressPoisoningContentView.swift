//  PopUpAddressPoisoningContentView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 15/01/2024
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

final class PopUpAddressPoisoningContentView: DynamicThemeView {

    // MARK: - Subiews

    @View private var tableView: PopUpTableView = {
        let view = PopUpTableView()
        view.register(type: PopUpAddressPoisoningContentCell.self)
        view.layer.cornerRadius = 10.0
        view.separatorStyle = .none
        return view
    }()

    @View private var tickView: TickButton = {
        let view = TickButton()
        view.isUserInteractionEnabled = true
        return view
    }()

    @View private var tickMessageLabel: UILabel = {
        let view = UILabel()
        view.text = localized("address_poisoning.pop_up.label.tick_message")
        view.font = .Avenir.medium.withSize(14.0)
        return view
    }()

    @View private var tickMessageButton = BaseButton()

    @View private var shieldIconView: UIImageView = {
        let view = UIImageView()
        view.image = .Icons.shieldCheckmark
        return view
    }()

    @View private var infoLabel: UILabel = {
        let view = UILabel()
        view.text = localized("address_poisoning.pop_up.label.trusted_info")
        view.font = .Avenir.medium.withSize(11.0)
        view.numberOfLines = 0
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()

    // MARK: - Properties

    var viewModels: [PopUpAddressPoisoningContentCell.ViewModel] = [] {
        didSet { update(viewModels: viewModels) }
    }

    var selectedIndex: Int? { tableView.indexPathForSelectedRow?.row }
    var isTrustedTickSelected: Bool { tickView.isSelected }

    private var dataSource: UITableViewDiffableDataSource<Int, PopUpAddressPoisoningContentCell.ViewModel>?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstratins()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstratins() {

        [tableView, tickView, tickMessageLabel, tickMessageButton, shieldIconView, infoLabel].forEach(addSubview)

        let constraints = [
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tickView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20.0),
            tickView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tickView.widthAnchor.constraint(equalToConstant: 24.0),
            tickView.heightAnchor.constraint(equalToConstant: 24.0),
            tickMessageLabel.topAnchor.constraint(equalTo: tickView.topAnchor),
            tickMessageLabel.leadingAnchor.constraint(equalTo: tickView.trailingAnchor, constant: 10.0),
            tickMessageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            tickMessageLabel.bottomAnchor.constraint(equalTo: tickView.bottomAnchor),
            tickMessageButton.topAnchor.constraint(equalTo: tickMessageLabel.topAnchor),
            tickMessageButton.leadingAnchor.constraint(equalTo: tickMessageLabel.leadingAnchor),
            tickMessageButton.trailingAnchor.constraint(equalTo: tickMessageLabel.trailingAnchor),
            tickMessageButton.bottomAnchor.constraint(equalTo: tickMessageLabel.bottomAnchor),
            shieldIconView.topAnchor.constraint(equalTo: tickView.bottomAnchor, constant: 10.0),
            shieldIconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shieldIconView.widthAnchor.constraint(equalToConstant: 20.0),
            shieldIconView.heightAnchor.constraint(equalToConstant: 20.0),
            infoLabel.topAnchor.constraint(equalTo: shieldIconView.topAnchor),
            infoLabel.leadingAnchor.constraint(equalTo: shieldIconView.trailingAnchor, constant: 10.0),
            infoLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            infoLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: PopUpAddressPoisoningContentCell.self, indexPath: indexPath)
            cell.update(viewModel: model)
            return cell
        }

        tableView.dataSource = dataSource
        tableView.delegate = self

        tickView.onTap = { [weak self] in
            self?.tickView.isSelected.toggle()
        }

        tickMessageButton.onTap = { [weak self] in
            self?.tickView.isSelected.toggle()
        }
    }

    // MARK: - Updates

    private func update(viewModels: [PopUpAddressPoisoningContentCell.ViewModel]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, PopUpAddressPoisoningContentCell.ViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModels)

        dataSource?.apply(snapshot, animatingDifferences: false)
        tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
    }

    private func updateTrustedContactElements(isTrusted: Bool) {
        tickView.isEnabled = !isTrusted
        tickView.isSelected = isTrusted
        tickMessageButton.isEnabled = !isTrusted
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        tableView.backgroundColor = theme.backgrounds.secondary
        tickMessageLabel.textColor = theme.text.links
        shieldIconView.tintColor = theme.text.lightText
        infoLabel.textColor = theme.text.body
    }
}

extension PopUpAddressPoisoningContentView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let isTrusted = viewModels[indexPath.row].isTrusted
        updateTrustedContactElements(isTrusted: isTrusted)
    }
}

final class PopUpAddressPoisoningContentCell: DynamicThemeCell {

    struct ViewModel: Identifiable, Hashable {
        var id: UUID
        let emojiID: String
        let name: String?
        let transactionsCount: Int
        let lastTransaction: String?
        let isTrusted: Bool
    }

    // MARK: - Subviews

    @View private var floatingContentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4.0
        view.layer.borderWidth = 2.0
        return view
    }()

    @View private var emojiView: ScrollableLabel = {
        let view = ScrollableLabel()
        view.label.font = .Avenir.medium.withSize(17.0)
        view.margin = 10.0
        return view
    }()

    @View private var labelsStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        return view
    }()

    @View private var bottomStackView = UIStackView()

    @View private var nameLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.heavy.withSize(14.0)
        return view
    }()

    @View private var transactionCountLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(14.0)
        return view
    }()

    @View private var lastTransactionLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(14.0)
        return view
    }()

    @View private var shieldIconView: UIImageView = {
        let view = UIImageView()
        view.image = .Icons.shieldCheckmark
        view.isHidden = true
        return view
    }()

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupView() {
        backgroundColor = .clear
        selectionStyle = .none
    }

    private func setupConstraints() {

        [floatingContentView, emojiView, labelsStackView].forEach(contentView.addSubview)
        [nameLabel, transactionCountLabel, bottomStackView].forEach(labelsStackView.addArrangedSubview)
        [lastTransactionLabel, shieldIconView].forEach(bottomStackView.addArrangedSubview)

        let constraints = [
            floatingContentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
            floatingContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10.0),
            floatingContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10.0),
            floatingContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10.0),
            emojiView.topAnchor.constraint(equalTo: floatingContentView.topAnchor, constant: 10.0),
            emojiView.leadingAnchor.constraint(equalTo: floatingContentView.leadingAnchor),
            emojiView.trailingAnchor.constraint(equalTo: floatingContentView.trailingAnchor),
            labelsStackView.topAnchor.constraint(equalTo: emojiView.bottomAnchor, constant: 10.0),
            labelsStackView.leadingAnchor.constraint(equalTo: floatingContentView.leadingAnchor, constant: 10.0),
            labelsStackView.trailingAnchor.constraint(equalTo: floatingContentView.trailingAnchor, constant: -10.0),
            labelsStackView.bottomAnchor.constraint(equalTo: floatingContentView.bottomAnchor, constant: -10.0),
            shieldIconView.widthAnchor.constraint(equalToConstant: 20.0),
            shieldIconView.heightAnchor.constraint(equalToConstant: 20.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        floatingContentView.backgroundColor = theme.backgrounds.primary
        floatingContentView.layer.borderColor = theme.icons.active?.cgColor
        floatingContentView.apply(shadow: theme.shadows.box)
        nameLabel.textColor = theme.text.body
        transactionCountLabel.textColor = theme.text.body
        lastTransactionLabel.textColor = theme.text.body
        shieldIconView.tintColor = theme.text.links
    }

    func update(viewModel: ViewModel) {
        emojiView.label.text = viewModel.emojiID
        nameLabel.text = viewModel.name
        nameLabel.isHidden = viewModel.name == nil
        transactionCountLabel.text = localized("address_poisoning.label.transaction_count", arguments: viewModel.transactionsCount)
        lastTransactionLabel.text = localized("address_poisoning.label.last_transction", arguments: viewModel.lastTransaction ?? localized("address_poisoning.label.last_transction.never"))
        shieldIconView.isHidden = !viewModel.isTrusted
    }

    private func update(isElevated: Bool) {
        floatingContentView.alpha = isElevated ? 1.0 : 0.0
    }

    // MARK: - Actions

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        UIView.animate(withDuration: 0.2) {
            self.update(isElevated: selected)
        }
    }
}
