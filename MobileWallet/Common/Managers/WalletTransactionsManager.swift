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

import Combine

final class WalletTransactionsManager {

    enum TransactionError: Error {
        case transactionError(error: Error)
        case unsucessfulTransaction
        case noInternetConnection
        case timeout
    }

    enum State {
        case connectionCheck
        case transaction
    }

    // MARK: - Properties

    private let connectionTimeout: DispatchQueue.SchedulerTimeType.Stride = .seconds(30)
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Actions

    func performTransactionPublisher(publicKey: PublicKey, amount: MicroTari, feePerGram: MicroTari, message: String, isOneSidedPayment: Bool) -> AnyPublisher<State, TransactionError> {

        let subject = CurrentValueSubject<State, TransactionError>(.connectionCheck)

        waitForConnection { [weak self] result in
            switch result {
            case .success:
                if !isOneSidedPayment {
                    subject.send(.transaction)
                }
                self?.sendTransactionToBlockchain(publicKey: publicKey, amount: amount, feePerGram: feePerGram, message: message, isOneSidedPayment: isOneSidedPayment) { result in
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

        guard case .connected = Tari.shared.connectionMonitor.networkConnection else {
            result(.failure(.noInternetConnection))
            return
        }
        
        Publishers.CombineLatest(Tari.shared.connectionMonitor.$torConnection, Tari.shared.connectionMonitor.$isTorBootstrapCompleted)
            .filter { $0 == .connected && $1 }
            .timeout(connectionTimeout, scheduler: DispatchQueue.global())
            .first()
            .sink(
                receiveCompletion: {
                    guard case .failure = $0 else { return }
                    result(.failure(.timeout))
                },
                receiveValue: { _ in result(.success) }
            )
            .store(in: &cancellables)
    }

    private func sendTransactionToBlockchain(publicKey: PublicKey, amount: MicroTari, feePerGram: MicroTari, message: String, isOneSidedPayment: Bool, result: @escaping (Result<Void, TransactionError>) -> Void) {

        do {
            let transactionID = try Tari.shared.transactions.send(
                toPublicKey: publicKey,
                amount: amount.rawValue,
                feePerGram: feePerGram.rawValue,
                message: message,
                isOneSidedPayment: isOneSidedPayment
            )

            guard !isOneSidedPayment else {
                result(.success)
                return
            }
            startListeningForWalletEvents(transactionID: transactionID, recipientHex: try publicKey.byteVector.hex, result: result)
        } catch {
            result(.failure(.transactionError(error: error)))
        }
    }

    private func startListeningForWalletEvents(transactionID: UInt64, recipientHex: String, result: @escaping (Result<Void, TransactionError>) -> Void) {
        
        WalletCallbacksManager.shared.transactionSendResult
            .filter { $0.identifier == transactionID }
            .first()
            .sink { [weak self] in
                guard $0.status.isSuccess else {
                    result(.failure(.unsucessfulTransaction))
                    return
                }
                
                self?.sendPushNotificationToRecipient(recipientHex: recipientHex)
                
                Logger.log(message: "Transaction send successful", domain: .general, level: .info)
                result(.success)
            }
            .store(in: &cancellables)
    }

    private func sendPushNotificationToRecipient(recipientHex: String) {

        do {
            try NotificationManager.shared.sendToRecipient(
                recipientHex: recipientHex,
                onSuccess: { Logger.log(message: "Recipient has been notified", domain: .general, level: .info) },
                onError: { Logger.log(message: "Failed to notify recipient: \($0.localizedDescription)", domain: .general, level: .error) }
            )
        } catch {
            Logger.log(message: "Failed to notify recipient: \(error.localizedDescription)", domain: .general, level: .error)
        }
    }
}
