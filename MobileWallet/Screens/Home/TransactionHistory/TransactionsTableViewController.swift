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
    func onScrollDirectionChange(_: ScrollDirection)
}

class TransactionsTableViewController: UITableViewController {

    enum BackgroundViewType: Equatable {
        case none
        case intro
        case empty
    }

    var backgroundType: BackgroundViewType = .none {
        didSet {
            if oldValue == backgroundType { return }
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

    let cellIdentifier = "TransactionTableTableViewCell"
    let sectionHeaderHeight: CGFloat = 0
    weak var actionDelegate: TransactionsTableViewDelegate?
    var refreshTransactionControl = UIRefreshControl()
    let animatedRefresher = AnimatedRefreshingView()
    private var lastContentOffset: CGFloat = 0
    private var lastScrollDirection: ScrollDirection = .up

    var groupedCompletedTransactions: [[CompletedTransaction]] = []
    var pendingInboundTransactions: [PendingInboundTransaction] = []
    var pendingOutboundTransactions: [PendingOutboundTransaction] = []

    var showsPendingGroup: Bool {
        return pendingInboundTransactions.count > 0 || pendingOutboundTransactions.count > 0
    }

    lazy var pendingAnimationContainer: AnimationView = {
        let animation = Animation.named("pendingTx")
        var animationContainer = AnimationView()
        animationContainer.animation = animation
        animationContainer.loopMode = .loop
        animationContainer.backgroundBehavior = .pauseAndRestore
        return animationContainer
    }()

    let pendingLabelText = NSLocalizedString("In Progress", comment: "Home view table of transactions")

    init(style: UITableView.Style, backgroundState: BackgroundViewType) {
        self.backgroundType = backgroundState
        super.init(style: style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        self.refreshTable()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.layoutSubviews()
    }

    private func viewSetup() {
        setupRefreshControl()

        tableView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView.estimatedSectionHeaderHeight = UITableView.automaticDimension

        tableView.separatorStyle = .none
        tableView.rowHeight = 74
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 48, left: 0, bottom: 0, right: 0)

        view.backgroundColor = Theme.shared.colors.transactionTableBackground
    }

    @objc private func registerEvents() {
        //Event for table refreshing
        TariEventBus.onMainThread(self, eventType: .transactionListUpdate) { [weak self] (_) in
            guard let self = self else { return }
            self.refreshTable()
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
        TariEventBus.unregister(self)
    }

    private func beginRefreshing() {
        guard refreshTransactionControl.isRefreshing else { return }
        tableView.reloadData()
        animatedRefresher.updateState(.loading)
        animatedRefresher.animateIn()

        do {
            if let wallet = TariLib.shared.tariWallet {
                try wallet.syncBaseNode()
            }
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Base node error", comment: "Refreshing TX list view"),
                description: NSLocalizedString("Could not sync to base node", comment: "Refreshing TX list view"),
                error: error
            )
        }
    }

    private func endRefreshingWithSuccess() {
        guard refreshTransactionControl.isRefreshing else { return }
        animatedRefresher.updateState(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
            guard let self = self else { return }
            self.animatedRefresher.animateOut { [weak self] in
                self?.tableView.reloadData()
                self?.refreshTransactionControl.endRefreshing()
            }
        })
    }

    private func refreshPullTransactions() {
        refreshTransactionControl.programaticallyBeginRefreshing(in: tableView)
        beginRefreshing()
    }

    func refreshTable() {
        guard let wallet = TariLib.shared.tariWallet else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to access wallet", comment: "Home screen"),
                description: ""
            )
            return
        }

        //All completed/cancelled txs
        let (groupedTransactions, groupedTransactionsError) = wallet.groupedCompletedAndCancelledTransactions
        guard groupedTransactionsError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to load transactions", comment: "Home screen"),
                description: NSLocalizedString("Could not load grouped completed transactions", comment: "Home screen"),
                error: groupedTransactionsError
            )
            return
        }

        //All pending inbound
        let (pendingInboundTxs, pendingInboundTxsError) = wallet.pendingInboundTransactions
        guard pendingInboundTxsError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to load transactions", comment: "Home screen"),
                description: NSLocalizedString("Could not load pending inbound transactions", comment: "Home screen"),
                error: pendingInboundTxsError
            )
            return
        }

        let (pendingInboundTxsList, pendingInboundTxsListError) = pendingInboundTxs!.list
        guard pendingInboundTxsListError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to load transactions", comment: "Home screen"),
                description: NSLocalizedString("Could not load list of pending inbound transactions", comment: "Home screen"),
                error: pendingInboundTxsListError
            )
            return
        }

        //All pending outbound
        let (pendingOutboundTxs, pendingOutboundTxsError) = wallet.pendingOutboundTransactions
        guard pendingOutboundTxsError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to load transactions", comment: "Home screen"),
                description: NSLocalizedString("Could not load pending outbound transactions", comment: "Home screen"),
                error: pendingOutboundTxsError
            )
            return
        }

        let (pendingOutboundTxsList, pendingOutboundTxsListError) = pendingOutboundTxs!.list
        guard pendingOutboundTxsListError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to load transactions", comment: "Home screen"),
                description: NSLocalizedString("Could not load list of pending outbound transactions", comment: "Home screen"),
                error: pendingOutboundTxsListError
            )
            return
        }

        groupedCompletedTransactions = groupedTransactions
        pendingInboundTransactions = pendingInboundTxsList
        pendingOutboundTransactions = pendingOutboundTxsList

        tableView.reloadData()
    }

    //Transaction gets tapped
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        var transaction: Any?

        //If it's the first group and we're showing the pending group
        if indexPath.section == 0 && showsPendingGroup {
            if indexPath.row < pendingInboundTransactions.count {
                transaction = pendingInboundTransactions[indexPath.row]
            } else {
                transaction = pendingOutboundTransactions[indexPath.row - pendingInboundTransactions.count]
            }
        } else {
            //Handle as a completed transaction
            let index = showsPendingGroup ? indexPath.section - 1 : indexPath.section
            transaction = groupedCompletedTransactions[index][indexPath.row]
        }

        actionDelegate?.onTransactionSelect(transaction!)

        return nil
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }

    //Parent component needs to know which direction they're scrolling
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.lastContentOffset + 25 < scrollView.contentOffset.y && lastScrollDirection != .down {
            actionDelegate?.onScrollDirectionChange(.down)
            lastScrollDirection = .down
        } else if self.lastContentOffset - 25 > scrollView.contentOffset.y && lastScrollDirection != .up {
            actionDelegate?.onScrollDirectionChange(.up)
            lastScrollDirection = .up
        }

        if scrollView.contentOffset.y < -100 && !refreshTransactionControl.isRefreshing && scrollView.isDragging == true {
            refreshPullTransactions()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func scrollToTop() {
        if groupedCompletedTransactions.count < 1 {
            return
        }

        let indexPath = NSIndexPath(item: 0, section: 0)
        tableView.scrollToRow(at: indexPath as IndexPath, at: .top, animated: true)
    }
}
