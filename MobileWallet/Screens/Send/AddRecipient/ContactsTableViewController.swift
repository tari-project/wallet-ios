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
    func onSelect(tx: TxProtocol)
    func onSendToYat(yat: String)
}

class ContactsTableViewController: UITableViewController {

    weak var actionDelegate: ContactsTableDelegate?

    var filter: String = "" {
        didSet {
            if filter.isEmpty {
                filteredTxs.removeAll()
                filteredTxs.append(contentsOf: recentTxs)
            } else {
                filteredTxs = recentTxs.filter({ (tx) -> Bool in
                    // check if it's a contact
                    if let alias = tx.contact.0?.alias.0, alias.localizedCaseInsensitiveContains(filter) {
                        return true
                    }
                    // check emoji id
                    if let publicKey = (tx.direction == .inbound) ? tx.sourcePublicKey.0 : tx.destinationPublicKey.0,
                        publicKey.emojis.0.localizedCaseInsensitiveContains(filter.emojiString) {
                        return true
                    }
                    // check yat
                    if let yat = (tx.direction == .inbound) ? tx.message.0.sourceYat : tx.message.0.destinationYat,
                        yat.localizedCaseInsensitiveContains(filter.emojiString) {
                        return true
                    }
                    return false
                })
            }

            tableView.reloadData()
        }
    }

    private var recentTxs: [TxProtocol] = []
    private var filteredTxs: [TxProtocol] = []
    private var contactList: [Contact] = []

    private let HEADER_HEIGHT: CGFloat = 20
    private let CELL_IDENTIFIER = "CONTACT_CELL"
    private let CONTACT_CELL_HEIGHT: CGFloat = 70
    private let SIDE_PADDING = Theme.shared.sizes.appSidePadding

    var yatLookupIsInProgress = false

    private var isScrolledToTop: Bool = true {
        willSet {
            // Only hit the delegate method if value actually changed
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
        if TariLib.shared.walletState != .started {
            TariEventBus.onMainThread(self, eventType: .walletStateChanged) {
                [weak self]
                (sender) in
                guard let self = self else { return }
                let walletState = sender!.object as! TariLib.WalletState
                switch walletState {
                case .started:
                    TariEventBus.unregister(self, eventType: .walletStateChanged)
                    do {
                        try self.loadContacts()
                    } catch {
                        UserFeedback.shared.error(
                            title: localized("add_recipient.error.load_contacts.title"),
                            description: localized("add_recipient.error.load_contacts.description"),
                            error: error
                        )
                    }
                case .startFailed:
                    TariEventBus.unregister(self, eventType: .walletStateChanged)
                    UserFeedback.shared.error(
                        title: localized("add_recipient.error.load_contacts.title"),
                        description: localized("add_recipient.error.load_contacts.description")
                    )
                default:
                    break
                }
            }
        } else {
            do {
                try loadContacts()
            } catch {
                UserFeedback.shared.error(
                    title: localized("add_recipient.error.load_contacts.title"),
                    description: localized("add_recipient.error.load_contacts.description"),
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
        recentTxs = try wallet.recentTxs()
        filteredTxs.removeAll()
        filteredTxs.append(contentsOf: recentTxs)
        contactList.sort(by: { (contact1, contact2) -> Bool in
            if contact1.alias.0.isEmpty { return false }
            return contact1.alias.0.lowercased() < contact2.alias.0.lowercased()
        })
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + ((filter.isEmpty && !contactList.isEmpty) ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if filter.isEmpty {
                return min(filteredTxs.count, 3)
            } else if filteredTxs.count == 0
                && filter.containsOnlyEmoji
                && filter.count <= YatAPI.defaultYatEmojiIdLength
                // check if all emojis are from the Yat emoji set
                && YatAPI.shared.textIsPossiblyYat(filter) {
                return 1
            }
            return filteredTxs.count
        } else {
            return filter.isEmpty ? contactList.count : 0
        }
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CONTACT_CELL_HEIGHT
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER, for: indexPath) as! ContactCell
        if indexPath.section == 0 {
            if filteredTxs.count == 0 {
                cell.setYat(filter, yatLookupIsInProgress: yatLookupIsInProgress)
            } else {
                cell.setTx(filteredTxs[indexPath.row])
            }
        } else if indexPath.section == 1 {
            cell.setContact(contactList[indexPath.row])
        }
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && filteredTxs.count == 0 {
            return 0
        }
        return HEADER_HEIGHT
    }

    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        // if there's no data in a section, don't show anything
        if section == 0 && filteredTxs.count == 0 {
            return nil
        }
        if section == 1 && !filter.isEmpty {
            return nil
        }

        let sectionHeaderView = UIView()
        let sectionHeaderLabel = UILabel()

        sectionHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionHeaderView.addSubview(sectionHeaderLabel)

        sectionHeaderView.heightAnchor.constraint(equalToConstant: HEADER_HEIGHT).isActive = true

        sectionHeaderLabel.font = Theme.shared.fonts.contactTableViewSectionHeader
        sectionHeaderLabel.textColor = Theme.shared.colors.txSmallSubheadingLabel
        sectionHeaderLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        sectionHeaderLabel.backgroundColor = .clear
        sectionHeaderLabel.heightAnchor.constraint(
            equalToConstant: sectionHeaderLabel.font.pointSize * 1.3
        ).isActive = true
        sectionHeaderLabel.layer.cornerRadius = 4
        sectionHeaderLabel.layer.masksToBounds = true
        sectionHeaderLabel.sizeToFit()
        sectionHeaderLabel.leadingAnchor.constraint(
            equalTo: sectionHeaderView.leadingAnchor,
            constant: SIDE_PADDING
        ).isActive = true
        sectionHeaderLabel.bottomAnchor.constraint(
            equalTo: sectionHeaderView.bottomAnchor,
            constant: 0
        ).isActive = true

        return sectionHeaderView
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        if section == 0 && filteredTxs.count > 0 {
            return localized("add_recipient.recent_txs")
        } else if section == 1 && filter.isEmpty {
            return localized("add_recipient.my_contacts")
        }
        return nil
    }

    override func tableView(_ tableView: UITableView,
                            willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 {
            if filteredTxs.count > 0 {
                actionDelegate?.onSelect(tx: filteredTxs[indexPath.row])
            } else {
                if yatLookupIsInProgress { return nil }
                actionDelegate?.onSendToYat(yat: filter)
            }
        } else if indexPath.section == 1 {
            actionDelegate?.onSelect(contact: contactList[indexPath.row])
        }
        return nil
    }

    // Parent component needs to know which direction they're scrolling
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 20 {
            isScrolledToTop = true
        } else {
            isScrolledToTop = false
        }
    }

    func isEmptyList() -> Bool {
        return (filteredTxs.count + contactList.count) < 1
    }
}
