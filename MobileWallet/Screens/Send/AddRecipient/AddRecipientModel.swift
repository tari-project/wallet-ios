//  AddRecipientModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 21/07/2023
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

import Combine
import YatLib

final class AddRecipientModel {

    enum Action {
        case sendTokens(paymentInfo: PaymentInfo)
        case show(dialog: DialogType)
    }

    enum DialogType {
        case bleTransactionWaitingForReceiverDialog
        case bleTransactionConfirmationDialog(receiverName: String)
        case bleFailureDialog(message: String?)
    }

    fileprivate enum SectionType: Int {
        case recentContacts
        case contacts
    }

    // MARK: - Constants

    private let maxYatIDLenght: Int = 5

    // MARK: - View Model

    @Published private(set) var listSections: [AddRecipientView.Section] = []
    @Published private(set) var action: Action?
    @Published private(set) var isYatFound: Bool = false
    @Published private(set) var isAddressPreviewAvaiable: Bool = false
    @Published private(set) var walletAddressPreview: String?
    @Published private(set) var canMoveToNextStep: Bool = false
    @Published private(set) var errorMessage: String?

    let searchText = CurrentValueSubject<String, Never>("")

    // MARK: - Properties

    private let contactsManager = ContactsManager()

    @Published private var address: TariAddress?
    @Published private var yatID: String?
    @Published private var contactModels: [ContactsManager.Model] = []

    private weak var bleTask: BLECentralTask?

    private var incomingUserProfile: UserProfileDeeplink?
    private var contactDictornary: [UUID: ContactsManager.Model] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
        fetchContacts()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        Publishers.CombineLatest($contactModels, searchText)
            .compactMap { [weak self] in
                guard let self else { return [[ContactsManager.Model]]() }
                let contacts = [self.fetchRecentContacts(), $0]
                return self.filter(contacts: contacts, searchText: $1)
            }
            .compactMap { [weak self] in self?.map(contacts: $0) }
            .sink { [weak self] in self?.listSections = $0 }
            .store(in: &cancellables)

        searchText
            .sink { [weak self] in self?.generateAddress(text: $0) }
            .store(in: &cancellables)

        searchText
            .throttle(for: .milliseconds(750), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in self?.searchAddress(forYatID: $0) }
            .store(in: &cancellables)

        $address
            .map { $0 != nil }
            .assign(to: \.canMoveToNextStep, on: self)
            .store(in: &cancellables)

        $yatID
            .sink { [weak self] in self?.isYatFound = $0 != nil }
            .store(in: &cancellables)

        Publishers.CombineLatest($yatID, $address)
            .sink { [weak self] in self?.isAddressPreviewAvaiable = $0 != nil && $1 != nil }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func fetchContacts() {
        Task {
            do {
                try await contactsManager.fetchModels()
                contactModels = contactsManager.tariContactModels.filter(\.isFFIContact)
            } catch {
                contactModels = []
            }
        }
    }

    private func fetchRecentTariAddresses() throws -> [TariAddress] {

        let transactionsService = Tari.shared.wallet(.main).transactions
        let transactions: [Transaction] = transactionsService.completed + transactionsService.pendingInbound + transactionsService.pendingOutbound

        let addresses = try transactions
            .sorted { try $0.timestamp > $1.timestamp }
            .map { try $0.address }
            .reduce(into: (identifiers: [String](), output: [TariAddress]())) { result, address in
                let addressComponents = try address.components
                guard !result.identifiers.contains(addressComponents.uniqueIdentifier), !addressComponents.isUnknownAddress else { return }
                result.identifiers.append(addressComponents.uniqueIdentifier)
                result.output.append(address)
            }
            .output
            .prefix(3)

        return Array(addresses)
    }

    private func fetchRecentContacts() -> [ContactsManager.Model] {

        let allContacts = contactsManager.tariContactModels

        do {
            return try fetchRecentTariAddresses().compactMap { address in try allContacts.first { try $0.internalModel?.addressComponents.uniqueIdentifier == address.components.uniqueIdentifier }}
        } catch {
            return []
        }
    }

    // MARK: - View Model Actions

    func handle(qrCodeData: QRCodeData) {

        guard case let .deeplink(deeplink) = qrCodeData else { return }

        if let deeplink = deeplink as? TransactionsSendDeeplink {
            var amount: MicroTari?
            if let rawAmount = deeplink.amount {
                amount = MicroTari(rawAmount)
            }
            guard let addressComponents = try? TariAddress(base58: deeplink.receiverAddress).components else { return }
            handleAddressSelection(paymentInfo: PaymentInfo(addressComponents: addressComponents, alias: nil, yatID: nil, amount: amount, feePerGram: nil, note: deeplink.note))
        } else if let deeplink = deeplink as? UserProfileDeeplink {
            guard let addressComponents = try? TariAddress(base58: deeplink.tariAddress).components else { return }
            handleAddressSelection(paymentInfo: PaymentInfo(addressComponents: addressComponents, alias: deeplink.alias, yatID: nil, amount: nil, feePerGram: nil, note: nil))
        }
    }

    func select(elementID: UUID) {
        guard let model = contactDictornary[elementID]?.internalModel else { return }
        handleAddressSelection(paymentInfo: PaymentInfo(addressComponents: model.addressComponents, alias: nil, yatID: yatID, amount: nil, feePerGram: nil, note: nil))
    }

    func fetchTransactionDataViaBLE() {

        let bleTask = BLECentralTask(service: BLEConstants.contactBookService.uuid, characteristic: BLEConstants.contactBookService.characteristics.transactionData)
        self.bleTask?.cancel()
        self.bleTask = bleTask

        action = .show(dialog: .bleTransactionWaitingForReceiverDialog)

        Task {
            do {
                guard let rawDeeplink = try await bleTask.findAndRead()?.string, let url = URL(string: rawDeeplink) else { return }
                let deeplink = try DeepLinkFormatter.model(type: UserProfileDeeplink.self, deeplink: url)
                incomingUserProfile = deeplink
                action = .show(dialog: .bleTransactionConfirmationDialog(receiverName: deeplink.alias))
            } catch {
                handle(bleError: error)
            }
        }
    }

    func cancelBLETask() {
        bleTask?.cancel()
    }

    func confirmIncomingTransaction() {

        guard let incomingUserProfile else {
            action = .show(dialog: .bleFailureDialog(message: ErrorMessageManager.errorMessage(forError: nil)))
            return
        }

        self.incomingUserProfile = nil

        guard let addressComponents = try? TariAddress(base58: incomingUserProfile.tariAddress).components else { return }
        handleAddressSelection(paymentInfo: PaymentInfo(addressComponents: addressComponents, alias: incomingUserProfile.alias, yatID: nil, amount: nil, feePerGram: nil, note: nil))
    }

    func cancelIncomingTransaction() {
        incomingUserProfile = nil
    }

    func toogleYatPreview() {
        let isAddressVisible = walletAddressPreview != nil
        walletAddressPreview = isAddressVisible ? nil : try? address?.components.fullRaw
    }

    func requestContinue() {

        guard let addressComponents = try? address?.components else {
            errorMessage = localized("add_recipient.error.invalid_emoji_id")
            return
        }

        handleAddressSelection(paymentInfo: PaymentInfo(addressComponents: addressComponents, alias: nil, yatID: yatID, amount: nil, feePerGram: nil, note: nil))
    }

    // MARK: - Handlers

    private func handleAddressSelection(paymentInfo: PaymentInfo) {
        action = .sendTokens(paymentInfo: paymentInfo)
    }

    private func filter(contacts: [[ContactsManager.Model]], searchText: String) -> [[ContactsManager.Model]] {

        guard !searchText.isEmpty else { return contacts }

        return contacts
            .map {
                $0.filter {
                    guard $0.name.range(of: searchText, options: .caseInsensitive) == nil else { return true }
                    guard let internalModel = $0.internalModel else { return false }
                    guard internalModel.addressComponents.fullEmoji.range(of: searchText, options: .caseInsensitive) == nil else { return true }
                    return internalModel.addressComponents.fullRaw.range(of: searchText, options: .caseInsensitive) != nil
                }
            }
    }

    private func searchAddress(forYatID yatID: String) {

        self.yatID = nil
        guard yatID.containsOnlyEmoji, (1...maxYatIDLenght).contains(yatID.count) else { return }

        Yat.api.emojiID.lookupEmojiIDPaymentPublisher(emojiId: yatID, tags: YatRecordTag.XTMAddress.rawValue)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] in self?.handle(apiResponse: $0, yatID: yatID) }
            )
            .store(in: &cancellables)
    }

    private func handle(apiResponse: PaymentAddressResponse, yatID: String) {
        guard let walletAddress = apiResponse.result?[YatRecordTag.XTMAddress.rawValue]?.address else { return }
        generateAddress(text: walletAddress)
        self.yatID = yatID
    }

    private func map(contacts: [[ContactsManager.Model]]) -> [AddRecipientView.Section] {

        let contactDictornary = contacts.map { $0.map { (identifier: UUID(), model: $0) }}
        var result: [AddRecipientView.Section] = [AddRecipientView.Section(title: nil, items: [.bluetooth])]

        result += contactDictornary
            .enumerated()
            .reduce(into: [AddRecipientView.Section]()) { result, data in

                let section = SectionType(rawValue: data.offset)
                guard !data.element.isEmpty else { return }

                let items: [AddRecipientView.ItemType] = data.element.map {
                    let viewModel = ContactBookCell.ViewModel(id: $0.identifier, addressViewModel: $0.model.contactBookCellAddressViewModel, isFavorite: false, contactTypeImage: nil, isSelectable: false)
                    return .contact(model: viewModel)
                }

                result.append(AddRecipientView.Section(title: section?.title, items: items))
            }

        self.contactDictornary = contactDictornary
            .flatMap { $0 }
            .reduce(into: [:]) { $0[$1.identifier] = $1.model }

        return result
    }

    private func handle(bleError error: Error) {

        Logger.log(message: "Unable to finish BLE task. Reason: \(error)", domain: .general, level: .error)

        let message: String?

        if let error = error as? BLECentralManager.BLECentralError {
            message = error.errorMessage
        } else {
            message = ErrorMessageManager.errorMessage(forError: error)
        }

        action = .show(dialog: .bleFailureDialog(message: message))
    }

    // MARK: - Helpers

    private func generateAddress(text: String) {

        guard let address = try? makeAddress(text: text) else {
            address = nil
            errorMessage = nil
            return
        }

        let isValid = verify(address: address)
        self.address = isValid ? address : nil
    }

    private func makeAddress(text: String) throws -> TariAddress {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return try TariAddress.makeTariAddress(input: trimmedText)
    }

    private func verify(address: TariAddress) -> Bool {

        guard let uniqueIdentifier = try? address.components.uniqueIdentifier, let userUniqueIdentifier = try? Tari.shared.wallet(.main).address.components.uniqueIdentifier, uniqueIdentifier != userUniqueIdentifier else {
            errorMessage = localized("add_recipient.error.can_not_send_yourself", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol)
            return false
        }

        errorMessage = nil
        return true
    }
}

private extension AddRecipientModel.SectionType {

    var title: String? {
        switch self {
        case .recentContacts:
            return localized("add_recipient.recent_txs")
        case .contacts:
            return localized("add_recipient.my_contacts")
        }
    }
}
