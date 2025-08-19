//  WalletTransactionsManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 08/02/2022
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

import Foundation
import Combine

final class WalletTransactionsManager {
    enum TransactionError: Error {
        case transactionError(error: Error)
        case unsucessfulTransaction
        case noInternetConnection
        case timeout
        case missingInputData
    }

    enum State {
        case connectionCheck
    }

    // MARK: - Properties

    private let connectionTimeout: DispatchQueue.SchedulerTimeType.Stride = .seconds(30)
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Actions

    func performTransactionPublisher(address: String, amount: MicroTari, feePerGram: MicroTari, paymentID: String) -> AnyPublisher<State, TransactionError> {
        let subject = CurrentValueSubject<State, TransactionError>(.connectionCheck)

        waitForConnection { [weak self] result in
            switch result {
            case .success:
                self?.sendTransactionToBlockchain(address: address, amount: amount, feePerGram: feePerGram, paymentID: paymentID) { result in
                    switch result {
                    case .success:
                        subject.send(completion: .finished)
                    case let .failure(error):
                        subject.send(completion: .failure(error))
                    }
                }
            case let .failure(error):
                subject.send(completion: .failure(error))
            }
        }
        return subject.eraseToAnyPublisher()
    }

    private func waitForConnection(result: @escaping (Result<Void, TransactionError>) -> Void) {
        guard case .connected = AppConnectionHandler.shared.connectionMonitor.networkConnection else {
            result(.failure(.noInternetConnection))
            return
        }
        result(.success)
    }

    private func sendTransactionToBlockchain(address: String, amount: MicroTari, feePerGram: MicroTari, paymentID: String, result: @escaping (Result<Void, TransactionError>) -> Void) {
        do {
            try Tari.mainWallet.transactions.send(
                toAddress: try TariAddress(base58: address),
                amount: amount.rawValue,
                feePerGram: feePerGram.rawValue,
                paymentID: paymentID
            )
            result(.success)
        } catch {
            result(.failure(.transactionError(error: error)))
        }
    }
}
