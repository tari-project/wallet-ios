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
        case showDetails(model: ContactsManager.Model)
        case popBack
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

    let emojiIDSubject: CurrentValueSubject<String, Never> = CurrentValueSubject("")
    let nameSubject: CurrentValueSubject<String, Never> = CurrentValueSubject("")

    @Published private(set) var isDataValid: Bool = false
    @Published private(set) var action: Action?
    @Published private(set) var errorText: String?
    @Published private(set) var errorMessage: MessageModel?

    // MARK: - Properties

    private var address: TariAddress?
    @Published private var errors = Set<DataValidationError>([.noEmojiID])

    private let contactsManager = ContactsManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(address: TariAddress? = nil) {
        setupCallbacks()
        self.address = address
        if let address = address, let emojis = try? address.emojis {
            emojiIDSubject.send(emojis)
            errors.remove(.noEmojiID)
        }
    }

    // MARK: - Setups

    private func setupCallbacks() {

        emojiIDSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(searchText: $0) }
            .store(in: &cancellables)

        nameSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
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
            let model = try contactsManager.createInternalModel(name: nameSubject.value, isFavorite: false, address: address)
            action = .showDetails(model: model)
        } catch {
            errorMessage = ErrorMessageManager.errorModel(forError: error)
        }
    }

    func handle(qrCodeData: QRCodeData) {

        guard case let .deeplink(deeplink) = qrCodeData else { return }

        switch deeplink {
        case let deeplink as UserProfileDeeplink:
            let address = try? TariAddress.makeTariAddress(input: deeplink.tariAddress)
            guard let emojis = try? address?.emojis else { return }
            emojiIDSubject.send(emojis)
            nameSubject.send(deeplink.alias)
        case let deeplink as TransactionsSendDeeplink:
            let address = try? TariAddress.makeTariAddress(input: deeplink.receiverAddress)
            guard let emojis = try? address?.emojis else { return }
            emojiIDSubject.send(emojis)
        default:
            break
        }
    }

    // MARK: - Handlers

    private func handle(searchText: String) {

        guard !searchText.isEmpty else {
            address = nil
            errors.remove(.invalidEmojiID)
            errors.insert(.noEmojiID)
            return
        }

        errors.remove(.noEmojiID)

        guard let address = try? TariAddress.makeTariAddress(input: searchText) else {
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
