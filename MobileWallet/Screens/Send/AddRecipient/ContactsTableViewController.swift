//  ContactsTableViewController.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/02/11
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

protocol ContactsTableDelegate {
    func onScrollTopHit(_: Bool)
    func onSelect(contact: Contact)
}

class ContactsTableViewController: UITableViewController {
    var actionDelegate: ContactsTableDelegate?

    private var recentContactList: [Contact] = []
    private var contactList: [Contact] = []
    private let CELL_IDENTIFIER = "CONTACT_CELL"
    private let CONTACT_CELL_HEIGHT: CGFloat = 70
    private let SIDE_PADDING = Theme.shared.sizes.appSidePadding

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

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.register(ContactCell.self, forCellReuseIdentifier: CELL_IDENTIFIER)

        tableView.dataSource = self
        tableView.delegate = self

        do {
            try loadContacts()
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Failed to load contacts", comment: "Add recipient view"),
                description: NSLocalizedString("Could not access wallet", comment: "Add recipient view"),
                error: error
            )
        }
    }

    private func loadContacts() throws {
        guard let wallet = TariLib.shared.tariWallet else {
            throw WalletErrors.walletNotInitialized
        }

        let (contacts, contactsError) = wallet.contacts
        guard contactsError == nil else {
            throw contactsError!
        }

        let (list, listError) = contacts!.list
        guard listError == nil else {
            throw listError!
        }

        contactList = list
        recentContactList = try contacts!.recentContacts(wallet: wallet, limit: 3)

        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 //dont' show 2 lists if both lists aren't populated
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return recentContactList.count
        }

        return contactList.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CONTACT_CELL_HEIGHT
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER, for: indexPath) as! ContactCell

        if indexPath.section == 0 {
            cell.setContact(recentContactList[indexPath.row])
        } else if indexPath.section == 1 {
            cell.setContact(contactList[indexPath.row])
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //If there's no data in a section, don't show anything
        if (section == 0 && recentContactList.count == 0) || (section == 1 && contactList.count == 0) {
            return UIView()
        }

        let sectionHeaderView = UIView()
        let sectionHeaderLabel = UILabel()

        sectionHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionHeaderView.addSubview(sectionHeaderLabel)

        sectionHeaderView.heightAnchor.constraint(equalToConstant: 35).isActive = true

        sectionHeaderLabel.font = Theme.shared.fonts.transactionDateValueLabel
        sectionHeaderLabel.textColor = Theme.shared.colors.transactionSmallSubheadingLabel
        sectionHeaderLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        sectionHeaderLabel.backgroundColor = Theme.shared.colors.appBackground?.withAlphaComponent(0.2)
        sectionHeaderLabel.heightAnchor.constraint(equalToConstant: sectionHeaderLabel.font.pointSize * 1.3).isActive = true
        sectionHeaderLabel.layer.cornerRadius = 4
        sectionHeaderLabel.layer.masksToBounds = true
        sectionHeaderLabel.sizeToFit()
        sectionHeaderLabel.leadingAnchor.constraint(equalTo: sectionHeaderView.leadingAnchor, constant: SIDE_PADDING).isActive = true
        sectionHeaderLabel.bottomAnchor.constraint(equalTo: sectionHeaderView.bottomAnchor, constant: 0).isActive = true

        return sectionHeaderView
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("Recent Transactions", comment: "Add recipient view")
        }

        return NSLocalizedString("My Contacts", comment: "Add recipient view")
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 {
            actionDelegate?.onSelect(contact: recentContactList[indexPath.row])
        } else if indexPath.section == 1 {
            actionDelegate?.onSelect(contact: contactList[indexPath.row])
        }

        return nil
    }

    //Parent component needs to know which direction they're scrolling
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y <= 20) {
            isScrolledToTop = true
        } else {
            isScrolledToTop = false
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
