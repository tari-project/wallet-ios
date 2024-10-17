//  ContactTransactionListModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 18/04/2023
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

final class ContactTransactionListModel {

    enum Action {
        case moveToTransaction(transaction: Transaction)
        case moveToTransactionSend(paymentInfo: PaymentInfo)
    }

    // MARK: - Properties

    @Published private(set) var name: String = ""
    @Published private(set) var viewModels: [TxTableViewModel] = []
    @Published private(set) var action: Action?
    @Published private(set) var errorModel: MessageModel?

    private let contactModel: ContactsManager.Model
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(contactModel: ContactsManager.Model) {
        self.contactModel = contactModel
        name = contactModel.name
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {
        Tari.shared.wallet(.main).transactions.$all
            .compactMap { $0.filter { [weak self] in self?.isContactTransaction(transaction: $0) == true }}
            .tryMap { try $0.sorted { try $0.timestamp > $1.timestamp }}
            .replaceError(with: [Transaction]())
            .sink { [weak self] in self?.handle(transactions: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func select(index: Int) {
        guard index < viewModels.count else { return }
        let model = viewModels[index]
        action = .moveToTransaction(transaction: model.transaction)
    }

    func transactionSendRequest() {
        guard let paymentInfo = try? contactModel.paymentInfo else { return }
        action = .moveToTransactionSend(paymentInfo: paymentInfo)
    }

    // MARK: - Handlers

    private func handle(transactions: [Transaction]) {
        do {
            viewModels = try transactions.map { try TxTableViewModel(transaction: $0, contact: contactModel) }
        } catch {
            errorModel = ErrorMessageManager.errorModel(forError: error)
        }
    }

    private func isContactTransaction(transaction: Transaction) -> Bool {

        guard let contactHex = contactModel.internalModel?.addressComponents.uniqueIdentifier else { return false }

        do {
            let transactionHex = try transaction.address.components.uniqueIdentifier
            return transactionHex == contactHex
        } catch {
            return false
        }
    }
}
