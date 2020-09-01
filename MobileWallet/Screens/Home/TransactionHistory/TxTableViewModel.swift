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

import Foundation
import GiphyUISDK
import GiphyCoreSDK

class TxTableViewModel: NSObject {
    typealias Value = (microTari: MicroTari?, direction: TxDirection, isCancelled: Bool, isPending: Bool)
    private static var cachedMedia = [String: GPHMedia]()

    let id: String = UUID().uuidString
    private(set) var title: NSAttributedString
    private(set) var avatar: String
    private(set) var message: String
    private(set) var value: Value

    private let gifID: String?

    var hasGif: Bool {
        get {
            return gifID != nil
        }
    }

    var shouldUpdateCellSize: Bool = false

    @objc dynamic private(set) var gifDownloadFailed: Bool = false
    @objc dynamic private(set) var gif: GPHMedia?
    @objc dynamic private(set) var status: String
    @objc dynamic private(set) var time: String

    required init(tx: TxProtocol) {
        var isCancelled = false
        var isPending = false

        let (publicKey, _) = tx.direction == .inbound ? tx.sourcePublicKey : tx.destinationPublicKey
        guard let pubKey = publicKey else { fatalError() }

        if let _ = tx as? PendingInboundTx {
            isPending = true
        }

        if let _ = tx as? PendingOutboundTx {
            isPending = true
        }

        let (emojis, _) = pubKey.emojis
        avatar = String(emojis.emojis.prefix(1))

        var alias = ""
        var aliasIsEmojis = false
        if let contact = tx.contact.0 {
            alias = contact.alias.0
        }

        if alias.isEmpty {
            let (emojis, _) = pubKey.emojis
            alias = "\(String(emojis.emojis.prefix(2)))•••\(String(emojis.emojis.suffix(2)))"
            aliasIsEmojis = true
        }

        var titleText = ""
        if tx.direction == .inbound {
            if isPending {
                titleText = String(
                    format: NSLocalizedString("tx_list.inbound_pending_title", comment: "Transaction list"),
                    alias
                )
            } else {
                titleText =  String(
                    format: NSLocalizedString("tx_list.inbound_title", comment: "Transaction list"),
                    alias
                )
            }
        } else if tx.direction == .outbound {
            titleText =  String(
                format: NSLocalizedString("tx_list.outbound_title", comment: "Transaction list"),
                alias
            )
        }

        //Getting the line breaks around the alias an not the other spaces in the copy
        titleText = titleText
            .replacingOccurrences(of: " ", with: "\u{00A0}")
            .replacingOccurrences(of: alias, with: " \(alias) ")
            .trimmingCharacters(in: .whitespaces)

        if let startIndex = titleText.indexDistance(of: alias) {
            let attributedTitle = NSMutableAttributedString(
                string: titleText,
                attributes: [
                    .font: Theme.shared.fonts.txCellUsernameLabel,
                    .foregroundColor: Theme.shared.colors.txCellAlias!
                ]
            )

            let range = NSRange(location: startIndex, length: alias.count)
            attributedTitle.addAttribute(.font, value: Theme.shared.fonts.txCellUsernameLabelHeavy, range: range)
            if aliasIsEmojis {
                //So the elippises between the emojis is lighter
                attributedTitle.addAttribute(.foregroundColor, value: Theme.shared.colors.emojisSeparator!, range: range)
            }

            title = attributedTitle
        } else {
            title = NSAttributedString()
        }

        var statusMessage = ""

        switch tx.status.0 {
        case .pending:
            if tx.direction == .inbound {
                statusMessage = NSLocalizedString("refresh_view.waiting_for_sender", comment: "Refresh view")
            } else if tx.direction == .outbound {
                statusMessage = NSLocalizedString("refresh_view.waiting_for_recipient", comment: "Refresh view")
            }
        case .broadcast, .completed:
            statusMessage = NSLocalizedString("refresh_view.final_processing", comment: "Refresh view")
        default:
            statusMessage = ""
        }

        //Cancelled tranaction
        if let compledTx = tx as? CompletedTx {
            if compledTx.isCancelled {
                isCancelled = true
                statusMessage = NSLocalizedString("transaction_detail.payment_cancelled", comment: "Transaction detail view")
            }
        }

        if statusMessage.isEmpty {
            status = ""
        } else {
            status = statusMessage
        }

        value = (microTari: tx.microTari.0, direction: tx.direction, isCancelled: isCancelled, isPending: isPending)
        let (msg, giphyDd) = TxTableViewModel.extractNote(from: tx.message.0)
        message = msg
        time = tx.date.0?.relativeDayFromToday() ?? ""
        gifID = giphyDd

        super.init()

        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] (_) in
            self?.time = tx.date.0?.relativeDayFromToday() ?? ""
        }

        if gifID != nil {
            if let media = TxTableViewModel.cachedMedia[gifID!] {
                self.gif = media
            } else {
                downloadGif(gifID: gifID!)
            }
        }
    }

    private static func extractNote(from message: String) -> (message: String, gifID: String?) {
        //Extract the giphy link
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

    private func downloadGif(gifID: String) {
        gifDownloadFailed = false
        let downloadOperation = GiphyCore.shared.gifByID(gifID) { (response, error) in
            guard error == nil else {
                return TariLogger.error("Failed to load gif", error: error)
            }
            let media = response?.data
            TxTableViewModel.cachedMedia[gifID] = media
            self.shouldUpdateCellSize = true
            self.gif = media
        }

        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { (timer) in
            timer.invalidate()
            if self.gif != nil { return }
            downloadOperation.cancel()
            self.gifDownloadFailed = true
        }
    }

    func retryDownloadGif() {
        if gifID != nil {
            downloadGif(gifID: gifID!)
        }
    }
}
