//  TransactionsTableViewController.swift

/*
    Package MobileWallet
    Created by Jason van den Berg on 2019/10/31
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

protocol TransactionsTableViewDelegate: class {
    func onTransactionSelect(_: Any)
    func onScrollTopHit(_: Bool)
}

class TransactionsTableViewController: UITableViewController {

    enum BackgroundViewType: Equatable {
        case none
        case intro
        case empty
    }

    var backgroundType: BackgroundViewType = .none {
        didSet {
            if oldValue == backgroundType && tableView.backgroundView != nil { return }
            switch backgroundType {
            case .empty:
                if oldValue == .intro { backgroundType = .intro; return }
                setEmptyView()
            case .intro:
                setIntroView()
            default:
                removeBackgroundView()
            }
        }
    }

    let cellIdentifier = "TransactionTableViewCell"
    weak var actionDelegate: TransactionsTableViewDelegate?
    let animatedRefresher = AnimatedRefreshingView()
    private var lastContentOffset: CGFloat = 0
    private var kvoBackupScheduleToken: NSKeyValueObservation?
    var transactionModels = [TransactionTableViewModel]()
    var transactions = [TransactionProtocol]() {
        didSet {
            transactionModels.removeAll()
            transactions.forEach { (tx) in
                let model = TransactionTableViewModel(tx: tx)
                transactionModels.append(model)
            }
        }
    }

    private var isScrolledToTop: Bool = true {
        willSet {
            //Only hit the delegate method if value actually changed
            if newValue && !isScrolledToTop {
                actionDelegate?.onScrollTopHit(true)
            } else if !newValue && isScrolledToTop {
                actionDelegate?.onScrollTopHit(false)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        registerEvents()

        if backgroundType == .intro {
            setIntroView()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.refreshPullTransactions()
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(registerEvents), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unregisterEvents), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if backgroundType != .intro {
            self.safeRefreshTable()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if tableView.refreshControl?.isRefreshing == false {
            animatedRefresher.stateType = .none
        }
        observeBackupState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservationBackupState()
    }

    private func viewSetup() {
        setupRefreshControl()

        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 28, left: 0, bottom: 80, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 600

        view.backgroundColor = Theme.shared.colors.transactionTableBackground
    }

    @objc private func registerEvents() {
        //Event for table refreshing
        TariEventBus.onMainThread(self, eventType: .transactionListUpdate) { [weak self] (_) in
            guard let self = self else { return }
            self.safeRefreshTable()
        }

        beginRefreshing()

        TariEventBus.onMainThread(self, eventType: .baseNodeSyncComplete) {(result) in
            if let success: Bool = result?.object as? Bool {
                if success {
                    self.endRefreshingWithSuccess()

                    //TODO this might not be the most appropriate place as it's not directly related to this VC
                    NotificationManager.shared.cancelAllFutureReminderNotifications()
                }
            }
        }
    }

    @objc private func unregisterEvents() {
        animatedRefresher.animateOut()
        animatedRefresher.stateType = .none
        TariEventBus.unregister(self)
    }

    private func beginRefreshing() {
        if animatedRefresher.stateType != .none { return }
        animatedRefresher.stateType = .updateData
        animatedRefresher.updateState(.loading, animated: false)
        animatedRefresher.animateIn()

        do {
            if let wallet = TariLib.shared.tariWallet {
                //If we sync before tor is connected it will fail. A base node sync is triggered when tor does connect.
                if TariLib.shared.isTorConnected {
                    try wallet.syncBaseNode()
                }
            }
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("tx_list.error.sync_to_base_node.title", comment: "Transactions list"),
                description: NSLocalizedString("tx_list.error.sync_to_base_node.description", comment: "Transactions list"),
                error: error
            )
        }
    }

    private func endRefreshingWithSuccess() {
        if animatedRefresher.stateType != .updateData { return }
        guard let refreshControl = tableView.refreshControl, refreshControl.isRefreshing else { return }
        animatedRefresher.updateState(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
            guard let self = self else { return }
            self.animatedRefresher.animateOut { [weak self] in
                self?.safeRefreshTable({ [weak self] in
                    self?.animatedRefresher.stateType = .none
                    self?.tableView.endRefreshing()
                })
            }
        })
    }

    private func refreshPullTransactions() {
        tableView.beginRefreshing()
        beginRefreshing()
    }

    func safeRefreshTable(_ completion:(() -> Void)? = nil) {
        TariLib.shared.waitIfWalletIsRestarting { [weak self] _ in
            self?.refreshTable()
            completion?()
        }
    }

    private func refreshTable() {
        guard let wallet = TariLib.shared.tariWallet else {
            TariLib.shared.waitIfWalletIsRestarting { [weak self] (success) in
                if success == true {
                    self?.refreshTable()
                }
            }
            return
        }

        //All completed/cancelled txs
        let (allTransactions, allTransactionsError) = wallet.allTransactions
        guard allTransactionsError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("tx_list.error.grouped_transactions.title", comment: "Transactions list"),
                description: NSLocalizedString("tx_list.error.grouped_transactions.descritpion", comment: "Transactions list"),
                error: allTransactionsError
            )
            return
        }

        transactions = allTransactions

        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        actionDelegate?.onTransactionSelect(transactions[indexPath.row])
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }

    //Parent component needs to know which direction they're scrolling
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            isScrolledToTop = true
        } else {
            isScrolledToTop = false
        }

        if scrollView.contentOffset.y < -(80 + scrollView.contentInset.top) && !scrollView.isRefreshing() && scrollView.isDragging == true {
            // stop dragging
            scrollView.panGestureRecognizer.isEnabled = false
            scrollView.panGestureRecognizer.isEnabled = true

            refreshPullTransactions()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func scrollToTop() {
        if transactions.count < 1 {
            return
        }

        let indexPath = NSIndexPath(item: 0, section: 0)
        tableView.scrollToRow(at: indexPath as IndexPath, at: .top, animated: true)
    }
}

extension TransactionsTableViewController: ICloudBackupObserver {
    func onUploadProgress(percent: Double, started: Bool, completed: Bool) {
        if started || completed {
            updateRefreshView()
        }
    }

    func failedToCreateBackup(error: Error) {
        updateRefreshView()
    }

    private func observeBackupState() {
        ICloudBackup.shared.addObserver(self)
        updateRefreshView(initialUpdate: true)
        if kvoBackupScheduleToken != nil { return }
        kvoBackupScheduleToken = BackupScheduler.shared.observe(\.isBackupScheduled, options: .new) { [weak self] (_, _) in
            self?.updateRefreshView()
        }
    }

    private func stopObservationBackupState() {
        ICloudBackup.shared.removeObserver(self)
        kvoBackupScheduleToken?.invalidate()
        kvoBackupScheduleToken = nil
    }

    private func updateRefreshView(initialUpdate: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now() + CATransaction.animationDuration()) { [weak self] in
            guard let self = self else { return }
            if  BackupScheduler.shared.isBackupScheduled || ICloudBackup.shared.inProgress {
                self.animatedRefresher.stateType = .backup
                self.tableView.beginRefreshing()
                if BackupScheduler.shared.isBackupScheduled {
                    self.animatedRefresher.updateState(.backupScheduled)
                } else if ICloudBackup.shared.inProgress {
                    self.animatedRefresher.updateState(.backupInProgress)
                }
            } else {
                if !ICloudBackup.shared.isLastBackupFailed && !initialUpdate {
                    self.animatedRefresher.updateState(.backupSuccess)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    guard let self = self else { return }
                    self.animatedRefresher.animateOut { [weak self] in
                        self?.animatedRefresher.stateType = .none
                        self?.safeRefreshTable({ [weak self] in
                            self?.tableView.endRefreshing()
                        })
                    }
                }
            }
            self.animatedRefresher.animateIn()
            self.tableView.layoutSubviews()
        }
    }
}
