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

    @View private var toastView: UIView = {
        let view = UIView()
        view.backgroundColor = .Background.primary
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.Elevation.outlined.cgColor
        view.alpha = 0
        return view
    }()
    
    @View public var copyDetailsButton: StylisedButton = {
        let button = StylisedButton(withStyle: .outlined, withSize: .large)
        button.setTitle("Copy Raw Details", for: .normal)
        button.setImage(.sendCopy.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()

    @View private var toastLabel: UILabel = {
        let view = UILabel()
        view.textColor = .Text.primary
        view.font = .Poppins.Medium.withSize(14)
        view.text = "Copied to clipboard"
        view.textAlignment = .center
        return view
    }()

    // MARK: - Initialisers

    init(model: TransactionDetailsModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        model.presenter = self
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

        // Set initial theme colors
        toastView.backgroundColor = .Background.primary
        toastView.layer.borderColor = UIColor.Elevation.outlined.cgColor
        toastLabel.textColor = .Text.primary
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Update contact data when view appears
        model.updateContactData()
    }

    // MARK: - Setups

    private func setupViews() {
        view.backgroundColor = .Background.primary
        view.addSubview(tableView)
        view.addSubview(copyDetailsButton)
        view.addSubview(toastView)
        toastView.addSubview(toastLabel)
    }

    private func setupConstraints() {
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 74),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            toastView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toastView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
            
            copyDetailsButton.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 8),
            copyDetailsButton.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
            copyDetailsButton.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16),
            copyDetailsButton.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -8),
            
            toastLabel.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 8),
            toastLabel.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
            toastLabel.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16),
            toastLabel.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -8)
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
                // Find the contact name cell and update only that cell
                if let indexPath = self?.findContactNameCellIndexPath() {
                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
            .store(in: &cancellables)

        model.$isNameSectionVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Only reload if the name section visibility changes
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        model.$amount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Only reload the amount cell
                self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
            .store(in: &cancellables)

        model.$fee
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Only reload the fee cell if it exists
                if let indexPath = self?.findFeeCellIndexPath() {
                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
            .store(in: &cancellables)

        model.$transactionDirection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Only reload the direction cell
                self?.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            }
            .store(in: &cancellables)
        
        model.$paymentReference
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Only reload the direction cell
                self?.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            }
            .store(in: &cancellables)

        model.$note
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Only reload the note cell if it exists
                if let indexPath = self?.findNoteCellIndexPath() {
                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
            .store(in: &cancellables)

        model.$isBlockExplorerActionAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Only reload the transaction ID cell
                self?.tableView.reloadRows(at: [IndexPath(row: 4, section: 0)], with: .none)
            }
            .store(in: &cancellables)

        model.$statusText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Only reload the status cell
                self?.tableView.reloadRows(at: [IndexPath(row: 5, section: 0)], with: .none)
            }
            .store(in: &cancellables)

        model.$isEmojiFormat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Only reload the address cell
                self?.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            }
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
        
        copyDetailsButton.onTap = { [weak self] in
            if let details = try? self?.model.rawDetails {
                UIPasteboard.general.string = details
            }
        }
    }

    private func findContactNameCellIndexPath() -> IndexPath? {
        // Contact name cell is at index 2 in the table
        return IndexPath(row: 2, section: 0)
    }

    private func findFeeCellIndexPath() -> IndexPath? {
        // Fee cell is at index 3 in the table
        return IndexPath(row: 3, section: 0)
    }

    private func findNoteCellIndexPath() -> IndexPath? {
        // Note cell is at index 6 in the table
        return IndexPath(row: 6, section: 0)
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

    private func truncateEmojiAddress(_ address: String) -> String {
        guard address.count > 8 else { return address }
        let start = address.prefix(4)
        let end = address.suffix(4)
        return "\(start)...\(end)"
    }

    private func showToast() {
        // Cancel any existing animations
        toastView.layer.removeAllAnimations()

        // Show toast with animation
        UIView.animate(withDuration: 0.2, animations: {
            self.toastView.alpha = 1
        }) { _ in
            // Hide toast after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                UIView.animate(withDuration: 0.3) {
                    self.toastView.alpha = 0
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension TransactionDetailsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let extraCellCount = model.paymentReference != nil ? 1 : 0
        // Hide Contact Name, Note, Address, and Fee rows for coinbase transactions
        if model.isCoinbase {
            return 4 + extraCellCount // Paid, Date, Txn ID, Status, Total (removed Fee)
        }
        // Add note row only if there's a non-empty note
        let baseRows = 7 + extraCellCount // Paid, To/From, Contact Name, Date, Txn ID, Status, Total (removed Fee)
        return (model.note?.isEmpty == false) ? baseRows : baseRows - 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case model.paymentReference != nil ? 8 : 7:
            let cell = tableView.dequeueReusableCell(type: TransactionTotalCell.self, indexPath: indexPath)
            cell.totalText = model.total
            return cell
        default:
            let cell = tableView.dequeueReusableCell(type: TransactionDetailsCell.self, indexPath: indexPath)

            // Configure cell based on row index
            let rowIndex: Int
            // Adjust row index for coinbase transactions
            if model.isCoinbase {
                rowIndex = indexPath.row >= 1 ? indexPath.row + 2 : indexPath.row // Adjusted for removed fee row
            } else {
                rowIndex = indexPath.row
            }

            switch rowIndex {
            case 0:
                cell.titleText = model.isInbound ? "Received" : "Paid"
                if let amount = model.amount {
                    cell.valueText = "\(amount) " + NetworkManager.shared.currencySymbol
                }
                cell.isAddressCell = false
            case 1:
                cell.titleText = model.transactionDirection
//                if let emojiAddress = model.addressComponents?.fullEmoji {
//                    if model.isEmojiFormat {
//                        cell.valueText = truncateEmojiAddress(emojiAddress)
//                    }
                // TODO: Add emoji/base58 address toggle
                if let baseAddress = model.addressComponents?.fullRaw {
                    cell.valueText = baseAddress.shortenedMiddle(to: 20)
                }
                cell.isAddressCell = true
                cell.isEmojiFormat = model.isEmojiFormat
                cell.onAddressFormatToggle = { [weak self] _ in
                    self?.model.toggleAddressFormat()
                }
            case 2:
                cell.titleText = "Contact Name"
                cell.valueText = model.userAlias ?? " "
                cell.isAddressCell = false
                cell.showAddContactButton = model.userAlias == nil && !model.isCoinbase
                cell.showEditButton = model.userAlias != nil && !model.isCoinbase
                cell.onAddContactTap = { [weak self] in
                    print("Add contact button tapped")
                    self?.addContactAliasRequest()
                    print("ViewController addContactAliasRequest called")
                }
                cell.onEditButtonTap = { [weak self] in
                    self?.model.handleEditContactRequest()
                }
            // case 3: // Fee cell temporarily hidden
            //     cell.titleText = "Fee"
            //     if let fee = model.fee {
            //         cell.valueText = "\(fee) " + NetworkManager.shared.currencySymbol
            //     }
            //     cell.isAddressCell = false
            case 3: // Date
                cell.titleText = "Date"
                if let timestamp = model.timestamp {
                    let date: Date = Date(timeIntervalSince1970: timestamp)
                    cell.valueText = date.formattedDisplay()
                }
                cell.onCopyButtonTap = nil
                cell.showCopyButton = false
            case 4: // Transaction ID
                cell.titleText = "Mined in Block Height"
                cell.valueText = "\(model.minedBlockHeight)"
                cell.isAddressCell = false
                cell.showBlockExplorerButton = 0 < model.minedBlockHeight && model.isBlockExplorerActionAvailable
                cell.onBlockExplorerButtonTap = { [weak self] in
                    self?.model.requestLinkToBlockExplorer()
                }
                cell.showCopyButton = false
            case 5: // Status
                cell.titleText = "Status"
                cell.valueText = model.statusText ?? ""
                cell.isAddressCell = false
                cell.showCopyButton = false
            case 6: // Note
                if let note = model.note, !note.isEmpty {
                    cell.titleText = "Note"
                    cell.valueText = truncated(note, to: 32)
                    cell.isAddressCell = false
                    cell.showAddContactButton = false
                    cell.showEditButton = false
                    cell.showBlockExplorerButton = false
                }
            case 7: // Payment reference
                cell.titleText = "Payment Reference"
                cell.isAddressCell = false
                cell.showAddContactButton = false
                cell.showEditButton = false
                cell.showBlockExplorerButton = false
                
                if let paymentReferenceValue = paymentReferenceValue() {
                    cell.valueText = paymentReferenceValue
                    cell.showCopyButton = model.isPaymentReferenceConfirmed
                } else {
                    cell.showCopyButton = false
                    cell.valueText = ""
                }
            default:
                break
            }

            cell.onCopyButtonTap = { [weak self] value in
                self?.copyAction(value: value, at: rowIndex)
            }
            return cell
        }
    }
}

private extension TransactionDetailsViewController {
    func paymentReferenceValue() -> String? {
        guard let reference = model.paymentReference else { return nil }
        let requiredConfirmations: UInt64 = 5
        let confirmations = model.paymentReferenceConfirmationCount
        if confirmations < requiredConfirmations {
            return "Waiting for \(requiredConfirmations) block confirmations (\(confirmations) of \(requiredConfirmations))"
        } else if let paymentReference = reference.paymentReference {
            return truncated(paymentReference, to: 32)
        }
        return nil
    }
    
    func copyAction(value: String?, at rowIndex: Int) {
        if rowIndex == 1, let addressComponents = model.addressComponents {
            // For address cell, copy the full address based on current format
            let fullAddress = model.isEmojiFormat == true ? addressComponents.fullEmoji : addressComponents.fullRaw
            UIPasteboard.general.string = fullAddress
        } else if rowIndex == 5, let paymentReference = model.paymentReference?.paymentReference {
            UIPasteboard.general.string = paymentReference
        } else {
            // For other cells, copy the displayed value
            UIPasteboard.general.string = value
        }
        showToast()
    }
    
    func truncated(_ value: String, to length: Int) -> String {
        if length < value.lengthOfBytes(using: .utf8) {
            value.prefix(length / 2) + "..." + value.suffix(length / 2)
        } else {
            value
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
