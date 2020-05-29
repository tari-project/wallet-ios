//  TransactionsTableViewController.TableView.swift

/*
    Package MobileWallet
    Created by Gugulethu on 2019/11/07
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

import Foundation
import UIKit
import Lottie

extension TransactionsTableViewController {

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeaderView = UIView()
        let sectionHeaderLabel = UILabel()

        sectionHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionHeaderView.addSubview(sectionHeaderLabel)

        let labelText = self.tableView(tableView, titleForHeaderInSection: section)

        sectionHeaderLabel.font = Theme.shared.fonts.transactionDateValueLabel
        sectionHeaderLabel.textColor = Theme.shared.colors.transactionSmallSubheadingLabel
        sectionHeaderLabel.text = labelText
        sectionHeaderLabel.textAlignment = .left

        sectionHeaderLabel.bottomAnchor.constraint(equalTo: sectionHeaderView.bottomAnchor).isActive = true
        sectionHeaderLabel.leadingAnchor.constraint(equalTo: sectionHeaderView.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true

        //Add lottie loader if this is the section header for in progress transactions
        if labelText == pendingLabelText {
            sectionHeaderView.addSubview(pendingAnimationContainer)
            pendingAnimationContainer.translatesAutoresizingMaskIntoConstraints = false
            pendingAnimationContainer.widthAnchor.constraint(equalToConstant: 40).isActive = true
            pendingAnimationContainer.heightAnchor.constraint(equalToConstant: 5).isActive = true
            pendingAnimationContainer.centerYAnchor.constraint(equalTo: sectionHeaderLabel.centerYAnchor).isActive = true
            pendingAnimationContainer.trailingAnchor.constraint(equalTo: sectionHeaderView.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
            pendingAnimationContainer.play()
        }

        return sectionHeaderView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && tableView.isRefreshing() {
            return 30
        }
        return 16
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && showsPendingGroup {
            return pendingLabelText
        } else {
            let index = showsPendingGroup ? section - 1 : section

            guard let tx = groupedCompletedTransactions[index].first else {
                return ""
            }

            let (date, _) = tx.date
            if let displayDate = date {
                return displayDate.relativeDayFromToday()
            }
        }

        return ""
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        var count = groupedCompletedTransactions.count

        if showsPendingGroup {
            count += 1
        }

        if count == 0 {
            backgroundType = .empty
        } else {
            backgroundType = .none
        }

        return count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //If it's the first group and we're showing the pending group
        if section == 0 && showsPendingGroup {
            return pendingInboundTransactions.count + pendingOutboundTransactions.count
        }

        let index = showsPendingGroup ? section - 1 : section

        return groupedCompletedTransactions[index].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TransactionTableViewCell

        //If it's the first group and we're showing the pending group
        if indexPath.section == 0 && showsPendingGroup {
            if indexPath.row < pendingInboundTransactions.count {
                let inboundTransaction = pendingInboundTransactions[indexPath.row]
                cell.setDetails(pendingInboundTransaction: inboundTransaction)
            } else {
                let outboundTransaction = pendingOutboundTransactions[indexPath.row - pendingInboundTransactions.count]
                cell.setDetails(pendingOutboundTransaction: outboundTransaction)
            }
        } else {
            //Handle as a completed transaction
            let index = showsPendingGroup ? indexPath.section - 1 : indexPath.section
            let transaction = groupedCompletedTransactions[index][indexPath.row]
            cell.setDetails(completedTransaction: transaction)
        }

        return cell
    }

    func setEmptyView() {
        let emptyView = UIView(frame: CGRect(x: tableView.center.x, y: tableView.center.y, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(messageLabel)

        messageLabel.numberOfLines = 0
        messageLabel.text = NSLocalizedString("We don’t see any transactions yet.\nHopefully something happens soon…🤞 ", comment: "Home view table when there are no transactions")
        messageLabel.textAlignment = .center
        messageLabel.textColor = Theme.shared.colors.transactionSmallSubheadingLabel
        messageLabel.font = Theme.shared.fonts.transactionListEmptyMessageLabel

        messageLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -50).isActive = true
        messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: messageLabel.font.pointSize * 1.2).isActive = true

        tableView.backgroundView = emptyView
    }

    func removeBackgroundView() {
        UIView.animate(withDuration: CATransaction.animationDuration(), animations: { [weak self] in
            self?.tableView.backgroundView?.alpha = 0.0
        }) { [weak self] (_) in
            self?.tableView.backgroundView = nil
        }
    }

    func setIntroView() {
        let introView = UIView(frame: CGRect(x: tableView.center.x, y: tableView.center.y, width: tableView.bounds.size.width, height: tableView.bounds.size.height))

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        introView.addSubview(titleLabel)

        let titleText = NSLocalizedString("Your wallet setup is complete.", comment: "Home screen untro")

        let attributedTitle = NSMutableAttributedString(
            string: titleText,
            attributes: [NSAttributedString.Key.font: Theme.shared.fonts.introTitle!]
        )

        titleLabel.attributedText = attributedTitle
        titleLabel.textAlignment = .center
        titleLabel.centerYAnchor.constraint(equalTo: introView.centerYAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: introView.centerXAnchor).isActive = true

        titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: titleLabel.font.pointSize * 1.2).isActive = true

        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        introView.addSubview(messageLabel)

        messageLabel.text = NSLocalizedString("You’re ready to start exploring", comment: "Home view table on introdution to wallet")
        messageLabel.textAlignment = .center
        messageLabel.textColor = Theme.shared.colors.transactionSmallSubheadingLabel
        messageLabel.font = Theme.shared.fonts.transactionListEmptyMessageLabel

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

        waveAnimation.play(fromProgress: 0, toProgress: 1, loopMode: .playOnce, completion: { [weak self] _ in
            self?.backgroundType = .none
            DispatchQueue.main.asyncAfter(deadline: .now() + CATransaction.animationDuration()) { [weak self] in
                self?.refreshTable()
            }
        })

        tableView.backgroundView = introView
    }

    func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.clipsToBounds = true
        refreshControl.backgroundColor = .clear
        refreshControl.tintColor = .clear
        refreshControl.subviews.first?.alpha = 0

        tableView.refreshControl = refreshControl
        refreshControl.addSubview(animatedRefresher)

        animatedRefresher.translatesAutoresizingMaskIntoConstraints = false
        animatedRefresher.topAnchor.constraint(equalTo: refreshControl.topAnchor, constant: 3).isActive = true

        let leading = animatedRefresher.leadingAnchor.constraint(equalTo: refreshControl.leadingAnchor, constant: Theme.shared.sizes.appSidePadding)
        leading.isActive = true
        leading.priority = .defaultHigh

        let trailing = animatedRefresher.trailingAnchor.constraint(equalTo: refreshControl.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding)
        trailing.isActive = true
        trailing.priority = .defaultHigh

        animatedRefresher.heightAnchor.constraint(equalToConstant: 48).isActive = true
        animatedRefresher.setupView(.loading)
    }
}
