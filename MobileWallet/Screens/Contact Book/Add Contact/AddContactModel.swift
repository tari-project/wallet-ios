//  AddContactModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 15/03/2023
	Using Swift 5.0
	Running on macOS 13.0

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

final class AddContactModel {

    enum Action {
        case endFlow(model: ContactsManager.Model)
    }

    private enum DataValidationError: Int, Error, Comparable {

        case noEmojiID
        case invalidEmojiID
        case noName

        static func < (lhs: AddContactModel.DataValidationError, rhs: AddContactModel.DataValidationError) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - View Model

    let searchTextSubject: CurrentValueSubject<String, Never> = CurrentValueSubject("")

    @Published var contactName: String = ""
    @Published var isSearchTextFormatted: Bool = true

    @Published private(set) var isDataValid: Bool = false
    @Published private(set) var action: Action?
    @Published private(set) var errorText: String?
    @Published private(set) var errorMessage: MessageModel?

    // MARK: - Properties

    private var rawSearchText: String = ""
    private var address: TariAddress?
    @Published private var errors = Set<DataValidationError>([.noEmojiID])

    private let contactsManager = ContactsManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        Publishers.CombineLatest(searchTextSubject.removeDuplicates(), $isSearchTextFormatted.removeDuplicates())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(searchText: $0, isSearchTextFormatted: $1) }
            .store(in: &cancellables)

        $contactName
            .sink { [weak self] in self?.handle(contactName: $0) }
            .store(in: &cancellables)

        $errors
            .map { $0.sorted().first }
            .map { [weak self] in self?.makeErrorText(error: $0) }
            .sink { [weak self] in self?.errorText = $0 }
            .store(in: &cancellables)

        $errors
            .map { $0.isEmpty }
            .assignPublisher(to: \.isDataValid, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func createContact() {
        do {
            guard let address else { return }
            let model = try contactsManager.createInternalModel(name: contactName, isFavorite: false, address: address)
            action = .endFlow(model: model)
        } catch {
            errorMessage = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func handle(deeplink: TransactionsSendDeeplink) {
        let address = TariAddressFactory.address(text: deeplink.receiverAddress)
        guard let emojis = try? address?.emojis else { return }
        rawSearchText = emojis
        searchTextSubject.send(emojis)
    }

    // MARK: - Handlers

    private func handle(searchText: String, isSearchTextFormatted: Bool) {

        if !isSearchTextFormatted {
            rawSearchText = searchText
        }

        handle(searchText: rawSearchText)

        if isSearchTextFormatted, address != nil {
            searchTextSubject.send(rawSearchText.insertSeparator(" | ", atEvery: 3))
        } else {
            searchTextSubject.send(rawSearchText)
        }
    }

    private func handle(searchText: String) {

        guard !searchText.isEmpty else {
            address = nil
            errors.remove(.invalidEmojiID)
            errors.insert(.noEmojiID)
            return
        }

        errors.remove(.noEmojiID)

        guard let address = TariAddressFactory.address(text: searchText) else {
            address = nil
            errors.insert(.invalidEmojiID)
            return
        }

        self.address = address
        errors.remove(.invalidEmojiID)
    }

    private func handle(contactName: String) {

        guard !contactName.isEmpty else {
            errors.insert(.noName)
            return
        }

        errors.remove(.noName)
    }

    private func makeErrorText(error: DataValidationError?) -> String? {

        guard let error else { return nil }

        switch error {
        case .noEmojiID:
            return nil
        case .invalidEmojiID:
            return localized("contact_book.add_contact.validation_error.invalid_emoji_id")
        case .noName:
            return localized("contact_book.add_contact.validation_error.no_name")
        }
    }
}

enum TariAddressFactory {

    static func address(text: String) -> TariAddress? {

        if let address = try? TariAddress(emojiID: text) {
            return address
        }

        return try? TariAddress(hex: text)
    }
}
