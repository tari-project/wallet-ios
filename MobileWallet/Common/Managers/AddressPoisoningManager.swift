//  AddressPoisoningManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 09/01/2024
	Using Swift 5.0
	Running on macOS 14.2

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

final class AddressPoisoningManager {

    struct SimilarAddressData {
        let address: String
        let emojiID: String
        let alias: String?
        let transactionsCount: Int
        let lastTransaction: String?
    }

    // MARK: - Constants

    private let minSameCharacters = 3
    private let usedPrefixSuffixCharacters = 3

    // MARK: - Properties

    static let shared: AddressPoisoningManager = AddressPoisoningManager()
    private let contactsManager = ContactsManager()

    // MARK: - Initialisers

    private init() {}

    // MARK: - Actions

    func similarAddresses(address: TariAddress, includeInputAddress: Bool) async throws -> [SimilarAddressData] {

        try await contactsManager.fetchModels()

        let emojiID = try address.emojis
        var result: [SimilarAddressData] = []

        if includeInputAddress {
            try result.append(inputAddressData(address: address))
        }

        result += try similarContacts(toEmojiID: emojiID)
        return result
    }

    private func similarContacts(toEmojiID emojiID: String) throws -> [SimilarAddressData] {
        try (contactsManager.tariContactModels + contactsManager.externalModels)
            .filter {
                guard let internalModel = $0.internalModel else { return false }
                return emojiID.isSimilar(to: internalModel.emojiID, minSameCharacters: minSameCharacters, usedPrefixSuffixCharacters: usedPrefixSuffixCharacters)
            }
            .compactMap { try data(contact: $0) }
    }

    private func inputAddressData(address: TariAddress) throws -> SimilarAddressData {
        let emojiID = try address.emojis
        guard let existingContact = (contactsManager.tariContactModels + contactsManager.externalModels).first(where: { $0.internalModel?.emojiID == emojiID }) else {
            return try data(hex: address.byteVector.hex, emojiID: emojiID)
        }
        return try data(contact: existingContact) ?? data(hex: address.byteVector.hex, emojiID: emojiID)
    }

    private func data(hex: String, emojiID: String) -> SimilarAddressData {
        SimilarAddressData(address: hex, emojiID: emojiID, alias: nil, transactionsCount: 0, lastTransaction: nil)
    }

    private func data(contact: ContactsManager.Model) throws -> SimilarAddressData? {
        guard let internalModel = contact.internalModel else { return nil }
        let transactions = try transactions(forHex: internalModel.hex)
        let lastTransaction = try formattedLastTransaction(transactions: transactions)
        return SimilarAddressData(address: internalModel.hex, emojiID: internalModel.emojiID, alias: contact.name, transactionsCount: transactions.count, lastTransaction: lastTransaction)
    }

    private func transactions(forHex hex: String) throws -> [Transaction] {
        try Tari.shared.transactions.all
            .filter { try $0.address.byteVector.hex == hex }
            .sorted { try $0.timestamp > $1.timestamp }
    }

    private func formattedLastTransaction(transactions: [Transaction]) throws -> String? {
        guard let timestamp = try transactions.last?.timestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp)).relativeDayFromToday()
    }
}
