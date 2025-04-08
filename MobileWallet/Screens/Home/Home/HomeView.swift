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

class MinersGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    @View private var startMiningButton: StylisedButton = {
        let startMiningButton = StylisedButton(withStyle: .mining, withSize: .xsmall)
        startMiningButton.setTitle("Start mining", for: .normal)
        return startMiningButton
    }()

    public func setActiveMiners(activeMiners: String) {
        minersLabel.text = activeMiners
    }

    var onStartMiningTap: (() -> Void)? {
        didSet {
            startMiningButton.onTap = onStartMiningTap
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
        setupSubviews()
    }

    @View private var minersLabel: UILabel = {
        let minersLabel = UILabel()
        minersLabel.font = .Poppins.SemiBold.withSize(24)
        minersLabel.textColor = .white
        minersLabel.translatesAutoresizingMaskIntoConstraints = false
        return minersLabel
    }()

    private func setupSubviews() {
        let label = UILabel()

        label.font = .Poppins.Medium.withSize(12)
        label.textColor = .white
        label.alpha = 0.5
        label.text = "Active Miners"
        label.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: .minersIcon)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        [label, iconView, minersLabel, startMiningButton].forEach(addSubview)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            iconView.leftAnchor.constraint(equalTo: label.leftAnchor, constant: 0),
            iconView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            minersLabel.leftAnchor.constraint(equalTo: iconView.rightAnchor, constant: 6),
            minersLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor, constant: 0),
            startMiningButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            startMiningButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -20)
        ])
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(hex: 0x0E1510).cgColor,
            UIColor(hex: 0x07160B).cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.25, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.75, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
        layer.cornerRadius = 16
        clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

final class HomeView: UIView {
    // MARK: - Subviews

    var isBalanceHidden = false {
        didSet {
            balanceLabel.isHidden = isBalanceHidden
            balanceHiddenLabel.isHidden = !isBalanceHidden
        }
    }

    @View private var titleLabel: StylisedLabel = {
        let view = StylisedLabel(withStyle: .heading2XL)
        view.text = "Tari Universe"
        return view
    }()

    @View private var balanceTitleLabel: UILabel = {
        let view = UILabel()
        view.font = .Poppins.Regular.withSize(17)
        view.textColor = .white
        view.text = "Wallet Balance"
        view.alpha = 0.5
        return view
    }()

    @View private var activeMinersView: MinersGradientView = {
        var view = MinersGradientView()
        return view
    }()

    @View private var walletCardView: UIImageView = {
        var view = UIImageView(image: .walletCard)
        return view
    }()

    @View private var discloseButton: DynamicThemeBaseButton = {
        var button = DynamicThemeBaseButton()
        button.setImage(.discloseHide, for: .normal)
        return button
    }()

    @View private var sendButton: StylisedButton = {
        var button = StylisedButton(withStyle: .outlinedInverted, withSize: .subSmall)
        button.setTitle("Send", for: .normal)
        return button
    }()

    @View private var receiveButton: StylisedButton = {
        var button = StylisedButton(withStyle: .outlinedInverted, withSize: .subSmall)
        button.setTitle("Receive", for: .normal)
        return button
    }()

    @View private var activityLabel: StylisedLabel = {
        let view = StylisedLabel(withStyle: .headingXL)
        view.text = "Recent activity"
        return view
    }()

    @View private var buttonsStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 20.0
        return view
    }()

    @View private var connectionStatusButton: BaseButton = {
        let view = BaseButton()
        view.tintColor = .Static.white
        return view
    }()

    @View private var qrCodeScannerButton: BaseButton = {
        let view = BaseButton()
        view.setImage(UIImage(systemName: "qrcode"), for: .normal)
        view.tintColor = .Static.white
        return view
    }()

    @View private var balanceContentView = UIView()

    @View private var balanceHiddenLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.Poppins.SemiBold.withSize(56.0)
        label.textColor = .white
        label.text = "*****"
        return label
    }()

    @View private var balanceLabel: AnimatedBalanceLabel = {
        let view = AnimatedBalanceLabel()
        view.animationSpeed = .slow
        view.adjustFontToFitWidth = false
        return view
    }()

    @View private var unitLabel: UILabel = {
        let view = UILabel()
        view.font = .Poppins.SemiBold.withSize(22)
        view.textColor = .white
        view.text = "tXTM"
        return view
    }()

    @View private var availableBalanceContentView = UIView()

    @View private var availableBalanceTitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("home.label.spendable")
        view.textColor = .Static.white
        view.font = .Poppins.Medium.withSize(12.0)
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
        view.tintColor = .Static.white
        return view
    }()

    @View private var avatarContentView = UIView()

//    @View private var avatarView: RoundedGlassContentView<RoundedAvatarView> = {
//        let view = RoundedGlassContentView<RoundedAvatarView>()
//        view.borderWidth = 16.0
//        view.subview.backgroundColorType = .static
//        return view
//    }()

//    @View private var avatarButton = BaseButton()

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
        view.setTitleColor(.Static.white, for: .normal)
        view.titleLabel?.font = .Poppins.Medium.withSize(12.0)
        return view
    }()

    // MARK: - Properties

    var connectionStatusIcon: UIImage? {
        get { connectionStatusButton.image(for: .normal) }
        set {
            UIView.transition(with: connectionStatusButton, duration: 0.5, options: .transitionCrossDissolve) {
                self.connectionStatusButton.setImage(newValue, for: .normal)
            }
        }
    }

    var activeMiners: String = "" {
        didSet { update(activeMiners: activeMiners) }
    }

    var balance: String = "" {
        didSet { update(balance: balance) }
    }

    var availableBalance: String = "" {
        didSet { update(availableBalance: availableBalance) }
    }

    var username: String = ""

    var transactions: [HomeViewTransactionCell.ViewModel] = [] {
        didSet { update(transactions: transactions) }
    }

    var onHideShowBalanceTap: (() -> Void)?
    var onConnetionStatusButtonTap: (() -> Void)?
    var onQRCodeScannerButtonTap: (() -> Void)?
    var onAvatarButtonTap: (() -> Void)?
    var onViewAllTransactionsButtonTap: (() -> Void)?
    var onAmountHelpButtonTap: (() -> Void)?
    var onSendButtonTap: (() -> Void)?
    var onReceiveButtonTap: (() -> Void)?
    var onTransactionCellTap: ((_ identifier: UInt64) -> Void)?
    var onStartMiningTap: (() -> Void)?

    private var transactionsDataSource: UITableViewDiffableDataSource<Int, HomeViewTransactionCell.ViewModel>?
    private var avatarConstraints: [NSLayoutConstraint] = []

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

    private func setupViews() {
        balanceHiddenLabel.isHidden = true
    }

    private func setupConstraints() {

        balanceHiddenLabel.isHidden = true

        [walletCardView, balanceLabel, unitLabel, balanceTitleLabel, titleLabel,
         activeMinersView, buttonsStackView, balanceContentView, avatarContentView,
         transactionTableView, transactionPlaceholderView, receiveButton, sendButton,
         activityLabel, discloseButton, balanceHiddenLabel].forEach(addSubview)

        let constraints = [
            balanceTitleLabel.leftAnchor.constraint(equalTo: walletCardView.leftAnchor, constant: 18),
            balanceTitleLabel.topAnchor.constraint(equalTo: walletCardView.topAnchor, constant: 115),
            discloseButton.centerYAnchor.constraint(equalTo: balanceTitleLabel.centerYAnchor),
            discloseButton.leftAnchor.constraint(equalTo: balanceTitleLabel.rightAnchor, constant: 3),
            discloseButton.widthAnchor.constraint(equalToConstant: 20),
            discloseButton.heightAnchor.constraint(equalToConstant: 20),
            titleLabel.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            activeMinersView.widthAnchor.constraint(equalToConstant: 370),
            activeMinersView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activeMinersView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 70),
            activeMinersView.heightAnchor.constraint(equalToConstant: 79),
            walletCardView.topAnchor.constraint(equalTo: activeMinersView.bottomAnchor, constant: 10),
            walletCardView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            walletCardView.widthAnchor.constraint(equalToConstant: 370),
            walletCardView.heightAnchor.constraint(equalToConstant: 200),
            receiveButton.rightAnchor.constraint(equalTo: walletCardView.rightAnchor, constant: -5),
            receiveButton.topAnchor.constraint(equalTo: walletCardView.bottomAnchor, constant: 11),
            sendButton.leftAnchor.constraint(equalTo: walletCardView.leftAnchor, constant: 5),
            sendButton.topAnchor.constraint(equalTo: walletCardView.bottomAnchor, constant: 11),
            balanceLabel.leftAnchor.constraint(equalTo: walletCardView.leftAnchor, constant: 20),
            balanceLabel.bottomAnchor.constraint(equalTo: walletCardView.bottomAnchor, constant: 7),
            balanceHiddenLabel.leftAnchor.constraint(equalTo: balanceLabel.leftAnchor),
            balanceHiddenLabel.rightAnchor.constraint(equalTo: balanceLabel.rightAnchor),
            balanceHiddenLabel.centerXAnchor.constraint(equalTo: balanceLabel.centerXAnchor),
            balanceHiddenLabel.centerYAnchor.constraint(equalTo: balanceLabel.centerYAnchor),
            unitLabel.leftAnchor.constraint(equalTo: balanceLabel.rightAnchor, constant: 3),
            unitLabel.topAnchor.constraint(equalTo: balanceLabel.centerYAnchor, constant: -5),
            activityLabel.topAnchor.constraint(equalTo: walletCardView.bottomAnchor, constant: 86),
            activityLabel.leftAnchor.constraint(equalTo: walletCardView.leftAnchor, constant: 0),
//            viewAllTransactionsButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -55.0),
//            viewAllTransactionsButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            transactionTableView.topAnchor.constraint(equalTo: activityLabel.bottomAnchor, constant: 20.0),
            transactionTableView.leftAnchor.constraint(equalTo: walletCardView.leftAnchor, constant: 0),
            transactionTableView.rightAnchor.constraint(equalTo: walletCardView.rightAnchor, constant: 0),
            transactionTableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            transactionPlaceholderView.topAnchor.constraint(equalTo: transactionTableView.topAnchor),
            transactionPlaceholderView.leadingAnchor.constraint(equalTo: transactionTableView.leadingAnchor),
            transactionPlaceholderView.trailingAnchor.constraint(equalTo: transactionTableView.trailingAnchor),
            transactionPlaceholderView.bottomAnchor.constraint(equalTo: transactionTableView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints + avatarConstraints)
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

        amountHelpButton.onTap = { [weak self] in
            self?.onAmountHelpButtonTap?()
        }

        sendButton.onTap = { [weak self] in
            self?.onSendButtonTap?()
        }

        receiveButton.onTap = { [weak self] in
            self?.onReceiveButtonTap?()
        }

        activeMinersView.onStartMiningTap = { [weak self] in
            self?.onStartMiningTap?()
        }

        transactionPlaceholderView.onStartMiningButtonTap = { [weak self] in
            self?.onStartMiningTap?()
        }

        discloseButton.onTap = {
//            DispatchQueue.main.async {
//                self.isBalanceHidden = !self.isBalanceHidden
//            }
        }
    }

    // MARK: - Updates

    private func update(activeMiners: String) {
        activeMinersView.setActiveMiners(activeMiners: activeMiners)
    }

    private func update(balance: String) {
        let textColor = UIColor.Static.white

        let balanceLabelAttributedText = NSMutableAttributedString(
            string: balance,
            attributes: [
                .font: UIFont.Poppins.SemiBold.withSize(56.0),
                .foregroundColor: textColor
            ]
        )

        let lastNumberOfDigitsToFormat = MicroTari.roundedFractionDigits + 1
        let fractionalNumbersStartIndex = balance.count - lastNumberOfDigitsToFormat

        balanceLabel.offsetIndex = fractionalNumbersStartIndex
        balanceLabel.topOffset = 0
        balanceLabel.attributedText = balanceLabelAttributedText
    }

    private func update(availableBalance: String) {
        availableBalanceLabel.attributedText = NSAttributedString(
            string: availableBalance,
            attributes: [
                .foregroundColor: UIColor.Static.white,
                .font: UIFont.Poppins.Medium.withSize(12.0)
            ]
        )
    }

    private func update(transactions: [HomeViewTransactionCell.ViewModel]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, HomeViewTransactionCell.ViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(transactions)
        transactionsDataSource?.apply(snapshot, animatingDifferences: false)

        activityLabel.isHidden = transactions.isEmpty

        UIView.animate(withDuration: 0.3) {
            self.transactionPlaceholderView.alpha = transactions.isEmpty ? 1.0 : 0.0
        }
    }

    // MARK: - Actions

    func startAnimations() {
//        waveBackgroundView.startAnimation()
//        pulseView.startAnimation()
    }

    func stopAnimations() {
//        waveBackgroundView.stopAnimation()
//        pulseView.stopAnimation()
    }
}

extension HomeView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? HomeViewTransactionCell, let identifier = cell.identifier else { return }
        onTransactionCellTap?(identifier)
    }
}
