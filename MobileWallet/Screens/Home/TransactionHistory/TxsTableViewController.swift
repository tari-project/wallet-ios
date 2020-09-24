//  TxsTableViewController.swift

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

protocol TxsTableViewDelegate: class {
    func onTxSelect(_: Any)
    func onScrollTopHit(_: Bool)
}

class TxsTableViewController: UITableViewController {

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

    let cellIdentifier = "TxTableViewCell"
    weak var actionDelegate: TxsTableViewDelegate?
    let animatedRefresher = AnimatedRefreshingView()
    private var lastContentOffset: CGFloat = 0
    private var kvoBackupScheduleToken: NSKeyValueObservation?
    var txModels = OrderedSet<TxTableViewModel>()

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
        tableView.prefetchDataSource = self
        viewSetup()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + CATransaction.animationDuration()) {
            self.registerEvents()
        }

        if backgroundType == .intro {
            setIntroView()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(registerEvents), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unregisterEvents), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if backgroundType != .intro && !tableView.isRefreshing() {
            self.safeRefreshTable()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if tableView.refreshControl?.isRefreshing == false {
            animatedRefresher.stateType = .none
        }
    }

    private func viewSetup() {
        setupRefreshControl()
        tableView.register(TxTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.estimatedRowHeight = 300
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        view.backgroundColor = Theme.shared.colors.txTableBackground
    }

    @objc private func registerEvents() {
        //Event for table refreshing
        TariEventBus.onMainThread(self, eventType: .txListUpdate) { [weak self] (_) in
            guard let self = self else { return }
            self.safeRefreshTable()
        }

        TariEventBus.onMainThread(self, eventType: .baseNodeSyncComplete) {(result) in
            if let success: Bool = result?.object as? Bool {
                if success {
                    self.endRefreshingWithSuccess()
                    NotificationManager.shared.cancelAllFutureReminderNotifications()
                } else {
                    self.animatedRefresher.animateOut { [weak self] in
                        self?.tableView.endRefreshing()
                    }
                    self.animatedRefresher.stateType = .none
                }
            }
        }
    }

    @objc private func unregisterEvents() {
        animatedRefresher.animateOut()
        tableView.endRefreshing()
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
        animatedRefresher.updateState(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { [weak self] in
            guard let self = self else { return }
            self.animatedRefresher.animateOut { [weak self] in
                self?.safeRefreshTable()
                self?.animatedRefresher.stateType = .none
            }
        })
    }

    @objc func refresh(_ sender: AnyObject) {
        beginRefreshing()
    }

    func safeRefreshTable(_ completion:(() -> Void)? = nil) {
        TariLib.shared.waitIfWalletIsRestarting { [weak self] (success) in
            if success == true {
                self?.refreshTable()
            }
            completion?()
        }
    }

    private func refreshTable() {
        //All completed/cancelled txs
        let (allTxs, allTxsError) = TariLib.shared.tariWallet!.allTxs
        guard allTxsError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("tx_list.error.grouped_transactions.title", comment: "Transactions list"),
                description: NSLocalizedString("tx_list.error.grouped_transactions.descritpion", comment: "Transactions list"),
                error: allTxsError
            )
            return
        }

        txModels.removeAll()
        allTxs.forEach { (tx) in
            let model = TxTableViewModel(tx: tx)
            txModels.append(model)
        }

        tableView.reloadData()
        tableView.endRefreshing()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        actionDelegate?.onTxSelect(txModels[indexPath.row].tx)
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
    }
}
