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

protocol ContactsTableDelegate: class {
    func onScrollTopHit(_: Bool)
    func onSelect(contact: Contact)
    func onSelect(publicKey: PublicKey)
}

class ContactsTableViewController: UITableViewController {
    weak var actionDelegate: ContactsTableDelegate?

    var filter: String = "" {
        didSet {
            if filter.isEmpty {
                filteredRecentPublicKeyList =  recentContactList
                filteredContactList = contactList.sorted(by: { (contact1, contact2) -> Bool in
                    if contact1.alias.0.isEmpty { return false }
                    return contact1.alias.0.lowercased() < contact2.alias.0.lowercased()
                })
            } else {
                filteredRecentPublicKeyList = recentContactList.filter({ (publicKey) -> Bool in
                    guard
                        let wallet = TariLib.shared.tariWallet,
                        let existContact = wallet.contacts.0?.list.0.filter({ $0.publicKey.0 == publicKey}).first
                    else {
                        return publicKey.emojis.0.localizedCaseInsensitiveContains(filter.emojiString)
                    }
                    return existContact.alias.0.localizedCaseInsensitiveContains(filter)
                })

                filteredContactList = contactList.filter {
                    ($0.publicKey.0?.emojis.0.localizedCaseInsensitiveContains(filter.emojiString))!
                        || $0.alias.0.localizedCaseInsensitiveContains(filter)
                }.sorted(by: { (contact1, contact2) -> Bool in
                    if contact1.alias.0.isEmpty { return false }
                    return contact1.alias.0.lowercased() < contact2.alias.0.lowercased()
                })
            }

            tableView.reloadData()
        }
    }

    private var recentContactList: [PublicKey] = []
    private var contactList: [Contact] = []
    private var filteredRecentPublicKeyList: [PublicKey] = []
    private var filteredContactList: [Contact] = []

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

        fetchContacts()
    }

    func getContact(publicKey: PublicKey?) -> Contact? {
        guard let publicKey = publicKey else { return nil }
        return contactList.filter { $0.publicKey.0?.emojis.0 == publicKey.emojis.0 }.first
    }

    private func fetchContacts() {
        TariLib.shared.waitIfWalletIsRestarting { [weak self] _ in
            do {
                try self?.loadContacts()
            } catch {
                UserFeedback.shared.error(
                    title: NSLocalizedString("Failed to load contacts", comment: "Add recipient view"),
                    description: NSLocalizedString("Could not access wallet", comment: "Add recipient view"),
                    error: error
                )
            }
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

        recentContactList = try wallet.recentPublicKeys(limit: 3)

        //Filtered lists are full lists by default
        filteredContactList = contactList
        filteredRecentPublicKeyList = recentContactList

        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 //dont' show 2 lists if both lists aren't populated
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return filteredRecentPublicKeyList.count
        }

        return filteredContactList.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CONTACT_CELL_HEIGHT
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER, for: indexPath) as! ContactCell

        if indexPath.section == 0 {
            cell.setPublicKey(filteredRecentPublicKeyList[indexPath.row])
        } else if indexPath.section == 1 {
            cell.setContact(filteredContactList[indexPath.row])
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //If there's no data in a section, don't show anything
        if (section == 0 && filteredRecentPublicKeyList.count == 0) || (section == 1 && filteredContactList.count == 0) {
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
        sectionHeaderLabel.backgroundColor = .clear
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
            actionDelegate?.onSelect(publicKey: filteredRecentPublicKeyList[indexPath.row])
        } else if indexPath.section == 1 {
            actionDelegate?.onSelect(contact: filteredContactList[indexPath.row])
        }

        return nil
    }

    //Parent component needs to know which direction they're scrolling
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 20 {
            isScrolledToTop = true
        } else {
            isScrolledToTop = false
        }
    }

    func isEmptyList() -> Bool {
        return (filteredRecentPublicKeyList.count + filteredContactList.count) < 1
    }
}
