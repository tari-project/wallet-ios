//  ChatMessageMetadataFormatter.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 25/04/2024
	Using Swift 5.0
	Running on macOS 14.4

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

struct ChatNotificationModel {
    let notificationParts: [StylizableComponent]
    let isValid: Bool
}

enum ChatMessageMetadataFormatter {

    // MARK: - Actions

    static func format(metadataList: [ChatMessageMetadata], isIncomming: Bool, username: String) throws -> [ChatNotificationModel] {
        try metadataList.compactMap { try format(metadata: $0, isIncomming: isIncomming, username: username) }
    }

    static func format(transaction: Transaction, isIncomming: Bool, username: String) throws -> ChatNotificationModel {

        let amount = try MicroTari(transaction.amount).formattedPrecise
        let notificationParts: [StylizableComponent]

        if isIncomming {
            notificationParts = [
                StylizedLabel.StylizedText(text: username, style: .bold),
                StylizedLabel.StylizedText(text: localized("chat.conversation.messages.payment.inbound.part2"), style: .normal),
                StylizedLabel.StylizedImage(image: .Icons.General.tariGem),
                StylizedLabel.StylizedText(text: amount, style: .normal)
            ]
        } else {
            notificationParts = [
                StylizedLabel.StylizedText(text: localized("chat.conversation.messages.payment.outbound.part1"), style: .normal),
                StylizedLabel.StylizedText(text: username, style: .bold),
                StylizedLabel.StylizedImage(image: .Icons.General.tariGem),
                StylizedLabel.StylizedText(text: amount, style: .normal)
            ]
        }

        return ChatNotificationModel(notificationParts: notificationParts, isValid: true)
    }

    private static func format(metadata: ChatMessageMetadata, isIncomming: Bool, username: String) throws -> ChatNotificationModel? {
        guard let type = try metadata.type, let notificationParts = try makeNotificationParts(metadata: metadata, type: type, isIncomming: isIncomming, username: username) else { return nil }
        let isValid = try isValid(metadata: metadata, type: type)
        return ChatNotificationModel(notificationParts: notificationParts, isValid: isValid)
    }

    // MARK: - Validation

    private static func isValid(metadata: ChatMessageMetadata, type: ChatMessageMetadata.MetadataType) throws -> Bool {
        switch type {
        case .reply, .gif:
            return true
        case .tokenRequest:
            return try metadata.data.data.value(type: UInt64.self, byteCount: UInt64.bitWidth / 8) != nil
        }
    }

    // MARK: - Notification Parts

    private static func makeNotificationParts(metadata: ChatMessageMetadata, type: ChatMessageMetadata.MetadataType, isIncomming: Bool, username: String) throws -> [StylizableComponent]? {
        switch type {
        case .reply, .gif:
            return nil
        case .tokenRequest:
            return try makeTokenRequestNotificationParts(metadata: metadata, isIncomming: isIncomming, username: username)
        }
    }

    private static func makeTokenRequestNotificationParts(metadata: ChatMessageMetadata, isIncomming: Bool, username: String) throws -> [StylizableComponent] {

        guard let rawValue = try metadata.data.data.value(type: UInt64.self, byteCount: UInt64.bitWidth / 8) else {
            return [StylizedLabel.StylizedText(text: localized("chat.conversation.messages.error.invalid_metadata"), style: .normal)]
        }

        let formattedValue = MicroTari(rawValue).formattedPrecise

        if isIncomming {
            return [
                StylizedLabel.StylizedText(text: username, style: .bold),
                StylizedLabel.StylizedText(text: localized("chat.conversation.messages.request.incomming.part2"), style: .normal),
                StylizedLabel.StylizedImage(image: .Icons.General.tariGem),
                StylizedLabel.StylizedText(text: formattedValue, style: .normal)
            ]
        } else {
            return [
                StylizedLabel.StylizedText(text: localized("chat.conversation.messages.you_placeholder"), style: .bold),
                StylizedLabel.StylizedText(text: localized("chat.conversation.messages.request.outgoing.part2"), style: .normal),
                StylizedLabel.StylizedImage(image: .Icons.General.tariGem),
                StylizedLabel.StylizedText(text: formattedValue, style: .normal)
            ]
        }
    }
}
