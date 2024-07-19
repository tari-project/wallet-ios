//  TxTableViewModel.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 03.08.2020
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

import GiphyUISDK

class TxTableViewModel: NSObject {

    struct Value {
        let microTari: MicroTari?
        let isOutboundTransaction: Bool
        let isCancelled: Bool
        let isPending: Bool
    }

    let id: UInt64
    private(set) var transaction: Transaction
    private(set) var title = NSAttributedString()
    private(set) var message: String
    private(set) var value: Value

    private let gifID: String?

    var hasGif: Bool { gifID != nil }

    var shouldUpdateCellSize: Bool = false

    @objc dynamic private(set) var gifDownloadFailed: Bool = true
    @objc dynamic private(set) var gif: GPHMedia?
    @objc dynamic private(set) var status: String = ""
    @objc dynamic private(set) var time: String

    private let contact: ContactsManager.Model?

    init(transaction: Transaction, contact: ContactsManager.Model?) throws {
        self.transaction = transaction
        self.contact = contact
        self.id = try transaction.identifier

        value = Value(microTari: MicroTari(try transaction.amount), isOutboundTransaction: try transaction.isOutboundTransaction, isCancelled: transaction.isCancelled, isPending: transaction.isPending)

        if try transaction.isOneSidedPayment {
            message = localized("transaction.one_sided_payment.note.normal")
            gifID = nil
        } else {
            let (msg, giphyId) = TxTableViewModel.extractNote(from: try transaction.message)
            message = msg
            gifID = giphyId
        }

        time = try transaction.formattedTimestamp

        super.init()

        try updateTitleAndAvatar()
        try updateStatus()
        updateMedia()

        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] (_) in
            self?.time = (try? transaction.formattedTimestamp) ?? ""
        }
    }

    private static func extractNote(from message: String) -> (message: String, gifID: String?) {
        // Extract the giphy link
        let giphyLinkPrefix = "https://giphy.com/embed/"
        if let endIndex = message.range(of: giphyLinkPrefix)?.lowerBound {
            let messageExcludingLink = message[..<endIndex].trimmingCharacters(in: .whitespaces)
            let link = message[endIndex...].trimmingCharacters(in: .whitespaces)
            let giphyId = link.replacingOccurrences(of: giphyLinkPrefix, with: "")
            return (messageExcludingLink, giphyId)
        } else {
            return (message, nil)
        }
    }

    func update(transaction: Transaction) throws {

        guard try id == transaction.identifier else { return }
        self.transaction = transaction

        value = Value(microTari: MicroTari(try transaction.amount), isOutboundTransaction: try transaction.isOutboundTransaction, isCancelled: transaction.isCancelled, isPending: transaction.isPending)

        try updateTitleAndAvatar()
        try updateStatus()
        updateMedia()
    }

    private func updateTitleAndAvatar() throws {

        guard try !transaction.isOneSidedPayment else {
            let alias = localized("transaction.one_sided_payment.inbound_user_placeholder")
            title = attributed(title: localized("tx_list.inbound_pending_title", arguments: alias), withAlias: alias)
            return
        }

        var titleText = ""
        let alias = contact?.name ?? ""

        if try transaction.isOutboundTransaction {
            titleText = localized("tx_list.outbound_title", arguments: alias)
        } else {
            titleText = try transaction.status == .pending ? localized("tx_list.inbound_pending_title", arguments: alias) : localized("tx_list.inbound_title", arguments: alias)
        }

        title = attributed(title: titleText, withAlias: alias)
    }

    private func attributed(title: String, withAlias alias: String) -> NSAttributedString {

        let title = title
            .replacingOccurrences(of: alias, with: " \(alias) ")
            .trimmingCharacters(in: .whitespaces)

        guard let startIndex = title.indexDistance(of: alias) else {
            return NSAttributedString()
        }

        let attributedTitle = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: Theme.shared.fonts.txCellUsernameLabel
            ]
        )

        let range = NSRange(location: startIndex, length: alias.count)
        attributedTitle.addAttribute(.font, value: Theme.shared.fonts.txCellUsernameLabelHeavy, range: range)

        return attributedTitle
    }

    private func updateStatus() throws {
        var statusMessage = ""

        switch try transaction.status {
        case .pending:
            statusMessage = try transaction.isOutboundTransaction ? localized("refresh_view.waiting_for_recipient") : localized("refresh_view.waiting_for_sender")
        case .broadcast, .completed:
            guard let requiredConfirmationCount = try? Tari.shared.transactions.requiredConfirmationsCount else {
                statusMessage = localized("refresh_view.final_processing")
                break
            }
            statusMessage = localized("refresh_view.final_processing_with_param", arguments: 1, requiredConfirmationCount + 1)
        case .minedUnconfirmed:
            guard let confirmationCount = try? (transaction as? CompletedTransaction)?.confirmationCount, let requiredConfirmationCount = try? Tari.shared.transactions.requiredConfirmationsCount else {
                statusMessage = localized("refresh_view.final_processing")
                break
            }
            statusMessage = localized("refresh_view.final_processing_with_param", arguments: confirmationCount + 1, requiredConfirmationCount + 1)
        default:
            break
        }

        if transaction.isCancelled {
            statusMessage = localized("tx_detail.payment_cancelled")
        }

        status = statusMessage
    }

    private func updateMedia() {
        if gifID != nil, gif == nil, let media = TxGifManager.shared.getGifFromCache(gifID: gifID!) {
            gif = media
            gifDownloadFailed = false
        }
    }

    func downloadGif() {
        if gifID == nil || gif != nil { return }
        gifDownloadFailed = false
        TxGifManager.shared.downloadGif(gifID: gifID!) { [weak self] (result) in
            switch result {
            case .success(let media):
                self?.gif = media
            case .failure:
                self?.gifDownloadFailed = true
            }
        }
    }

    func cancelDowloadGif() {
        if gifID == nil || gif != nil { return }
        TxGifManager.shared.cancelDownloadGif(gifID: gifID!)
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TxTableViewModel else { return false }
        return object.id == id
    }
}
