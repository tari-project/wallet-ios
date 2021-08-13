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

protocol TxsTableViewDelegate: AnyObject {
    func onTxSelect(_: Any)
    func onScrollTopHit(_: Bool)
}

final class TxsListViewController: UIViewController {

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
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.0 + CATransaction.animationDuration()
        ) {
            [weak self] in
            guard let self = self else { return }
            self.registerEvents()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.registerEvents),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.unregisterEvents),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

    func safeRefreshTable(_ completion:(() -> Void)? = nil) {
        if TariLib.shared.walletState == .started {
            refreshTable(completion)
        } else {
            TariEventBus.onMainThread(self, eventType: .walletStateChanged) {
                [weak self]
                (sender) in
                guard let self = self else { return }
                let walletState = sender!.object as! TariLib.WalletState
                switch walletState {
                case .started:
                    TariEventBus.unregister(self, eventType: .walletStateChanged)
                    self.refreshTable(completion)
                case .startFailed:
                    TariEventBus.unregister(self, eventType: .walletStateChanged)
                default:
                    break
                }
            }
        }
     }

    private func refreshTable(_ completion:(() -> Void)?) {
        txDataUpdateQueue.async(flags: .barrier) {
            if self.fetchTx() == true {
               DispatchQueue.main.async {
                   [weak self] in
                   self?.tableView.reloadData()
               }
           }
           DispatchQueue.main.async { completion?() }
        }
    }

    @discardableResult
    private func fetchTx() -> Bool {

        guard let wallet = TariLib.shared.tariWallet else { return false }

        do {
            var pendingTransactions: [TxProtocol] = try wallet.pendingInboundTransactions().list.0
            pendingTransactions += try wallet.pendingOutboundTransactions().list.0
            var completedTransactions: [TxProtocol] = try wallet.completedTransactions().list.0
            completedTransactions += try wallet.cancelledTransactions().list.0

            pendingTxModels = pendingTransactions
                .sorted {
                    guard let lDate = $0.date.0, let rDate = $1.date.0 else { return false }
                    return lDate > rDate
                }
                .map { TxTableViewModel(tx: $0) }

            completedTxModels = completedTransactions
                .sorted {
                    guard let lDate = $0.date.0, let rDate = $1.date.0 else { return false }
                    return lDate > rDate
                }
                .map { TxTableViewModel(tx: $0) }

            return true
        } catch {
            UserFeedback.shared.error(
                title: localized("tx_list.error.grouped_transactions.title"),
                description: localized("tx_list.error.grouped_transactions.descritpion"),
                error: error
            )
            return false
        }
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
}

// MARK: AnimatedRefreshingView behavior
extension TxsListViewController {

    private func onRefreshTimeout() {
        TariLogger.info("Refresh has timed out.")
        stopListeningToBaseNodeSync()
        refreshTimeoutTimer?.invalidate()
        refreshTimeoutTimer = nil
        endRefreshingWithSuccess()
    }

    private func beginRefreshing() {
        if animatedRefresher.stateType != .none {
            return
        }
        animatedRefresher.updateState(.loading, animated: false)
        animatedRefresher.animateIn()

        if refreshTimeoutTimer == nil {
            refreshTimeoutTimer = Timer.scheduledTimer(
                withTimeInterval: refreshTimeoutPeriodSecs,
                repeats: false
            ) {
                [weak self]
                (timer) in
                timer.invalidate()
                self?.onRefreshTimeout()
            }
        }
        let connectionState = ConnectionMonitor.shared.state
        if connectionState.torBootstrapProgress == 100 {
            syncBaseNode()
        } else {
            TariEventBus.onMainThread(self, eventType: .torConnectionProgress) {
                [weak self] (result) in
                guard let self = self else { return }
                if let progress: Int = result?.object as? Int, progress == 100 {
                    TariEventBus.unregister(self, eventType: .torConnectionProgress)
                    TariEventBus.unregister(self, eventType: .torConnectionFailed)
                    self.beginRefreshing()
                }
            }
            TariEventBus.onMainThread(self, eventType: .torConnectionFailed) {
                [weak self] (_) in
                guard let self = self else { return }
                TariEventBus.unregister(self, eventType: .torConnectionProgress)
                TariEventBus.unregister(self, eventType: .torConnectionFailed)
                self.refreshTimeoutTimer?.invalidate()
                self.refreshTimeoutTimer = nil
                self.endRefreshingWithSuccess()
            }
        }
    }

    private func syncBaseNode() {
        do {
            if let wallet = TariLib.shared.tariWallet {
                hasReceivedTxWhileUpdating = false
                hasBroadcastTxWhileUpdating = false
                hasMinedTxWhileUpdating = false
                hasCancelledTxWhileUpdating = false
                startListeningToBaseNodeSync()
                try wallet.syncBaseNode()
            } else {
                TariLogger.error("Cannot get wallet.")
                refreshTimeoutTimer?.invalidate()
                refreshTimeoutTimer = nil
                endRefreshingWithSuccess()
            }
        } catch {
            refreshTimeoutTimer?.invalidate()
            refreshTimeoutTimer = nil
            endRefreshingWithSuccess()
            UserFeedback.shared.error(
                title: localized("tx_list.error.sync_to_base_node.title"),
                description: localized("tx_list.error.sync_to_base_node.description"),
                error: error
            )
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
        actionDelegate?.onTxSelect(tableViewModel(forIndexPath: indexPath).tx)
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

// MARK: TariBus events observation
extension TxsListViewController {

    @objc private func registerEvents() {
        // Event for table refreshing
        TariEventBus.onMainThread(self, eventType: .txListUpdate) {
            [weak self] (_) in
            guard let self = self else { return }
            /*
            if self.animatedRefresher.stateType != .updateData {
                self.safeRefreshTable()
            }
             */
            // temporary :: display all changes immediately
            // regardless of refresh status
            self.safeRefreshTable()
        }

        TariEventBus.onBackgroundThread(self, eventType: .receivedTx) {
            [weak self] (_) in
            guard let self = self else { return }
            if self.animatedRefresher.stateType == .updateData {
                self.hasReceivedTxWhileUpdating = true
            }
        }

        TariEventBus.onBackgroundThread(self, eventType: .txBroadcast) {
            [weak self] (_) in
            guard let self = self else { return }
            if self.animatedRefresher.stateType == .updateData {
                self.hasBroadcastTxWhileUpdating = true
            }
        }

        TariEventBus.onBackgroundThread(self, eventType: .txMined) {
            [weak self] (_) in
            guard let self = self else { return }
            if self.animatedRefresher.stateType == .updateData {
                self.hasMinedTxWhileUpdating = true
            }
        }

        TariEventBus.onBackgroundThread(self, eventType: .txCancellation) {
            [weak self] (_) in
            guard let self = self else { return }
            if self.animatedRefresher.stateType == .updateData {
                self.hasCancelledTxWhileUpdating = true
            }
        }

        TariEventBus.onBackgroundThread(self, eventType: .txValidationSuccessful) {
            (_) in
            if let wallet = TariLib.shared.tariWallet {
                do {
                    let successful = try wallet.restartTxBroadcast()
                    TariLogger.info("Restart tx broadcast is successful? \(successful)")
                } catch {
                    TariLogger.error("Error while restarting tx broadcast: \(error.localizedDescription)")
                }
            }
        }
    }

    private func startListeningToBaseNodeSync() {
        TariEventBus.onMainThread(self, eventType: .baseNodeSyncComplete) {
            [weak self]
            (result) in
            guard let self = self else { return }
            if let result: [String: Any] = result?.object as? [String: Any] {
                let result = result["result"] as! BaseNodeValidationResult
                switch result {
                case .success:
                    self.refreshTimeoutTimer?.invalidate()
                    self.refreshTimeoutTimer = nil
                    self.animatedRefresher.stateType = .updateData
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        [weak self] in
                        guard let self = self else { return }
                        if self.animatedRefresher.stateType != .none {
                            self.animatedRefresher.playUpdateSequence(
                                hasReceivedTx: self.hasReceivedTxWhileUpdating,
                                hasMinedTx: self.hasMinedTxWhileUpdating,
                                hasBroadcastTx: self.hasBroadcastTxWhileUpdating,
                                hasCancelledTx: self.hasCancelledTxWhileUpdating
                            ) {
                                [weak self] in
                                self?.endRefreshingWithSuccess()
                            }
                        }
                        NotificationManager.shared.cancelAllFutureReminderNotifications()
                    }
                case .baseNodeNotInSync:
                    fallthrough
                case .failure:
                    // change base node
                    do {
                        TariLogger.warn("Base node sync failed or base node not in sync. Setting another random peer.")
                        try TariLib.shared.update(baseNode: .randomNode(), syncAfterSetting: true)
                    } catch {
                        TariLogger.error("Failed to add random base node peer")
                    }
                    // retry sync
                    self.syncBaseNode()
                case .aborted:
                    self.refreshTimeoutTimer?.invalidate()
                    self.refreshTimeoutTimer = nil
                    self.endRefreshingWithSuccess()
                }
            }
        }
    }

    private func stopListeningToBaseNodeSync() {
        TariEventBus.unregister(self, eventType: .baseNodeSyncComplete)
    }

    @objc private func unregisterEvents() {
        animatedRefresher.animateOut()
        tableView.endRefreshing()
        animatedRefresher.stateType = .none
        TariEventBus.unregister(self)
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

        view.backgroundColor = Theme.shared.colors.txTableBackground
    }

    private func setEmptyView() {
        let emptyView = UIView(frame: CGRect(x: tableView.center.x, y: tableView.center.y, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(messageLabel)

        messageLabel.numberOfLines = 0
        messageLabel.text = localized("tx_list.empty")
        messageLabel.textAlignment = .center
        messageLabel.textColor = Theme.shared.colors.txSmallSubheadingLabel
        messageLabel.font = Theme.shared.fonts.txListEmptyMessageLabel

        messageLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -20).isActive = true
        messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: messageLabel.font.pointSize * 1.2).isActive = true

        tableView.backgroundView = emptyView
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
        let introView = UIView(
            frame: CGRect(
                x: tableView.center.x,
                y: tableView.center.y,
                width: tableView.bounds.size.width,
                height: tableView.bounds.size.height
            )
        )

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        introView.addSubview(titleLabel)

        let titleText = localized("tx_list.intro")

        let attributedTitle = NSMutableAttributedString(
            string: titleText,
            attributes: [NSAttributedString.Key.font: Theme.shared.fonts.introTitle]
        )

        titleLabel.attributedText = attributedTitle
        titleLabel.textAlignment = .center
        titleLabel.centerYAnchor.constraint(
            equalTo: introView.centerYAnchor
        ).isActive = true
        titleLabel.centerXAnchor.constraint(
            equalTo: introView.centerXAnchor
        ).isActive = true

        titleLabel.heightAnchor.constraint(
            greaterThanOrEqualToConstant: titleLabel.font.pointSize * 1.2
        ).isActive = true

        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        introView.addSubview(messageLabel)

        messageLabel.text = localized("tx_list.intro_message")
        messageLabel.textAlignment = .center
        messageLabel.textColor = Theme.shared.colors.txSmallSubheadingLabel
        messageLabel.font = Theme.shared.fonts.txListEmptyMessageLabel

        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15).isActive = true
        messageLabel.centerXAnchor.constraint(equalTo: introView.centerXAnchor).isActive = true
        messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: messageLabel.font.pointSize * 1.2).isActive = true

        let waveAnimation = AnimationView()
        waveAnimation.backgroundBehavior = .pauseAndRestore
        waveAnimation.animation = Animation.named(.waveEmoji)
        introView.addSubview(waveAnimation)

        waveAnimation.translatesAutoresizingMaskIntoConstraints = false
        waveAnimation.widthAnchor.constraint(equalToConstant: 70).isActive = true
        waveAnimation.heightAnchor.constraint(equalToConstant: 70).isActive = true
        waveAnimation.centerXAnchor.constraint(equalTo: introView.centerXAnchor).isActive = true
        waveAnimation.bottomAnchor.constraint(equalTo: titleLabel.topAnchor).isActive = true

        waveAnimation.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: {
                [weak self] _ in
                self?.backgroundType = .none
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + CATransaction.animationDuration()
                ) {
                    [weak self] in
                    self?.tableView.reloadData()
                }
            }
        )

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
        beginRefreshing()
    }
}
