//  AddRecipientModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 06/10/2021
	Using Swift 5.0
	Running on macOS 12.0

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

import Combine
import YatLib
import UIKit

struct PaymentInfo {
    let address: TariAddress
    let yatID: String?
}

struct ContactsSectionItem {
    let title: String
    let items: [ContactElementItem]
}

struct ContactElementItem: Identifiable, Hashable {
    
    let id: UUID
    
    let title: String
    let initial: String
    let isEmojiID: Bool
}

private struct AddressMetadata {
    let uuid: UUID
    let address: TariAddress
}

final class AddRecipientModel {

    // MARK: - Constants

    private let maxYatIDLenght: Int = 5

    // MARK: - View Model

    @Published private(set) var canMoveToNextStep: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var errorDialog: MessageModel?
    @Published private(set) var verifiedPaymentInfo: PaymentInfo?
    @Published private(set) var contactsSectionItems: [ContactsSectionItem] = []
    @Published private(set) var validatedPasteboardText: String?
    @Published private(set) var yatID: String?
    @Published private(set) var walletAddressPreview: String?
    let searchText = CurrentValueSubject<String, Never>("")
    
    // MARK: - Properties
    
    @Published private var address: TariAddress?
    private var contacts: [UUID: Contact] = [:]
    private var recentPublicKeys: [AddressMetadata] = []
    private var allRecentContactsItems: [ContactElementItem] = []
    private var allContactsItems: [ContactElementItem] = []
    private var cancelables = Set<AnyCancellable>()

    // MARK: - Initializers

    init() {
        setupFeedbacks()
        fetchWalletContacts()
    }
    
    // MARK: - Setups
    
    private func setupFeedbacks() {
        
        searchText
            .sink { [weak self] in self?.searchForContact(searchText: $0) }
            .store(in: &cancelables)
        
        searchText
            .throttle(for: .milliseconds(750), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in self?.searchAddress(forYatID: $0) }
            .store(in: &cancelables)
        
        $address
            .map { $0 != nil }
            .assign(to: \.canMoveToNextStep, on: self)
            .store(in: &cancelables)
    }
    
    // MARK: - Actions - View Model
    
    func confirmSelection() {
        
        guard let address else {
            errorMessage = contactsSectionItems.isEmpty ? localized("add_recipient.inputbox.warning") : nil
            return
        }
        
        errorMessage = nil
        verifiedPaymentInfo = PaymentInfo(address: address, yatID: yatID)
    }
    
    func onSelectItem(atIndexPath indexPath: IndexPath) {
        
        let address: TariAddress?
        let model = contactsSectionItems[indexPath.section].items[indexPath.row]
        
        switch indexPath.section {
        case 0:
            address = recentPublicKeys.first { $0.uuid == model.id }?.address
        case 1:
            address = try? contacts[model.id]?.address
        default:
            return
        }
        
        guard let address else {
            verifiedPaymentInfo = nil
            return
        }
        
        verifiedPaymentInfo = PaymentInfo(address: address, yatID: yatID)
    }
    
    func toogleYatPreview() {
        let isAddressVisible = walletAddressPreview != nil
        walletAddressPreview = isAddressVisible ? nil : try? address?.byteVector.hex
    }

    // MARK: - Actions - Contacts
    
    private func fetchWalletContacts() {
        
        let sortedContacts: [Contact]
        
        do {
            sortedContacts = try Tari.shared.contacts.allContacts.sorted { try $0.alias.lowercased() < $1.alias.lowercased() }
        } catch {
            presentFetchContactsError()
            return
        }
        
        
        contacts = sortedContacts.reduce(into: [UUID: Contact]()) { $0[UUID()] = $1 }
        
        do {
            recentPublicKeys = try fetchRecentPublicKeys().map { AddressMetadata(uuid: UUID(), address: $0) }
            allRecentContactsItems = try recentPublicKeys.map { try Tari.shared.contacts.findContact(hex: $0.address.byteVector.hex)?.viewItem(uuid: $0.uuid) ?? $0.address.viewItem(uuid: $0.uuid) }
            allContactsItems = try contacts.map { try $1.viewItem(uuid: $0) }
        } catch {
            presentFetchContactsError()
        }
        
        filterContacts(searchText: "")
    }
    
    private func fetchRecentPublicKeys() throws -> [TariAddress] {
        
        let transactions: [Transaction] = Tari.shared.transactions.completed + Tari.shared.transactions.pendingInbound + Tari.shared.transactions.pendingOutbound
        
        let recentTransactions = try transactions
            .sorted { try $0.timestamp > $1.timestamp }
            .map { try $0.address }
            .reduce(into: [TariAddress]()) { result, address in
                guard !result.contains(address) else { return }
                result.append(address)
            }
            .prefix(3)
        
        return Array(recentTransactions)
    }

    private func searchForContact(searchText: String) {
        generateAddress(text: searchText)
        filterContacts(searchText: searchText)
    }
    
    private func filterContacts(searchText: String) {
        
        var recentContactsItems: [ContactElementItem] = []
        var contactsItems: [ContactElementItem] = []
        var contactsSectionItems: [ContactsSectionItem] = []
        
        if searchText.isEmpty {
            recentContactsItems = allRecentContactsItems
            contactsItems = allContactsItems
        } else {
            let walletContacts = try? Tari.shared.contacts.allContacts
            
            recentContactsItems = recentPublicKeys
                .filter { addressMetadata in
                    (try? addressMetadata.address.emojis.localizedStandardContains(searchText)) == true
                    || (try? walletContacts?.filter { (try? $0.address) == addressMetadata.address }.first?.alias.localizedStandardContains(searchText)) == true
                }
                .map(\.uuid)
                .compactMap { uuid in allRecentContactsItems.first { $0.id == uuid }}
            
            contactsItems = contacts
                .filter {
                    guard let alias = try? $0.value.alias else { return false }
                    return alias.localizedCaseInsensitiveContains(searchText)
                }
                .map(\.key)
                .compactMap { uuid in allContactsItems.first { $0.id == uuid }}
        }
        
        if !recentContactsItems.isEmpty {
            contactsSectionItems.append(ContactsSectionItem(title: localized("add_recipient.recent_txs"), items: recentContactsItems))
        }
        
        if !contactsItems.isEmpty {
            contactsSectionItems.append(ContactsSectionItem(title: localized("add_recipient.my_contacts"), items: contactsItems))
        }
        
        self.contactsSectionItems = contactsSectionItems
    }
    
    private func presentFetchContactsError() {
        errorDialog = MessageModel(title: localized("add_recipient.error.load_contacts.title"), message: localized("add_recipient.error.load_contacts.description"), type: .error)
    }
    
    // MARK: - Actions - Yat

    private func searchAddress(forYatID yatID: String) {
        
        self.yatID = nil
        guard yatID.containsOnlyEmoji, (1...maxYatIDLenght).contains(yatID.count) else { return }

        Yat.api.emojiID.lookupEmojiIDPaymentPublisher(emojiId: yatID, tags: YatRecordTag.XTRAddress.rawValue)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] in self?.handle(apiResponse: $0, yatID: yatID) }
            )
            .store(in: &cancelables)
    }
    
    private func handle(apiResponse: PaymentAddressResponse, yatID: String) {
        guard let walletAddress = apiResponse.result?[YatRecordTag.XTRAddress.rawValue]?.address else { return }
        generateAddress(text: walletAddress)
        self.yatID = yatID
    }
    
    // MARK: - Actions - Public Key
    
    private func generateAddress(text: String) {
        guard let address = try? makeAddress(text: text), verify(address: address) else {
            address = nil
            return
        }
        self.address = address
    }
    
    private func makeAddress(text: String) throws -> TariAddress {
        do { return try TariAddress(emojiID: text) } catch {}
        return try TariAddress(hex: text)
    }
    
    private func verify(address: TariAddress) -> Bool {
        guard let hex = try? address.byteVector.hex, let userHex = try? Tari.shared.walletAddress.byteVector.hex, hex != userHex else {
            errorMessage = localized("add_recipient.warning.can_not_send_yourself.with_param", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol)
            return false
        }
        return true
    }
    
    // MARK: - Actions - Pasteboard
    
    func checkPasteboard() {
        guard let pasteboardText = UIPasteboard.general.string, let emojis = try? makeAddress(text: pasteboardText).emojis else { return }
        validatedPasteboardText = emojis
    }
}

private extension Contact {
    
    func viewItem(uuid: UUID) throws -> ContactElementItem {
        let alias = try alias
        let isEmojiID = alias.isEmpty
        let title = isEmojiID ? try address.emojis.obfuscatedText : alias
        let initial = isEmojiID ? "" : title.prefix(1)
        return ContactElementItem(id: uuid, title: title, initial: String(initial), isEmojiID: isEmojiID)
    }
}

private extension TariAddress {
    
    func viewItem(uuid: UUID) -> ContactElementItem {
        let title = (try? emojis.obfuscatedText) ?? ""
        return ContactElementItem(id: uuid, title: title, initial: "", isEmojiID: true)
    }
}

private extension String {
    var obfuscatedText: String {
        guard count >= 9 else { return self }
        return "\(prefix(3))•••\(suffix(3))"
    }
}
