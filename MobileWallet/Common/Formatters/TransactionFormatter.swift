//  TransactionFormatter.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 09/07/2023
	Using Swift 5.0
	Running on macOS 13.4

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

final class TransactionFormatter {

    struct Model: Identifiable {
        var id: UInt64
        let titleComponents: [StylizedLabel.StylizedText]
        let timestamp: TimeInterval
        let amountModel: AmountBadge.ViewModel
        let status: String?
        let note: String?
        let giphyID: String?
    }

    // MARK: - Properties

    private var contactsManager = ContactsManager()

    // MARK: - Actions

    func updateContactsData() async throws {
        try await contactsManager.fetchModels()
    }

    func model(transaction: Transaction, filter: String = "") throws -> Model? {

        let contactName = try contactName(transaction: transaction)

        if !filter.isEmpty {
            guard try transaction.address.components.fullEmoji.range(of: filter) != nil || transaction.address.components.fullRaw.range(of: filter) != nil || contactName.range(of: filter) != nil else { return nil }
        }

        let messageComponents = try messageComponents(transaction: transaction)

        return try Model(
            id: transaction.identifier,
            titleComponents: transactionTitleComponents(transaction: transaction, name: contactName),
            timestamp: TimeInterval(transaction.timestamp),
            amountModel: amountViewModel(transaction: transaction),
            status: status(transaction: transaction),
            note: messageComponents.note,
            giphyID: messageComponents.giphyID
        )
    }

    func contact(uniqueIdentifier: String) -> ContactsManager.Model? {
        contactsManager.tariContactModels.first { $0.internalModel?.addressComponents.uniqueIdentifier == uniqueIdentifier }
    }

    private func contactName(transaction: Transaction) throws -> String {
        guard try !transaction.isCoinbase else { return localized("transaction.coinbase.user_placeholder") }
        let contact = try contact(transaction: transaction)
        return contact?.name ?? localized("transaction.one_sided_payment.inbound_user_placeholder")
    }

    private func transactionTitleComponents(transaction: Transaction, name: String) throws -> [StylizedLabel.StylizedText] {

        if try transaction.isOutboundTransaction {
            return [
                StylizedLabel.StylizedText(text: localized("transaction.normal.title.outbound.part.1"), style: .normal),
                StylizedLabel.StylizedText(text: name, style: .bold)
            ]
        } else {

            let name = try transaction.isOneSidedPayment ? localized("transaction.one_sided_payment.inbound_user_placeholder") : name
            let text = transaction.isPending ? localized("transaction.normal.title.pending.part.2") : localized("transaction.normal.title.inbound.part.2")

            return [
                StylizedLabel.StylizedText(text: name, style: .bold),
                StylizedLabel.StylizedText(text: text, style: .normal)
            ]
        }
    }

    private func amountViewModel(transaction: Transaction) throws -> AmountBadge.ViewModel {

        let tariAmount = try MicroTari(transaction.amount)
        let amount = try transaction.isOutboundTransaction ? tariAmount.formattedWithNegativeOperator : tariAmount.formattedWithOperator

        let valueType: AmountBadge.ValueType

        if transaction.isCancelled {
            valueType = .invalidated
        } else if transaction.isPending {
            valueType = .waiting
        } else if try transaction.isOutboundTransaction {
            valueType = .negative
        } else {
            valueType = .positive
        }

        return AmountBadge.ViewModel(amount: amount, valueType: valueType)
    }

    private func status(transaction: Transaction) throws -> String? {

        guard !transaction.isCancelled else {
            return localized("tx_detail.payment_cancelled")
        }

        switch try transaction.status {
        case .pending:
            return try transaction.isOutboundTransaction ? localized("refresh_view.waiting_for_recipient") : localized("refresh_view.waiting_for_sender")
        case .broadcast, .completed:
            guard let requiredConfirmationCount = try? Tari.shared.transactions.requiredConfirmationsCount else {
                return localized("refresh_view.final_processing")
            }
            return localized("refresh_view.final_processing_with_param", arguments: 1, requiredConfirmationCount + 1)
        case .minedUnconfirmed:
            guard let confirmationCount = try? (transaction as? CompletedTransaction)?.confirmationCount, let requiredConfirmationCount = try? Tari.shared.transactions.requiredConfirmationsCount else {
                return localized("refresh_view.final_processing")
            }
            return localized("refresh_view.final_processing_with_param", arguments: confirmationCount + 1, requiredConfirmationCount + 1)
        case .imported, .coinbase, .minedConfirmed, .rejected, .oneSidedUnconfirmed, .oneSidedConfirmed, .queued, .coinbaseUnconfirmed, .coinbaseConfirmed, .coinbaseNotInBlockChain, .txNullError, .unknown:
            return nil
        }
    }

    private func messageComponents(transaction: Transaction) throws -> (note: String, giphyID: String?) {

        guard try !transaction.isOneSidedPayment else {
            return (localized("transaction.one_sided_payment.note.normal"), nil)
        }

        let giphyURL = "https://giphy.com/embed/"
        let message = try transaction.message

        guard let urlEndIndex = message.range(of: giphyURL)?.lowerBound else {
            return (message, nil)
        }

        let note = message[..<urlEndIndex].trimmingCharacters(in: .whitespaces)
        let url = message[urlEndIndex...].trimmingCharacters(in: .whitespaces)
        let giphyID = url.replacingOccurrences(of: giphyURL, with: "")

        return (note, giphyID)
    }

    // MARK: - Helpers

    private func contact(transaction: Transaction) throws -> ContactsManager.Model? {
        contact(uniqueIdentifier: try transaction.address.components.uniqueIdentifier)
    }
}
