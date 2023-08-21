//  HomeView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 22/06/2023
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

final class HomeView: UIView {

    // MARK: - Constants

    private static let avatarWidth = 136.0

    // MARK: - Subviews

    @View private var waveBackgroundView = HomeBackgroundView()

    @View private var buttonsStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 20.0
        return view
    }()

    @View private var connectionStatusButton: BaseButton = {
        let view = BaseButton()
        view.tintColor = .static.white
        return view
    }()

    @View private var qrCodeScannerButton: BaseButton = {
        let view = BaseButton()
        view.setImage(UIImage(systemName: "qrcode"), for: .normal)
        view.tintColor = .static.white
        return view
    }()

    @View private var balanceContentView = UIView()

    @View private var balanceCurrencyView: UIImageView = {
        let view = UIImageView()
        view.tintColor = .static.white
        view.image = .icons.tariGem
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private var balanceLabel: AnimatedBalanceLabel = {
        let view = AnimatedBalanceLabel()
        view.animationSpeed = .slow
        view.adjustFontToFitWidth = false
        return view
    }()

    @View private var availableBalanceContentView = UIView()

    @View private var availableBalanceTitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("home.label.spendable")
        view.textColor = .static.white
        view.font = .Avenir.medium.withSize(12.0)
        return view
    }()

    @View private var availableBalanceCurrencyView: UIImageView = {
        let view = UIImageView()
        view.tintColor = .static.white
        view.image = .icons.tariGem
        view.contentMode = .scaleAspectFit

        return view
    }()

    @View private var availableBalanceLabel: AnimatedBalanceLabel = {
        let view = AnimatedBalanceLabel()
        view.animationSpeed = .slow
        view.adjustFontToFitWidth = false
        return view
    }()

    @View private var amountHelpButton: BaseButton = {
        let view = BaseButton()
        view.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
        view.tintColor = .static.white
        return view
    }()

    @View private var avatarContentView = UIView()

    @View private var avatarView: RoundedGlassContentView<RoundedAvatarView> = {
        let view = RoundedGlassContentView<RoundedAvatarView>()
        view.borderWidth = 16.0
        view.subview.backgroundColorType = .static
        return view
    }()

    @View private var avatarButton = BaseButton()

    @View private var transactionTableView: UITableView = {
        let view = UITableView()
        view.register(type: HomeViewTransactionCell.self)
        view.estimatedRowHeight = 44.0
        view.rowHeight = UITableView.automaticDimension
        view.backgroundColor = .clear
        view.separatorStyle = .none
        view.bounces = false
        return view
    }()

    @View private var transactionPlaceholderView = HomeTransactionsPlaceholderView()

    @View private var viewAllTransactionsButton: BaseButton = {
        let view = BaseButton()
        view.setTitle(localized("home.button.all_transactions"), for: .normal)
        view.setTitleColor(.static.white, for: .normal)
        view.titleLabel?.font = .Avenir.medium.withSize(12.0)
        return view
    }()

    @View private var pulseView = PulseView(radius: avatarWidth)

    // MARK: - Properties

    var connectionStatusIcon: UIImage? {
        get { connectionStatusButton.image(for: .normal) }
        set {
            UIView.transition(with: connectionStatusButton, duration: 0.5, options: .transitionCrossDissolve) {
                self.connectionStatusButton.setImage(newValue, for: .normal)
            }
        }
    }

    var balance: String = "" {
        didSet { update(balance: balance) }
    }

    var availableBalance: String = "" {
        didSet { update(availableBalance: availableBalance) }
    }

    var avatar: String = "" {
        didSet { avatarView.subview.avatar = .text(avatar) }
    }

    var username: String = "" {
        didSet { transactionPlaceholderView.text = localized("home.transaction_list.placeholder", arguments: username) }
    }

    var transactions: [HomeViewTransactionCell.ViewModel] = [] {
        didSet { update(transactions: transactions) }
    }

    var onConnetionStatusButtonTap: (() -> Void)?
    var onQRCodeScannerButtonTap: (() -> Void)?
    var onAvatarButtonTap: (() -> Void)?
    var onViewAllTransactionsButtonTap: (() -> Void)?
    var onAmountHelpButtonTap: (() -> Void)?
    var onTransactionCellTap: ((_ identifier: UInt64) -> Void)?

    private var transactionsDataSource: UITableViewDiffableDataSource<Int, HomeViewTransactionCell.ViewModel>?

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

        [connectionStatusButton, qrCodeScannerButton].forEach(buttonsStackView.addArrangedSubview)
        [balanceCurrencyView, balanceLabel].forEach(balanceContentView.addSubview)
        [availableBalanceTitleLabel, availableBalanceCurrencyView, availableBalanceLabel, amountHelpButton].forEach(availableBalanceContentView.addSubview)
        [pulseView, avatarView, avatarButton].forEach(avatarContentView.addSubview)
        [waveBackgroundView, buttonsStackView, balanceContentView, availableBalanceContentView, avatarContentView, viewAllTransactionsButton, transactionTableView, transactionPlaceholderView].forEach(addSubview)

        let constraints = [
            waveBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            waveBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            waveBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            waveBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonsStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 21.0),
            buttonsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -35.0),
            balanceCurrencyView.widthAnchor.constraint(equalToConstant: 24.0),
            balanceCurrencyView.heightAnchor.constraint(equalToConstant: 24.0),
            qrCodeScannerButton.widthAnchor.constraint(equalToConstant: 24.0),
            qrCodeScannerButton.heightAnchor.constraint(equalToConstant: 24.0),
            balanceContentView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 111.0),
            balanceContentView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 10.0),
            balanceContentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10.0),
            balanceContentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            balanceCurrencyView.topAnchor.constraint(equalTo: balanceContentView.topAnchor, constant: 15.0),
            balanceCurrencyView.leadingAnchor.constraint(equalTo: balanceContentView.leadingAnchor),
            balanceCurrencyView.widthAnchor.constraint(equalToConstant: 16.0),
            balanceCurrencyView.heightAnchor.constraint(equalToConstant: 16.0),
            balanceLabel.topAnchor.constraint(equalTo: balanceContentView.topAnchor),
            balanceLabel.leadingAnchor.constraint(equalTo: balanceCurrencyView.trailingAnchor, constant: 5.0),
            balanceLabel.trailingAnchor.constraint(equalTo: balanceContentView.trailingAnchor),
            balanceLabel.bottomAnchor.constraint(equalTo: balanceContentView.bottomAnchor),
            availableBalanceContentView.topAnchor.constraint(equalTo: balanceContentView.bottomAnchor, constant: 10.0),
            availableBalanceContentView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 10.0),
            availableBalanceContentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10.0),
            availableBalanceContentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            availableBalanceTitleLabel.topAnchor.constraint(equalTo: availableBalanceContentView.topAnchor),
            availableBalanceTitleLabel.leadingAnchor.constraint(equalTo: availableBalanceContentView.leadingAnchor),
            availableBalanceTitleLabel.bottomAnchor.constraint(equalTo: availableBalanceContentView.bottomAnchor),
            availableBalanceCurrencyView.leadingAnchor.constraint(equalTo: availableBalanceTitleLabel.trailingAnchor, constant: 4.0),
            availableBalanceCurrencyView.centerYAnchor.constraint(equalTo: availableBalanceContentView.centerYAnchor),
            availableBalanceCurrencyView.widthAnchor.constraint(equalToConstant: 9.0),
            availableBalanceCurrencyView.heightAnchor.constraint(equalToConstant: 9.0),
            availableBalanceLabel.topAnchor.constraint(equalTo: availableBalanceContentView.topAnchor),
            availableBalanceLabel.leadingAnchor.constraint(equalTo: availableBalanceCurrencyView.trailingAnchor, constant: 4.0),
            availableBalanceLabel.bottomAnchor.constraint(equalTo: availableBalanceContentView.bottomAnchor),
            amountHelpButton.leadingAnchor.constraint(equalTo: availableBalanceLabel.trailingAnchor, constant: 5.0),
            amountHelpButton.trailingAnchor.constraint(equalTo: availableBalanceContentView.trailingAnchor),
            amountHelpButton.centerYAnchor.constraint(equalTo: availableBalanceContentView.centerYAnchor),
            amountHelpButton.widthAnchor.constraint(equalToConstant: 22.0),
            amountHelpButton.heightAnchor.constraint(equalToConstant: 22.0),
            avatarContentView.topAnchor.constraint(equalTo: availableBalanceContentView.bottomAnchor),
            avatarContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            avatarView.centerXAnchor.constraint(equalTo: avatarContentView.centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: avatarContentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: Self.avatarWidth),
            avatarView.heightAnchor.constraint(equalToConstant: Self.avatarWidth),
            avatarButton.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
            viewAllTransactionsButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -55.0),
            viewAllTransactionsButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            transactionTableView.topAnchor.constraint(equalTo: avatarContentView.bottomAnchor),
            transactionTableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 26.0),
            transactionTableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -26.0),
            transactionTableView.bottomAnchor.constraint(equalTo: viewAllTransactionsButton.topAnchor, constant: -20.0),
            transactionTableView.heightAnchor.constraint(equalToConstant: HomeViewTransactionCell.defaultHeight * 2.0),
            transactionPlaceholderView.topAnchor.constraint(equalTo: transactionTableView.topAnchor),
            transactionPlaceholderView.leadingAnchor.constraint(equalTo: transactionTableView.leadingAnchor),
            transactionPlaceholderView.trailingAnchor.constraint(equalTo: transactionTableView.trailingAnchor),
            transactionPlaceholderView.bottomAnchor.constraint(equalTo: transactionTableView.bottomAnchor),
            pulseView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            pulseView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        transactionsDataSource = UITableViewDiffableDataSource(tableView: transactionTableView) { tableView, indexPath, viewModel in
            let cell = tableView.dequeueReusableCell(type: HomeViewTransactionCell.self, indexPath: indexPath)
            cell.update(viewModel: viewModel)
            return cell
        }

        transactionTableView.dataSource = transactionsDataSource
        transactionTableView.delegate = self

        connectionStatusButton.onTap = { [weak self] in
            self?.onConnetionStatusButtonTap?()
        }

        qrCodeScannerButton.onTap = { [weak self] in
            self?.onQRCodeScannerButtonTap?()
        }

        viewAllTransactionsButton.onTap = { [weak self] in
            self?.onViewAllTransactionsButtonTap?()
        }

        avatarButton.onTap = { [weak self] in
            self?.onAvatarButtonTap?()
        }

        amountHelpButton.onTap = { [weak self] in
            self?.onAmountHelpButtonTap?()
        }
    }

    // MARK: - Updates

    private func update(balance: String) {

        guard let textColor = UIColor.static.white else { return }

        let integerFont = UIFont.Avenir.black.withSize(50.0)
        let fractionalFont = UIFont.Avenir.heavy.withSize(18.0)

        let balanceLabelAttributedText = NSMutableAttributedString(
            string: balance,
            attributes: [
                .font: integerFont,
                .foregroundColor: textColor
            ]
        )

        let lastNumberOfDigitsToFormat = MicroTari.roundedFractionDigits + 1

        var baselineOffset = integerFont.capHeight - fractionalFont.capHeight

        if #unavailable(iOS 16.4) {
            baselineOffset /= 2.5
        }

        balanceLabelAttributedText.addAttributes(
            [
                .font: fractionalFont,
                .foregroundColor: textColor,
                .baselineOffset: baselineOffset
            ],
            range: NSRange(location: balance.count - lastNumberOfDigitsToFormat, length: lastNumberOfDigitsToFormat)
        )

        balanceLabel.attributedText = balanceLabelAttributedText
    }

    private func update(availableBalance: String) {

        guard let foregroundColor = UIColor.static.white else { return }

        availableBalanceLabel.attributedText = NSAttributedString(
            string: availableBalance,
            attributes: [
                .foregroundColor: foregroundColor,
                .font: UIFont.Avenir.medium.withSize(12.0)
            ]
        )
    }

    private func update(transactions: [HomeViewTransactionCell.ViewModel]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, HomeViewTransactionCell.ViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(transactions)
        transactionsDataSource?.apply(snapshot, animatingDifferences: false)

        UIView.animate(withDuration: 0.3) {
            self.transactionPlaceholderView.alpha = transactions.isEmpty ? 1.0 : 0.0
        }
    }

    // MARK: - Actions

    func startAnimations() {
        waveBackgroundView.startAnimation()
        pulseView.startAnimation()
    }

    func stopAnimations() {
        waveBackgroundView.stopAnimation()
        pulseView.stopAnimation()
    }
}

extension HomeView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? HomeViewTransactionCell, let identifier = cell.identifier else { return }
        onTransactionCellTap?(identifier)
    }
}
