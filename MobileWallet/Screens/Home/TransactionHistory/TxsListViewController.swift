//  TxsListViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 28.09.2020
	Using Swift 5.0
	Running on macOS 10.15

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
import Lottie
import Combine
import TariCommon

protocol TxsTableViewDelegate: AnyObject {
    func onTxSelect(_: Transaction)
    func onScrollTopHit(_: Bool)
}

final class TxsListViewController: DynamicThemeViewController {

    private enum Section {
        case pending
        case completed

        var title: String {
            switch self {
            case .pending:
                return localized("home.transactions.section.pending")
            case .completed:
                return localized("home.transactions.section.completed")
            }
        }
    }

    enum BackgroundViewType: Equatable {
        case none
        case intro
        case empty
    }

    weak var actionDelegate: TxsTableViewDelegate?

    let tableView = UITableView(frame: .zero, style: .grouped)
    private let animatedRefresher = AnimatedRefreshingView()
    private let refreshTimeoutPeriodSecs = 40.0

    private var pendingTxModels = [TxTableViewModel]()
    private var completedTxModels = [TxTableViewModel]()

    private let txDataUpdateQueue = DispatchQueue(
        label: "com.tari.wallet.tx_list.data_update_queue",
        attributes: .concurrent
    )

    private var hasReceivedTxWhileUpdating = false
    private var hasMinedTxWhileUpdating = false
    private var hasBroadcastTxWhileUpdating = false
    private var hasCancelledTxWhileUpdating = false

    private var refreshTimeoutTimer: Timer?
    private var transactionModelsCancellables = Set<AnyCancellable>()
    private var cancellables = Set<AnyCancellable>()

    var backgroundType: BackgroundViewType = .none {
        didSet {
            if oldValue == backgroundType { return }
            removeBackgroundView { [weak self] in
                guard let `self` = self else { return }
                switch self.backgroundType {
                case .empty:
                    self.setEmptyView()
                case .intro:
                    self.setIntroView()
                default: break
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + CATransaction.animationDuration()) { [weak self] in
            self?.setupEvents()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupTransactionsCallbacks()
        
        if backgroundType != .intro {
            safeRefreshTable()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if tableView.refreshControl?.isRefreshing == false {
            animatedRefresher.stateType = .none
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelTransactionsCallbacks()
    }

    func safeRefreshTable(_ completion:(() -> Void)? = nil) {
        txDataUpdateQueue.async(flags: .barrier) {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                completion?()
            }
        }
    }
    
    private func setupTransactionsCallbacks() {
        
        Publishers.CombineLatest(Tari.shared.transactions.$pendingInbound, Tari.shared.transactions.$pendingOutbound)
            .map { $0 as [Transaction] + $1 }
            .tryMap { try $0.sorted { try $0.timestamp > $1.timestamp }}
            .tryMap { try $0.map { try TxTableViewModel(transaction: $0) }}
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pendingTxModels = $0 }
            .store(in: &transactionModelsCancellables)
        
        Publishers.CombineLatest(Tari.shared.transactions.$completed, Tari.shared.transactions.$cancelled)
            .map { $0 + $1 }
            .tryMap { try $0.sorted { try $0.timestamp > $1.timestamp }}
            .tryMap { try $0.map { try TxTableViewModel(transaction: $0) }}
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.completedTxModels = $0 }
            .store(in: &transactionModelsCancellables)
    }
    
    private func cancelTransactionsCallbacks() {
        transactionModelsCancellables.forEach { $0.cancel() }
        transactionModelsCancellables.removeAll()
    }
    
    private func setupEvents() {
        
        WalletCallbacksManager.shared.receivedTransaction
            .sink { [weak self] _ in
                self?.safeRefreshTable()
                guard self?.animatedRefresher.stateType == .updateData else { return }
                self?.hasReceivedTxWhileUpdating = true
            }
            .store(in: &cancellables)
        
        WalletCallbacksManager.shared.receivedTransactionReply
            .sink { [weak self] _ in self?.safeRefreshTable() }
            .store(in: &cancellables)
        
        WalletCallbacksManager.shared.receivedFinalizedTransaction
            .sink { [weak self] _ in self?.safeRefreshTable() }
            .store(in: &cancellables)
        
        WalletCallbacksManager.shared.transactionBroadcast
            .sink { [weak self] _ in
                self?.safeRefreshTable()
                guard self?.animatedRefresher.stateType == .updateData else { return }
                self?.hasBroadcastTxWhileUpdating = true
            }
            .store(in: &cancellables)
        
        WalletCallbacksManager.shared.transactionMined
            .sink { [weak self] _ in
                self?.safeRefreshTable()
                guard self?.animatedRefresher.stateType == .updateData else { return }
                self?.hasMinedTxWhileUpdating = true
            }
            .store(in: &cancellables)
        
        WalletCallbacksManager.shared.unconfirmedTransactionMined
            .sink { [weak self] _ in self?.safeRefreshTable() }
            .store(in: &cancellables)
        
        WalletCallbacksManager.shared.fauxTransactionConfirmed
            .sink { [weak self] _ in self?.safeRefreshTable() }
            .store(in: &cancellables)
        
        WalletCallbacksManager.shared.fauxTransactionUnconfirmed
            .sink { [weak self] _ in self?.safeRefreshTable() }
            .store(in: &cancellables)
        
        WalletCallbacksManager.shared.transactionSendResult
            .sink { [weak self] _ in self?.safeRefreshTable() }
            .store(in: &cancellables)
        
        WalletCallbacksManager.shared.transactionCancellation
            .sink { [weak self] _ in
                self?.safeRefreshTable()
                guard self?.animatedRefresher.stateType == .updateData else { return }
                self?.hasCancelledTxWhileUpdating = true
            }
            .store(in: &cancellables)
        
        Tari.shared.connectionMonitor.$syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(syncStatus: $0) }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.animatedRefresher.animateOut()
                self?.tableView.endRefreshing()
                self?.animatedRefresher.stateType = .none
            }
            .store(in: &cancellables)
    }

    // MARK: - ViewModel related

    private func sections() -> [Section] {
        var result = [Section]()
        if !pendingTxModels.isEmpty { result.append(.pending) }
        if !completedTxModels.isEmpty { result.append(.completed) }
        return result
    }

    private func tableViewModels(forSection section: Int) -> [TxTableViewModel] {
        switch sections()[section] {
        case .pending:
            return pendingTxModels
        case .completed:
            return completedTxModels
        }
    }

    private func tableViewModel(forIndexPath indexPath: IndexPath) -> TxTableViewModel {
        tableViewModels(forSection: indexPath.section)[indexPath.row]
    }
    
    // MARK: - Handlers
    
    private func handle(syncStatus: TariValidationService.SyncStatus) {
        switch syncStatus {
        case .idle:
            break
        case .syncing:
            self.animateToSyncingState()
        case .synced:
            self.animateToSyncState()
        case .failed:
            break
        }
    }
    
    // MARK: - Animations
    
    private func animateToSyncingState() {
        guard animatedRefresher.stateType == .none else { return }
        animatedRefresher.updateState(.loading, animated: false)
        animatedRefresher.animateIn()
    }
    
    private func animateToSyncState() {
        animatedRefresher.stateType = .updateData
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in guard let self = self else { return }
            if self.animatedRefresher.stateType != .none {
                self.animatedRefresher.playUpdateSequence(
                    hasReceivedTx: self.hasReceivedTxWhileUpdating,
                    hasMinedTx: self.hasMinedTxWhileUpdating,
                    hasBroadcastTx: self.hasBroadcastTxWhileUpdating,
                    hasCancelledTx: self.hasCancelledTxWhileUpdating
                ) { [weak self] in
                    self?.endRefreshingWithSuccess()
                }
            }
            NotificationManager.shared.cancelAllFutureReminderNotifications()
        }
    }
}

// MARK: AnimatedRefreshingView behavior
extension TxsListViewController {

    private func syncBaseNode() {
        do {
            try Tari.shared.validation.sync()
            hasReceivedTxWhileUpdating = false
            hasBroadcastTxWhileUpdating = false
            hasMinedTxWhileUpdating = false
            hasCancelledTxWhileUpdating = false
        } catch {
            refreshTimeoutTimer?.invalidate()
            refreshTimeoutTimer = nil
            endRefreshingWithSuccess()
            PopUpPresenter.show(message: MessageModel(title: localized("tx_list.error.sync_to_base_node.title"), message: localized("tx_list.error.sync_to_base_node.description"), type: .error))
        }
    }

    private func endRefreshingWithSuccess() {
        safeRefreshTable {
            [weak self] in
            self?.animatedRefresher.animateOut {
                [weak self] in
                self?.animatedRefresher.stateType = .none
                self?.hasReceivedTxWhileUpdating = false
                self?.hasMinedTxWhileUpdating = false
                self?.hasBroadcastTxWhileUpdating = false
                self?.hasCancelledTxWhileUpdating = false

                self?.tableView.endRefreshing()
            }
        }
    }

}

// MARK: UITableViewDelegate & UITableViewDataSource
extension TxsListViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        let sectionsCount = sections().count
        guard backgroundType != .intro else { return sectionsCount }
        backgroundType = sectionsCount == 0 ? .empty : .none
        return sectionsCount
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = TransactionsListHeaderView()
        label.title = sections()[section].title
        return label
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { tableViewModels(forSection: section).count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(type: TxTableViewCell.self, indexPath: indexPath)
        let viewModel = tableViewModel(forIndexPath: indexPath)

        cell.configure(with: viewModel)
        viewModel.downloadGif()

        cell.updateCell = {
            DispatchQueue.main.async {
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        actionDelegate?.onTxSelect(tableViewModel(forIndexPath: indexPath).transaction)
    }
}

// MARK: UITableViewDataSourcePrefetching
extension TxsListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { tableViewModel(forIndexPath: $0).downloadGif() }
    }
}

// MARK: UIScrollViewDelegate
extension TxsListViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            actionDelegate?.onScrollTopHit(true)
        } else {
            actionDelegate?.onScrollTopHit(false)
        }
    }
}

// MARK: setup UI
extension TxsListViewController {
    private func viewSetup() {
        if backgroundType == .intro {
            setIntroView()
        }

        setupTableView()
        setupRefreshControl()
    }

    private func setupTableView() {
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        tableView.register(
            TxTableViewCell.self,
            forCellReuseIdentifier: String(describing: TxTableViewCell.self)
        )
        tableView.estimatedRowHeight = 300
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.prefetchDataSource = self
        tableView.delegate = self
        tableView.dataSource = self

        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        tableView.backgroundColor = .clear
    }

    private func setEmptyView() {
        tableView.backgroundView = TxsListEmptyView()
    }

    private func removeBackgroundView(completion:(() -> Void)? = nil) {
        if tableView.backgroundView == nil {
            completion?()
            return
        }

        UIView.animate(
            withDuration: CATransaction.animationDuration(),
            animations: {
                [weak self] in
                self?.tableView.backgroundView?.alpha = 0.0
            }
        ) {
            [weak self] (_) in
            self?.tableView.backgroundView = nil
            completion?()
        }
    }

    private func setIntroView() {
        
        let introView = TxsListIntroView()
        
        introView.playAnimation { [weak self] in
            self?.backgroundType = .none
            DispatchQueue.main.asyncAfter(deadline: .now() + CATransaction.animationDuration()) { [weak self] in
                self?.tableView.reloadData()
            }
        }
        
        tableView.backgroundView = introView
    }

    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.clipsToBounds = true
        refreshControl.backgroundColor = .clear
        refreshControl.tintColor = .clear
        refreshControl.addTarget(
            self,
            action: #selector(self.refresh(_:)),
            for: .valueChanged
        )
        refreshControl.subviews.first?.alpha = 0

        tableView.refreshControl = refreshControl
        view.addSubview(animatedRefresher)
        tableView.bringSubviewToFront(animatedRefresher)

        animatedRefresher.translatesAutoresizingMaskIntoConstraints = false
        animatedRefresher.topAnchor.constraint(
            equalTo: view.topAnchor,
            constant: 5
        ).isActive = true

        let leading = animatedRefresher.leadingAnchor.constraint(
            equalTo: refreshControl.leadingAnchor,
            constant: Theme.shared.sizes.appSidePadding
        )
        leading.isActive = true
        leading.priority = .defaultHigh

        let trailing = animatedRefresher.trailingAnchor.constraint(
            equalTo: refreshControl.trailingAnchor,
            constant: -Theme.shared.sizes.appSidePadding
        )
        trailing.isActive = true
        trailing.priority = .defaultHigh

        animatedRefresher.heightAnchor.constraint(equalToConstant: 48).isActive = true
        animatedRefresher.setupView(.loading)
    }

    @objc private func refresh(_ sender: AnyObject) {
        syncBaseNode()
    }
}

private final class TxsListEmptyView: DynamicThemeView {
    
    // MARK: - Subviews
    
    @View private var label: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.text = localized("tx_list.empty")
        view.font = Theme.shared.fonts.txListEmptyMessageLabel
        view.textAlignment = .center
        return view
    }()
    
    // MARK: - Initialisers
    
    override init() {
        super.init()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupConstraints() {
        
        addSubview(label)
        
        let constraints = [
            label.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Updates
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.body
    }
}

private final class TxsListIntroView: DynamicThemeView {
    
    // MARK: - Subviews
    
    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("tx_list.intro")
        view.font = Theme.shared.fonts.introTitle
        view.textAlignment = .center
        return view
    }()
    
    @View private var messageLabel: UILabel = {
        let view = UILabel()
        view.text = localized("tx_list.intro_message")
        view.font = Theme.shared.fonts.txListEmptyMessageLabel
        view.textAlignment = .center
        return view
    }()
    
    @View private var waveAnimation: AnimationView = {
        let view = AnimationView()
        view.backgroundBehavior = .pauseAndRestore
        view.animation = Animation.named(.waveEmoji)
        return view
    }()
    
    // MARK: - Initialisers
    
    override init() {
        super.init()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupConstraints() {
        
        [titleLabel, messageLabel, waveAnimation].forEach(addSubview)
        
        let constraints = [
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15.0),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: messageLabel.font.pointSize * 1.2),
            waveAnimation.bottomAnchor.constraint(equalTo: titleLabel.topAnchor),
            waveAnimation.widthAnchor.constraint(equalToConstant: 70.0),
            waveAnimation.heightAnchor.constraint(equalToConstant: 70.0),
            waveAnimation.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Updates
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        messageLabel.textColor = theme.text.lightText
    }
    
    // MARK: - Actions
    
    func playAnimation(completion: (() -> Void)?) {
        waveAnimation.play { _ in completion?() }
    }
}


struct MockTx: Transaction {
    var identifier: UInt64 = 1
    var amount: UInt64 = 1234567
    var isOutboundTransaction: Bool = false
    var status: TransactionStatus = .broadcast
    var message: String = "Test Message"
    var timestamp: UInt64 = 12345678
    var address: TariAddress = try! TariAddress(hex: "000000000000000000000000000000000000000000000000000000000000000026")
    var isCancelled: Bool = false
    var isPending: Bool = true
}
