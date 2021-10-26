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
    let publicKey: PublicKey
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

final class AddRecipientModel {

    // MARK: - Constants

    private let maxYatIDLenght: Int = 5

    // MARK: - View Model

    @Published private(set) var canMoveToNextStep: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var errorDialog: SimpleErrorModel?
    @Published private(set) var verifiedPaymentInfo: PaymentInfo?
    @Published private(set) var contactsSectionItems: [ContactsSectionItem] = []
    @Published private(set) var validatedPasteboardText: String?
    @Published private(set) var yatID: String?
    @Published private(set) var walletAddressPreview: String?
    let searchText = CurrentValueSubject<String, Never>("")
    
    // MARK: - Properties
    
    private var publicKey: PublicKey?
    private var contacts: [UUID: Contact] = [:]
    private var recentPublicKeys: [UUID: PublicKey] = [:]
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
            .throttle(for: .milliseconds(750), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] in self?.searchAddress(forYatID: $0) }
            .store(in: &cancelables)
    }
    
    // MARK: - Actions - View Model
    
    func confirmSelection() {
        
        guard let publicKey = publicKey else {
            errorMessage = contactsSectionItems.isEmpty ? localized("add_recipient.inputbox.warning") : nil
            return
        }
        
        errorMessage = nil
        verifiedPaymentInfo = PaymentInfo(publicKey: publicKey, yatID: yatID)
    }
    
    func onSelectItem(atIndexPath indexPath: IndexPath) {
        
        let publicKey: PublicKey?
        
        let model = contactsSectionItems[indexPath.section].items[indexPath.row]
        
        switch indexPath.section {
        case 0:
            publicKey = recentPublicKeys[model.id]
        case 1:
            publicKey = contacts[model.id]?.publicKey.0
        default:
            return
        }
        
        guard let publicKey = publicKey else {
            verifiedPaymentInfo = nil
            return
        }
        
        verifiedPaymentInfo = PaymentInfo(publicKey: publicKey, yatID: yatID)
    }
    
    func toogleYatPreview() {
        let isAddressVisible = walletAddressPreview != nil
        walletAddressPreview = isAddressVisible ? nil : publicKey?.hex.0
    }

    // MARK: - Actions - Contacts
    
    private func fetchWalletContacts() {
        TariLib.shared.walletStatePublisher
            .sink { [weak self] in self?.handle(walletState: $0) }
            .store(in: &cancelables)
    }
    
    private func handle(walletState: TariLib.WalletState) {
        switch walletState {
        case .started:
            do {
                try loadContacts()
            } catch {
                errorDialog = SimpleErrorModel(title: localized("add_recipient.error.load_contacts.title"), description: localized("add_recipient.error.load_contacts.description"), error: error)
            }
        case .startFailed:
            errorDialog = SimpleErrorModel(title: localized("add_recipient.error.load_contacts.title"), description: localized("add_recipient.error.load_contacts.description"))
        case .notReady, .starting:
            break
        }
    }
    
    private func loadContacts() throws {
        
        guard let wallet = TariLib.shared.tariWallet else {
            throw WalletErrors.walletNotInitialized
        }
        
        let (walletContacts, contactsError) = wallet.contacts
        
        if let contactsError = contactsError {
            throw contactsError
        }
        
        guard let walletContacts = walletContacts else {
            throw WalletErrors.walletNotInitialized
        }
        
        let (contactList, listError) = walletContacts.list
        
        if let listError = listError {
            throw listError
        }
        
        let sortedContacts = contactList.sorted { $0.alias.0.lowercased() < $1.alias.0.lowercased() }
        let publicKeys = try wallet.recentPublicKeys(limit: 3)
        
        recentPublicKeys = publicKeys.reduce(into: [UUID: PublicKey]()) { $0[UUID()] = $1 }
        contacts = sortedContacts.reduce(into: [UUID: Contact]()) { $0[UUID()] = $1 }
        
        allRecentContactsItems = recentPublicKeys.map { (try? TariLib.shared.tariWallet?.contacts.0?.find(publicKey: $1).viewItem(uuid: $0)) ?? $1.viewItem(uuid: $0) }
        allContactsItems = contacts.map { $1.viewItem(uuid: $0) }
        
        filterContacts(searchText: "")
    }

    private func searchForContact(searchText: String) {
        generatePublicKey(text: searchText)
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
            let contactList = TariLib.shared.tariWallet?.contacts.0?.list.0
            recentContactsItems = recentPublicKeys
                .filter {
                    dataPair in dataPair.value.emojis.0.localizedCaseInsensitiveContains(searchText) ||
                    ((contactList?.filter { $0.publicKey.0 == dataPair.value }.first?.alias.0.localizedCaseInsensitiveContains(searchText)) == true) }
                .map(\.key)
                .compactMap { uuid in allRecentContactsItems.first { $0.id == uuid } }
            
            contactsItems = contacts
                .filter { $0.value.alias.0.localizedCaseInsensitiveContains(searchText) }
                .map(\.key)
                .compactMap { uuid in allContactsItems.first { $0.id == uuid } }
        }
        
        if !recentContactsItems.isEmpty {
            contactsSectionItems.append(ContactsSectionItem(title: localized("add_recipient.recent_txs"), items: recentContactsItems))
        }
        
        if !contactsItems.isEmpty {
            contactsSectionItems.append(ContactsSectionItem(title: localized("add_recipient.my_contacts"), items: contactsItems))
        }
        
        self.contactsSectionItems = contactsSectionItems
    }
    
    // MARK: - Actions - Yat

    private func searchAddress(forYatID yatID: String) {
        
        self.yatID = nil
        guard yatID.containsOnlyEmoji, (1...maxYatIDLenght).contains(yatID.count) else { return }

        Yat.api.fetchRecordsPublisher(forEmojiID: yatID, symbol: "XTR")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] in self?.handle(apiResponse: $0, yatID: yatID) }
            )
            .store(in: &cancelables)
    }
    
    private func handle(apiResponse: LookupEmojiIDWithSymbolResponse, yatID: String) {
        guard let walletAddress = apiResponse.result?.first?.data else { return }
        generatePublicKey(text: walletAddress)
        self.yatID = yatID
    }
    
    // MARK: - Actions - Public Key
    
    private func generatePublicKey(text: String) {
        
        do {
            let publicKey = try PublicKey(any: text)
            verify(publicKey: publicKey)
            self.publicKey = publicKey
        } catch {
            publicKey = nil
            handle(error: error)
        }
        
        canMoveToNextStep = publicKey != nil
    }
    
    private func verify(publicKey: PublicKey) {
        
        guard publicKey.hex.0 != TariLib.shared.tariWallet?.publicKey.0?.hex.0 else {
            errorMessage = localized("add_recipient.warning.can_not_send_yourself.with_param", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol)
            return
        }
    }
    
    private func handle(error: Error) {
        
        guard let error = error as? PublicKeyError else {
            errorMessage = nil
            return
        }
        
        switch error {
        case .invalidEmojiSet:
            errorMessage = localized("add_recipient.error.load_contacts.invalid_emoji_set")
        default:
            errorMessage = nil
        }
    }
    
    // MARK: - Actions - Pasteboard
    
    func checkPasteboard() {
        guard let pasteboardText = UIPasteboard.general.string, let publicKey = try? PublicKey(any: pasteboardText) else { return }
        validatedPasteboardText = publicKey.emojis.0
    }
}

private extension Contact {
    
    func viewItem(uuid: UUID) -> ContactElementItem {
        let isEmojiID = alias.0.isEmpty
        let title = isEmojiID ? (publicKey.0?.emojis.0.obfuscatedText ?? "") : alias.0
        let initial = isEmojiID ? "" : title.prefix(1)
        return ContactElementItem(id: uuid, title: title, initial: String(initial), isEmojiID: isEmojiID)
    }
}

private extension PublicKey {
    
    func viewItem(uuid: UUID) -> ContactElementItem {
        let title = emojis.0.obfuscatedText
        return ContactElementItem(id: uuid, title: title, initial: "", isEmojiID: true)
    }
}

private extension String {
    var obfuscatedText: String {
        guard count >= 9 else { return self }
        return "\(prefix(3))•••\(suffix(3))"
    }
}
