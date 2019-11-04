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

class TransactionsTableViewController: UITableViewController {
    private let CELL_IDENTIFIER = "TransactionTableTableViewCell"
    private let transactions = dummyTransactions

    override func viewDidLoad() {
        super.viewDidLoad()

        viewSetup()
        tableView.register(UINib(nibName: CELL_IDENTIFIER, bundle: nil), forCellReuseIdentifier: CELL_IDENTIFIER)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // TODO return number of date sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return transactions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER, for: indexPath) as! TransactionTableTableViewCell

        let transaction = transactions[indexPath.row]

        cell.icon.image = transaction.icon
        cell.userNameLabel.text = transaction.userName
        cell.descriptionLabel.text = transaction.description

        let value = transaction.value
        cell.setValueLabel(value: value)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    private func viewSetup() {
        tableView.separatorStyle = .none
        view.backgroundColor = Theme.shared.colors.transactionTableBackground
        tableView.rowHeight = 74
    }
}
