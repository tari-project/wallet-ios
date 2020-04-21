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
    let CELL_IDENTIFIER = "TransactionTableTableViewCell"
    let SECTION_HEADER_HEIGHT: CGFloat = 35
    weak var actionDelegate: TransactionsTableViewDelegate?
    var refreshTransactionControl = UIRefreshControl()
    var isRefreshing = false {
        didSet {
            //Header view that contains the loading animation needs to update
            self.tableView.reloadData()
        }
    }
    let animatedRefresher = AnimatedRefreshingView()
    private var lastContentOffset: CGFloat = 0
    private var lastScrollDirection: ScrollDirection = .up

    var groupedCompletedTransactions: [[CompletedTransaction]] = []
    var pendingInboundTransactions: [PendingInboundTransaction] = []
    var pendingOutboundTransactions: [PendingOutboundTransaction] = []

    var showsPendingGroup: Bool {
        return pendingInboundTransactions.count > 0 || pendingOutboundTransactions.count > 0
    }

    var showsEmptyState: Bool = false {
        willSet {
            //Stop it from getting re added each time unnecessarily
            if newValue && !showsEmptyState {
                setEmptyView()
            } else if !newValue {
                removeEmptyView()
            }
        }
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

    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        tableView.register(UINib(nibName: CELL_IDENTIFIER, bundle: nil), forCellReuseIdentifier: CELL_IDENTIFIER)
        refreshTransactionControl.addTarget(self, action: #selector(refreshPullTransactions(_:)), for: .valueChanged)
        tableView.addSubview(refreshTransactionControl)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = SECTION_HEADER_HEIGHT
        listenForRefreshUpdates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.refreshTable()

        TariEventBus.onMainThread(self, eventType: .receievedTransaction) { [weak self] (result) in
            guard let _ = self else { return }

            if let tx: PendingInboundTransaction = result?.object as? PendingInboundTransaction {
                //TODO animate in the new TX instead of just refreshing the table below
                TariLogger.verbose("New transaction receieved txId=\(tx.id.0)")
            }
        }

        TariEventBus.onMainThread(self, eventType: .transactionListUpdate) { [weak self] (_) in
            guard let self = self else { return }

            self.refreshTable()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        TariEventBus.unregister(self)
    }

    private func viewSetup() {
        tableView.separatorStyle = .none
        tableView.rowHeight = 74
        view.backgroundColor = Theme.shared.colors.transactionTableBackground
    }

    private func showRefreshingSpinner(_ show: Bool) {
        refreshTransactionControl.attributedTitle = nil

        if show {
            refreshTransactionControl.tintColor = .systemGray
            refreshTransactionControl.subviews.first?.alpha = 1
        } else {
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                guard let self = self else { return }
                self.refreshTransactionControl.tintColor = .clear
                self.refreshTransactionControl.subviews.first?.alpha = 0
            }) { _ in
                //Switch off the pull to refresh part
                self.refreshTransactionControl.endRefreshing()
            }
        }
    }

    private func listenForRefreshUpdates() {
        self.animatedRefresher.setupView(.loading)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
            guard let self = self else { return }
            //We know where refreshing if this is the first load
            self.beginRefreshing()
        })

        //After first load if they bring the app into the foreground listen for the connection starting
        TariEventBus.onMainThread(self, eventType: .torPortsOpened) { [weak self] (_) in
            guard let self = self else { return }
            self.beginRefreshing()
        }

        //Listen for when to stop refreshing
        TariEventBus.onMainThread(self, eventType: .baseNodeSyncComplete) { [weak self] (result) in
            guard let self = self else { return }

            if let success: Bool = result?.object as? Bool {
                if success == true {
                    self.endRefreshingWithSuccess()
                } else {
                    //TODO base node always fails the first few times. When that stabalises we can show an error here.
                }
            }
        }
    }

    private func beginRefreshing() {
        showRefreshingSpinner(false)

        guard !isRefreshing else {
            return
        }
        isRefreshing = true

        animatedRefresher.updateState(.loading)
        animatedRefresher.animateIn()

        try? TariLib.shared.tariWallet?.syncBaseNode()
    }

    private func endRefreshingWithSuccess() {
        guard isRefreshing else {
            return
        }

        self.animatedRefresher.updateState(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
            guard let self = self else { return }

            self.animatedRefresher.animateOut { [weak self] in
                guard let self = self else { return }

                self.isRefreshing = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                    guard let self = self else { return }
                    self.showRefreshingSpinner(true)
                })
            }
        })
    }

    @objc private func refreshPullTransactions(_ sender: UIRefreshControl) {
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

        //All completed txs
        let (completedTransactions, completedTransactionsError) = wallet.completedTransactions
        guard completedTransactionsError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to load transactions", comment: "Home screen"),
                description: NSLocalizedString("Could not load completed transactions", comment: "Home screen"),
                error: completedTransactionsError
            )
            return
        }

        let (groupedTransactions, groupedTransactionsError) = completedTransactions!.groupedByDate
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
    }

    func scrollToTop() {
        if groupedCompletedTransactions.count < 1 {
            return
        }

        let indexPath = NSIndexPath(item: 0, section: 0)
        tableView.scrollToRow(at: indexPath as IndexPath, at: .top, animated: true)
    }
}
