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

    static func format(metadata: [ChatMessageMetadata.MetadataType: ByteVector], transactionAmount: MicroTari?, isIncomming: Bool, username: String) throws -> [ChatNotificationModel] {
        let metadataNotificationModels = try metadata.compactMap { try format(type: $0.key, metadata: $0.value, isIncomming: isIncomming, username: username) }
        guard let transactionAmount else { return metadataNotificationModels }
        let transactionNotifcationModels = try format(transactionAmount: transactionAmount, isIncomming: isIncomming, username: username)
        return metadataNotificationModels + [transactionNotifcationModels]
    }

    private static func format(type: ChatMessageMetadata.MetadataType, metadata: ByteVector, isIncomming: Bool, username: String) throws -> ChatNotificationModel? {
        switch type {
        case .tokenRequest:
            let notificationParts = try makeTokenRequestNotificationParts(metadata: metadata, isIncomming: isIncomming, username: username)
            let isValid = try isRequestMetadataValid(metadata: metadata)
            return ChatNotificationModel(notificationParts: notificationParts, isValid: isValid)
        case .replyMessage, .replyTransaction, .gif:
            return nil
        }
    }

    private static func format(transactionAmount: MicroTari, isIncomming: Bool, username: String) throws -> ChatNotificationModel {

        let notificationParts: [StylizableComponent]

        if isIncomming {
            notificationParts = [
                StylizedLabel.StylizedText(text: username, style: .bold),
                StylizedLabel.StylizedText(text: localized("chat.conversation.messages.payment.inbound.part2"), style: .normal),
                StylizedLabel.StylizedImage(image: .Icons.General.tariGem),
                StylizedLabel.StylizedText(text: transactionAmount.formattedPrecise, style: .normal)
            ]
        } else {
            notificationParts = [
                StylizedLabel.StylizedText(text: localized("chat.conversation.messages.payment.outbound.part1"), style: .normal),
                StylizedLabel.StylizedText(text: username, style: .bold),
                StylizedLabel.StylizedImage(image: .Icons.General.tariGem),
                StylizedLabel.StylizedText(text: transactionAmount.formattedPrecise, style: .normal)
            ]
        }

        return ChatNotificationModel(notificationParts: notificationParts, isValid: true)
    }

    // MARK: - Validation

    private static func isRequestMetadataValid(metadata: ByteVector) throws -> Bool {
        try metadata.data.value(type: UInt64.self, byteCount: UInt64.bitWidth / 8) != nil
    }

    // MARK: - Notification Parts

    private static func makeTokenRequestNotificationParts(metadata: ByteVector, isIncomming: Bool, username: String) throws -> [StylizableComponent] {

        guard let rawValue = try metadata.data.value(type: UInt64.self, byteCount: UInt64.bitWidth / 8) else {
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
