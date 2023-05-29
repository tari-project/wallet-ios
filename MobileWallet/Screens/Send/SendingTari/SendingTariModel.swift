//  SendingTariModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 04/02/2022
	Using Swift 5.0
	Running on macOS 12.1

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

final class SendingTariModel {

    struct InputData {
        let address: String
        let amount: MicroTari
        let feePerGram: MicroTari
        let message: String
        let isOneSidedPayment: Bool
    }

    struct StateModel {
        let firstText: String
        let secondText: String
        let stepIndex: Int
    }

    enum Completion {
        case success
        case failure(WalletTransactionsManager.TransactionError)
    }

    private enum State: Comparable {
        case connectionCheck
        case discovery
        case sent
    }

    // MARK: - View Model

    @Published var stateModel: StateModel?
    @Published var onCompletion: Completion?
    var isNextStepAvailable: Bool { !stateQueue.isEmpty }

    // MARK: - Properties

    @Published private var state: State = .connectionCheck

    private let inputData: InputData
    private let walletTransactionsManager = WalletTransactionsManager()

    private var stateQueue: [State] = []
    private var transactionID: UInt64?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(inputData: InputData) {
        self.inputData = inputData
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {
        $state
            .compactMap { [weak self] in self?.stateModel(forState: $0) }
            .assign(to: \.stateModel, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func start() {
        guard state == .connectionCheck else { return }
        sendTransactionToBlockchain()
    }

    func moveToNextStep() {
        guard isNextStepAvailable else { return }
        state = stateQueue.removeFirst()
    }

    private func addStateToQueue(state: State) {
        guard state > self.state else { return }
        var queue = Set(stateQueue)
        queue.insert(state)
        stateQueue = queue.sorted()
    }

    private func sendTransactionToBlockchain() {

        walletTransactionsManager.performTransactionPublisher(address: inputData.address, amount: inputData.amount, feePerGram: inputData.feePerGram, message: inputData.message, isOneSidedPayment: inputData.isOneSidedPayment)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.finalizeTransaction()
                case let .failure(error):
                    self?.onCompletion = .failure(error)
                }
            } receiveValue: { [weak self] state in
                switch state {
                case .connectionCheck:
                    self?.addStateToQueue(state: .connectionCheck)
                case .transaction:
                    self?.addStateToQueue(state: .discovery)
                }
            }
            .store(in: &cancellables)
    }

    private func finalizeTransaction() {
        addStateToQueue(state: .sent)
        onCompletion = .success
    }

    // MARK: - Handlers

    private func stateModel(forState state: State) -> StateModel? {
        switch state {
        case .connectionCheck:
            return StateModel(firstText: localized("sending_tari.connecting"), secondText: localized("sending_tari.network"), stepIndex: 0)
        case .discovery:
            return StateModel(firstText: localized("sending_tari.searching"), secondText: localized("sending_tari.recipient"), stepIndex: 1)
        case .sent:
            let stepIndex = inputData.isOneSidedPayment ? 1 : 2
            return StateModel(firstText: localized("sending_tari.sent"), secondText: localized("sending_tari.tx_is_on_its_way"), stepIndex: stepIndex)
        }
    }
}
