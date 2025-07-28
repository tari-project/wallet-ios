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
import Combine

final class HomeView: DynamicThemeView {
    // MARK: - Subviews

    var isBalanceHidden = false {
        didSet {
            balanceLabel.isHidden = isBalanceHidden
            balanceHiddenLabel.isHidden = !isBalanceHidden
            update(availableBalance: availableBalance)
        }
    }

    @TariView private var titleLabel: StylisedLabel = {
        let view = StylisedLabel(withStyle: .heading2XL)
        view.text = "Tari Universe"
        return view
    }()

    @TariView private var syncStatusView: SyncStatusView = {
        let view = SyncStatusView()
        view.isHidden = true
        return view
    }()

    @TariView private var balanceTitleLabel: UILabel = {
        let view = UILabel()
        view.font = .Poppins.Regular.withSize(17)
        view.textColor = .white
        view.text = "Wallet Balance"
        view.alpha = 0.5
        return view
    }()

    @TariView var activeMinersView: MinersGradientView = {
        var view = MinersGradientView()
        return view
    }()

    @TariView private var walletCardView: UIImageView = {
        var view = UIImageView(image: .walletCard)
        return view
    }()

    @TariView private var discloseButton: DynamicThemeBaseButton = {
        var button = DynamicThemeBaseButton()
        button.setImage(.discloseHide, for: .normal)
        return button
    }()

    @TariView private var sendButton: StylisedButton = {
        var button = StylisedButton(withStyle: .outlinedInverted, withSize: .subSmall)
        button.setTitle("Send", for: .normal)
        return button
    }()

    @TariView private var receiveButton: StylisedButton = {
        var button = StylisedButton(withStyle: .outlinedInverted, withSize: .subSmall)
        button.setTitle("Receive", for: .normal)
        return button
    }()

    @TariView private var activityLabel: StylisedLabel = {
        let view = StylisedLabel(withStyle: .headingXL)
        view.text = "Recent activity"
        return view
    }()

    @TariView private var buttonsStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 20.0
        return view
    }()

    @TariView private var qrCodeScannerButton: BaseButton = {
        let view = BaseButton()
        view.setImage(UIImage(systemName: "qrcode"), for: .normal)
        view.tintColor = .Static.white
        return view
    }()

    @TariView private var balanceContentView = UIView()

    @TariView private var balanceHiddenLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.Poppins.SemiBold.withSize(56.0)
        label.textColor = .white
        label.text = "*******"
        return label
    }()

    @TariView private var balanceLabel: UILabel = {
        let view = UILabel()
        view.font = .Poppins.SemiBold.withSize(56.0)
        view.textColor = .white
        view.adjustsFontSizeToFitWidth = true
        view.minimumScaleFactor = 0.5
        return view
    }()

    @TariView private var availableBalanceContentView = UIView()

    @TariView private var availableBalanceTitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("home.label.spendable")
        view.textColor = .Static.white
        view.font = .Poppins.Regular.withSize(17)
        return view
    }()

    @TariView private var availableBalanceLabel: UILabel = {
        let view = UILabel()
        view.font = .Poppins.Regular.withSize(17)
        view.textColor = .white.withAlphaComponent(0.5)
        view.adjustsFontSizeToFitWidth = true
        view.minimumScaleFactor = 0.5
        return view
    }()

    @TariView private var disclaimerButton: BaseButton = {
        let view = BaseButton()
        view.setTitle("?", for: .normal)
        view.titleLabel?.font = .Poppins.Regular.withSize(13)
        view.setTitleColor(.white.withAlphaComponent(0.5), for: .normal)
        view.backgroundColor = .clear
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        return view
    }()

    @TariView private var amountHelpButton: BaseButton = {
        let view = BaseButton()
        view.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
        view.tintColor = .Static.white
        return view
    }()

    @TariView private var headerView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    @TariView private var transactionTableView: UITableView = {
        let view = UITableView()
        view.register(type: HomeViewTransactionCell.self)
        view.register(type: HomeTransactionsPlaceholderCell.self)
        view.estimatedRowHeight = 44.0
        view.rowHeight = UITableView.automaticDimension
        view.backgroundColor = .clear
        view.separatorStyle = .none
        view.bounces = true
        view.contentInsetAdjustmentBehavior = .never
        view.isUserInteractionEnabled = true
        return view
    }()

    @TariView private var versionBadgeView: VersionBadgeView = {
        let view = VersionBadgeView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties


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
    var onAmountHelpButtonTap: (() -> Void)?
    var onSendButtonTap: (() -> Void)?
    var onReceiveButtonTap: (() -> Void)?
    var onTransactionCellTap: ((_ identifier: UInt64) -> Void)?
    var onStartMiningTap: (() -> Void)?
    var onDisclaimerButtonTap: (() -> Void)?

    private var transactionsDataSource: UITableViewDiffableDataSource<Int, HomeViewTransactionCell.ViewModel>?
    private var avatarConstraints: [NSLayoutConstraint] = []

    var isSyncInProgress: Bool = false {
        didSet {
            print("IsSyncInProgress:", !isSyncInProgress)
            syncStatusView.isHidden = !isSyncInProgress
            sendButton.isEnabled = !isSyncInProgress
            transactionTableView.isScrollEnabled = !isSyncInProgress
        }
    }

    private var cancellables: Set<AnyCancellable> = []

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

    private func setupViews() {
        balanceHiddenLabel.isHidden = true
    }

    private func setupConstraints() {
        balanceHiddenLabel.isHidden = true

        // Add main components
        [transactionTableView, syncStatusView].forEach(addSubview)

        // Table view constraints
        let tableViewConstraints = [
            transactionTableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            transactionTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            transactionTableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            transactionTableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        // Sync status view constraints
        let syncStatusConstraints = [
            syncStatusView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            syncStatusView.centerXAnchor.constraint(equalTo: centerXAnchor),
            syncStatusView.widthAnchor.constraint(equalToConstant: 370),
            syncStatusView.heightAnchor.constraint(equalToConstant: 97)
        ]

        NSLayoutConstraint.activate(tableViewConstraints + syncStatusConstraints)

        headerView.isUserInteractionEnabled = true
        headerView.translatesAutoresizingMaskIntoConstraints = false
        // Add header components
        [titleLabel, versionBadgeView, activeMinersView, walletCardView, balanceLabel,
         balanceTitleLabel, discloseButton, availableBalanceLabel, disclaimerButton, sendButton,
         receiveButton, activityLabel, balanceHiddenLabel].forEach { view in
            view.isUserInteractionEnabled = true
            headerView.addSubview(view)
        }

        // Header constraints
        let headerConstraints = [
            titleLabel.leftAnchor.constraint(equalTo: activeMinersView.leftAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),

            versionBadgeView.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 10),
            versionBadgeView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            versionBadgeView.heightAnchor.constraint(equalToConstant: 20),

            activeMinersView.widthAnchor.constraint(equalToConstant: 370),
            activeMinersView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            activeMinersView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            activeMinersView.heightAnchor.constraint(equalToConstant: 79),

            walletCardView.topAnchor.constraint(equalTo: activeMinersView.bottomAnchor, constant: 10),
            walletCardView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            walletCardView.widthAnchor.constraint(equalToConstant: 370),
            walletCardView.heightAnchor.constraint(equalToConstant: 200),

            balanceTitleLabel.leftAnchor.constraint(equalTo: walletCardView.leftAnchor, constant: 18),
            balanceTitleLabel.bottomAnchor.constraint(equalTo: balanceLabel.topAnchor),

            discloseButton.centerYAnchor.constraint(equalTo: balanceTitleLabel.centerYAnchor),
            discloseButton.leftAnchor.constraint(equalTo: balanceTitleLabel.rightAnchor, constant: 3),
            discloseButton.widthAnchor.constraint(equalToConstant: 20),
            discloseButton.heightAnchor.constraint(equalToConstant: 20),

            balanceLabel.leftAnchor.constraint(equalTo: walletCardView.leftAnchor, constant: 20),
            balanceLabel.rightAnchor.constraint(lessThanOrEqualTo: walletCardView.rightAnchor, constant: -20),
            balanceLabel.bottomAnchor.constraint(equalTo: availableBalanceLabel.topAnchor, constant: 4),

            balanceHiddenLabel.leftAnchor.constraint(equalTo: balanceLabel.leftAnchor),
            balanceHiddenLabel.rightAnchor.constraint(equalTo: balanceLabel.rightAnchor),
            balanceHiddenLabel.centerXAnchor.constraint(equalTo: balanceLabel.centerXAnchor),
            balanceHiddenLabel.centerYAnchor.constraint(equalTo: balanceLabel.centerYAnchor),
            balanceHiddenLabel.widthAnchor.constraint(equalTo: balanceLabel.widthAnchor),

            availableBalanceLabel.leftAnchor.constraint(equalTo: balanceLabel.leftAnchor),
            availableBalanceLabel.rightAnchor.constraint(lessThanOrEqualTo: walletCardView.rightAnchor, constant: -20),
            availableBalanceLabel.bottomAnchor.constraint(equalTo: walletCardView.bottomAnchor, constant: -20),

            disclaimerButton.centerYAnchor.constraint(equalTo: availableBalanceLabel.centerYAnchor),
            disclaimerButton.leftAnchor.constraint(equalTo: availableBalanceLabel.rightAnchor, constant: 4),
            disclaimerButton.widthAnchor.constraint(equalToConstant: 16),
            disclaimerButton.heightAnchor.constraint(equalToConstant: 16),

            sendButton.leftAnchor.constraint(equalTo: walletCardView.leftAnchor, constant: 5),
            sendButton.topAnchor.constraint(equalTo: walletCardView.bottomAnchor, constant: 11),
            sendButton.widthAnchor.constraint(equalToConstant: 180),
            sendButton.heightAnchor.constraint(equalToConstant: 44),

            receiveButton.rightAnchor.constraint(equalTo: walletCardView.rightAnchor, constant: -5),
            receiveButton.topAnchor.constraint(equalTo: walletCardView.bottomAnchor, constant: 11),
            receiveButton.widthAnchor.constraint(equalToConstant: 180),
            receiveButton.heightAnchor.constraint(equalToConstant: 44),

            activityLabel.topAnchor.constraint(equalTo: walletCardView.bottomAnchor, constant: 86),
            activityLabel.leftAnchor.constraint(equalTo: walletCardView.leftAnchor, constant: 0),

            headerView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            headerView.bottomAnchor.constraint(equalTo: activityLabel.bottomAnchor, constant: 20)
        ]

        NSLayoutConstraint.activate(headerConstraints)

        fixHeaderView()
    }

    private func setupCallbacks() {
        transactionsDataSource = UITableViewDiffableDataSource(tableView: transactionTableView) { [weak self] tableView, indexPath, viewModel in
            if viewModel.id == 0 { // Placeholder cell
                let cell = tableView.dequeueReusableCell(type: HomeTransactionsPlaceholderCell.self, indexPath: indexPath)
                cell.onStartMiningButtonTap = self?.onStartMiningTap
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(type: HomeViewTransactionCell.self, indexPath: indexPath)
                cell.update(viewModel: viewModel)
                return cell
            }
        }

        transactionTableView.dataSource = transactionsDataSource
        transactionTableView.delegate = self

        qrCodeScannerButton.onTap = { [weak self] in
            self?.onQRCodeScannerButtonTap?()
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

        discloseButton.onTap = { [weak self] in
            guard let self = self else { return }
            self.isBalanceHidden = !self.isBalanceHidden
        }

        disclaimerButton.onTap = { [weak self] in
            guard let self = self else { return }
            self.onDisclaimerButtonTap?()
        }

        let monitor = AppConnectionHandler.shared.connectionMonitor

        Publishers.CombineLatest3(monitor.$networkConnection, monitor.$baseNodeConnection, monitor.$syncStatus)
            .sink { [weak self] in
                self?.versionBadgeView.updateNetworkStatus(
                    networkConnection: $0,
                    baseNodeStatus: $1,
                    syncStatus: $2
                )
            }
            .store(in: &cancellables)
    }

    // MARK: - Updates

    private func update(activeMiners: String) {
        activeMinersView.setActiveMiners(activeMiners: activeMiners)
    }

    private func update(balance: String) {
        let textColor = UIColor.Static.white
        let formattedBalance = balance
        // Create attributed string with different font sizes
        let attributedString = NSMutableAttributedString()

        // Add the balance value
        let balanceAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: UIFont.Poppins.SemiBold.withSize(56.0)
        ]
        attributedString.append(NSAttributedString(string: formattedBalance, attributes: balanceAttributes))

        // Add the currency symbol with smaller font
        let currencyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.Poppins.SemiBold.withSize(28.0),
            .foregroundColor: textColor
        ]
        attributedString.append(NSAttributedString(string: " " + NetworkManager.shared.currencySymbol, attributes: currencyAttributes))

        balanceLabel.attributedText = attributedString
    }

    private func update(availableBalance: String) {
        let text = isBalanceHidden ? "Available: *******" : "Available: \(availableBalance) " + NetworkManager.shared.currencySymbol
        availableBalanceLabel.text = text
    }

    private func update(transactions: [HomeViewTransactionCell.ViewModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, HomeViewTransactionCell.ViewModel>()
        snapshot.appendSections([0])

        if transactions.isEmpty {
            // Add placeholder cell when no transactions
            snapshot.appendItems([HomeViewTransactionCell.ViewModel(id: 0, titleComponents: [], timestamp: 0, amount: AmountBadge.ViewModel(amount: nil, valueType: .invalidated))])
        } else {
            snapshot.appendItems(transactions)
        }

        transactionsDataSource?.apply(snapshot, animatingDifferences: false)
        activityLabel.isHidden = transactions.isEmpty
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        transactionTableView.reloadData()
    }

    // MARK: - Actions

    func startAnimations() {
        // waveBackgroundView.startAnimation()
        // pulseView.startAnimation()
    }

    func stopAnimations() {
        // waveBackgroundView.stopAnimation()
        // pulseView.stopAnimation()
    }

    public func fixHeaderView() {
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()

        var frame = headerView.frame
        frame.size.width = 378
        frame.size.height = 1
        headerView.frame = frame

        // Calculate the required size
        let size = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        // Create a frame that's at least as wide as the table view
        frame.size.width = 378
        frame.size.height = size.height
        headerView.frame = frame

        transactionTableView.tableHeaderView = headerView
    }
}

extension HomeView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? HomeViewTransactionCell, let identifier = cell.identifier else { return }
        onTransactionCellTap?(identifier)
    }
}
