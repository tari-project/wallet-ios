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

extension TransactionsTableViewController {

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeaderView = UIView.init()
        let sectionHeaderLabel = UILabel()

        sectionHeaderLabel.font = Theme.shared.fonts.transactionDateValueLabel
        sectionHeaderLabel.textColor = Theme.shared.colors.transactionSmallSubheadingLabel
        sectionHeaderLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        sectionHeaderLabel.backgroundColor = Theme.shared.colors.transactionTableBackground?.withAlphaComponent(0.8)
        sectionHeaderLabel.textAlignment = .center

        sectionHeaderLabel.layer.cornerRadius = 4
        sectionHeaderLabel.layer.masksToBounds = true

        sectionHeaderLabel.sizeToFit()
        sectionHeaderLabel.frame = CGRect(x: Theme.shared.sizes.appSidePadding, y: 35.0, width: sectionHeaderLabel.frame.width + 12, height: sectionHeaderLabel.frame.height + 8)

        sectionHeaderView.addSubview(sectionHeaderLabel)

        return sectionHeaderView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60.0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && showsPendingGroup {
            return NSLocalizedString("Pending Transactions", comment: "Home view table of transactions")
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
            showsEmptyState = true
        } else {
            showsEmptyState = false
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
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER, for: indexPath) as! TransactionTableTableViewCell

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

        messageLabel.text = NSLocalizedString("You don’t have any transactions yet", comment: "Home view table when there are no transactions")
        messageLabel.textAlignment = .center
        messageLabel.textColor = Theme.shared.colors.transactionSmallSubheadingLabel
        messageLabel.font = Theme.shared.fonts.transactionListEmptyMessageLabel

        messageLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
        messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: messageLabel.font.pointSize * 1.2).isActive = true

        tableView.backgroundView = emptyView
    }

    func removeEmptyView() {
        tableView.backgroundView = nil
    }

    func setIntroView() {
        let introView = UIView(frame: CGRect(x: tableView.center.x, y: tableView.center.y, width: tableView.bounds.size.width, height: tableView.bounds.size.height))

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        introView.addSubview(titleLabel)

        let titleText = NSLocalizedString("Hello! This is your Tari Wallet", comment: "Home screen untro")

        let attributedTitle = NSMutableAttributedString(
            string: titleText,
            attributes: [NSAttributedString.Key.font: Theme.shared.fonts.introTitle!]
        )

        //Bold first word
        if let firstWordEndPosition = titleText.indexDistance(of: " ") {
            attributedTitle.addAttributes(
                [NSAttributedString.Key.font: Theme.shared.fonts.introTitleBold!],
                range: NSRange(location: 0, length: firstWordEndPosition)
            )
        }

        titleLabel.attributedText = attributedTitle
        titleLabel.textAlignment = .center
        titleLabel.centerYAnchor.constraint(equalTo: introView.centerYAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: introView.centerXAnchor).isActive = true

        titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: titleLabel.font.pointSize * 1.2).isActive = true

        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        introView.addSubview(messageLabel)

        messageLabel.text = NSLocalizedString("Swipe down and I'll show you around your wallet", comment: "Home view table on introdution to wallet")
        messageLabel.textAlignment = .center
        messageLabel.textColor = Theme.shared.colors.transactionSmallSubheadingLabel
        messageLabel.font = Theme.shared.fonts.transactionListEmptyMessageLabel

        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15).isActive = true
        messageLabel.centerXAnchor.constraint(equalTo: introView.centerXAnchor).isActive = true
        messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: messageLabel.font.pointSize * 1.2).isActive = true

        let introImage = UIImageView()
        introImage.image = Theme.shared.images.handWave!
        introImage.translatesAutoresizingMaskIntoConstraints = false
        introView.addSubview(introImage)
        introImage.centerXAnchor.constraint(equalTo: introView.centerXAnchor).isActive = true
        introImage.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -15).isActive = true

        let downArrow = UIImageView()
        downArrow.image = Theme.shared.images.downArrow!
        downArrow.translatesAutoresizingMaskIntoConstraints = false
        introView.addSubview(downArrow)
        downArrow.centerXAnchor.constraint(equalTo: introView.centerXAnchor).isActive = true
        downArrow.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 15).isActive = true

        tableView.backgroundView = introView

        animateWave(imageView: introImage)
    }

    private func animateWave(imageView: UIImageView) {
        let degreesUp: CGFloat = 20.0
        let degreesDown: CGFloat = -15.0
        let duration: TimeInterval = 0.5

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            //Clockwise
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                imageView.transform = CGAffineTransform(rotationAngle: (degreesUp * .pi) / 180.0)
            }, completion: { (_) in
                //Anti clockwise
                UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
                    imageView.transform = CGAffineTransform(rotationAngle: (degreesDown * .pi) / 180.0)
                }, completion: { (_) in
                    //Back to start
                    UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
                        imageView.transform = CGAffineTransform(rotationAngle: 0)
                    })

                })
            })
        })
    }

    func showIntroContent(_ isIntro: Bool) {
        if isIntro {
            showsEmptyState = false
            setIntroView()
        } else {
            removeEmptyView()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: { [ weak self] in
                guard let self = self else { return }
                self.showsEmptyState = true
            })
        }
    }
}
