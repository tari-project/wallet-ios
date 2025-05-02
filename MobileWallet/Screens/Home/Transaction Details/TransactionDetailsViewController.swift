//  TransactionDetailsViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 14/03/2022
	Using Swift 5.0
	Running on macOS 12.2

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
import Combine
import TariCommon

final class TransactionDetailsViewController: SecureViewController<TransactionDetailsView> {

    // MARK: - Properties

    private let model: TransactionDetailsModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Subviews

    @View private var tableView: UITableView = {
        let view = UITableView()
        view.separatorStyle = .none
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - Initialisers

    init(model: TransactionDetailsModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupTableView()
        setupModelCallbacks()
        hideKeyboardWhenTappedAroundOrSwipedDown()
    }

    // MARK: - Setups

    private func setupViews() {
        view.backgroundColor = .Background.primary
    }

    private func setupConstraints() {
        view.addSubview(tableView)

        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 74),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(type: TransactionDetailsCell.self)
        tableView.register(type: TransactionTotalCell.self)
    }

    private func setupModelCallbacks() {
        model.$title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.title = $0 }
            .store(in: &cancellables)

        model.$isAddContactButtonVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("isAddContactButtonVisible changed, reloading table")
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        model.$isNameSectionVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("isNameSectionVisible changed, reloading table")
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        model.$amount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        model.$fee
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        model.$transactionDirection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        model.$userAlias
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        model.$note
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        model.$isBlockExplorerActionAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        model.$statusText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        model.$isEmojiFormat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        model.$linkToOpen
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { UIApplication.shared.open($0) }
            .store(in: &cancellables)

        model.$errorModel
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)

        model.userAliasUpdateSuccessCallback = {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Actions

    private func addContactAliasRequest() {
        model.handleAddContactRequest()

        guard let address = try? model.getTransactionAddress() else { return }
        let controller = AddContactConstructor.bulidScene(onSuccess: .moveBack, address: address)
        navigationController?.pushViewController(controller, animated: true)
    }

    override func dismissKeyboard() {
        super.dismissKeyboard()
        model.resetAlias()
    }

    private func statusText(for status: TransactionStatus) -> String {
        switch status {
        case .unknown:
            return "Unknown"
        case .txNullError:
            return "Transaction Error"
        case .completed:
            return "Completed"
        case .broadcast:
            return "Broadcast"
        case .minedUnconfirmed:
            return "Mined (Unconfirmed)"
        case .imported:
            return "Imported"
        case .pending:
            return "Pending"
        case .coinbase:
            return "Coinbase"
        case .minedConfirmed:
            return "Mined (Confirmed)"
        case .rejected:
            return "Rejected"
        case .oneSidedUnconfirmed:
            return "One-Sided (Unconfirmed)"
        case .oneSidedConfirmed:
            return "One-Sided (Confirmed)"
        case .queued:
            return "Queued"
        case .coinbaseUnconfirmed:
            return "Coinbase (Unconfirmed)"
        case .coinbaseConfirmed:
            return "Coinbase (Confirmed)"
        case .coinbaseNotInBlockChain:
            return "Coinbase (Not in Blockchain)"
        }
    }

    private func truncateEmojiAddress(_ address: String) -> String {
        guard address.count > 8 else { return address }
        let start = address.prefix(4)
        let end = address.suffix(4)
        return "\(start)...\(end)"
    }
}

// MARK: - UITableViewDataSource

extension TransactionDetailsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Hide Contact Name, Note, Address, and Fee rows for coinbase transactions
        if model.isCoinbase {
            return 5 // Paid, Date, Txn ID, Status, Total
        }
        return 9 // Paid, To/From, Contact Name, Fee, Date, Note, Txn ID, Status, Total
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 8:
            let cell = tableView.dequeueReusableCell(type: TransactionTotalCell.self, indexPath: indexPath)
            cell.totalText = model.total
            return cell
        default:
            let cell = tableView.dequeueReusableCell(type: TransactionDetailsCell.self, indexPath: indexPath)

            // Configure cell based on row index
            let rowIndex: Int
            // Adjust row index for coinbase transactions
            if model.isCoinbase {
                rowIndex = indexPath.row >= 1 ? indexPath.row + 3 : indexPath.row
            } else {
                rowIndex = indexPath.row
            }

            switch rowIndex {
            case 0:
                cell.titleText = model.isInbound ? "Received" : "Paid"
                if let amount = model.amount {
                    cell.valueText = "\(amount) tXTM"
                }
                cell.isAddressCell = false
            case 1:
                cell.titleText = model.transactionDirection
                if let emojiAddress = model.addressComponents?.fullEmoji {
                    if model.isEmojiFormat {
                        cell.valueText = truncateEmojiAddress(emojiAddress)
                    } else if let baseAddress = model.addressComponents?.fullRaw {
                        cell.valueText = baseAddress.shortenedMiddle(to: 20)
                    }
                    cell.isAddressCell = true
                    cell.isEmojiFormat = model.isEmojiFormat
                    cell.onAddressFormatToggle = { [weak self] _ in
                        self?.model.toggleAddressFormat()
                    }
                }
            case 2:
                cell.titleText = "Contact Name"
                cell.valueText = model.userAlias ?? ""
                cell.isAddressCell = false
                cell.showAddContactButton = model.userAlias == nil && !model.isCoinbase
                cell.onAddContactTap = { [weak self] in
                    print("Add contact button tapped")
                    self?.addContactAliasRequest()
                    print("ViewController addContactAliasRequest called")
                }
            case 3:
                cell.titleText = "Fee"
                if let fee = model.fee {
                    cell.valueText = "\(fee) tXTM"
                }
                cell.isAddressCell = false
            case 4:
                cell.titleText = "Date"
                if let timestamp = model.timestamp {
                    let date: Date = Date(timeIntervalSince1970: timestamp)
                    cell.valueText = date.formattedDisplay()
                }
                cell.isAddressCell = false
            case 5:
                cell.titleText = "Note"
                cell.valueText = model.note ?? ""
                cell.isAddressCell = false
            case 6:
                cell.titleText = "Transaction ID"
                cell.valueText = model.identifier
                cell.isAddressCell = false
            case 7:
                cell.titleText = "Status"
                cell.valueText = model.statusText ?? ""
                cell.isAddressCell = false
            default:
                break
            }

            cell.onCopyButtonTap = { [weak self] value in
                UIPasteboard.general.string = value
            }

            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension TransactionDetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 4 && model.isBlockExplorerActionAvailable {
            model.requestLinkToBlockExplorer()
        }
    }
}
