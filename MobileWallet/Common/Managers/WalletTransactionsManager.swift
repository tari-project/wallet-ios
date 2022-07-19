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
        case unableToStartWallet
        case timeout
    }

    enum State {
        case connectionCheck
        case transaction
    }

    // MARK: - Properties

    private let connectionTimeout: TimeInterval = 30.0
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
                self?.verifyWalletStateAndSendTransactionToBlockchain(publicKey: publicKey, amount: amount, feePerGram: feePerGram, message: message, isOneSidedPayment: isOneSidedPayment) { result in
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

        let connectionState = LegacyConnectionMonitor.shared.state

        switch connectionState.reachability {
        case .offline, .unknown:
            result(.failure(.noInternetConnection))
        case .wifi, .cellular:
            break
        }

        let startDate = Date()

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in

            if connectionState.torStatus == .connected, connectionState.torBootstrapProgress == 100 {
                timer.invalidate()
                result(.success)
            }

            guard let self = self, -startDate.timeIntervalSinceNow > self.connectionTimeout else { return }

            timer.invalidate()
            result(.failure(.timeout))
        }
    }

    private func verifyWalletStateAndSendTransactionToBlockchain(publicKey: PublicKey, amount: MicroTari, feePerGram: MicroTari, message: String, isOneSidedPayment: Bool, result: @escaping (Result<Void, TransactionError>) -> Void) {

        var cancel: AnyCancellable?

        cancel = TariLib.shared.walletStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] walletState in
                switch walletState {
                case .started:
                    cancel?.cancel()
                    self?.sendTransactionToBlockchain(publicKey: publicKey, amount: amount, feePerGram: feePerGram, message: message, isOneSidedPayment: isOneSidedPayment, result: result)
                case .startFailed:
                    cancel?.cancel()
                    result(.failure(.unableToStartWallet))
                case .notReady, .starting:
                    break
                }
            }

        cancel?.store(in: &cancellables)
    }

    private func sendTransactionToBlockchain(publicKey: PublicKey, amount: MicroTari, feePerGram: MicroTari, message: String, isOneSidedPayment: Bool, result: @escaping (Result<Void, TransactionError>) -> Void) {
        
        guard let wallet = TariLib.shared.tariWallet else { return }

        do {
            let transactionID = try wallet.sendTx(destination: publicKey, amount: amount, feePerGram: feePerGram, message: message, isOneSidedPayment: isOneSidedPayment)

            guard !isOneSidedPayment else {
                result(.success)
                return
            }
            startListeningForWalletEvents(transactionID: transactionID, publicKey: publicKey, result: result)
        } catch {
            result(.failure(.transactionError(error: error)))
        }
    }

    private func startListeningForWalletEvents(transactionID: UInt64, publicKey: PublicKey, result: @escaping (Result<Void, TransactionError>) -> Void) {
        
        TariEventBus.events(forType: .transactionSendResult)
            .compactMap { $0.object as? TransactionResult }
            .filter { $0.id == transactionID }
            .sink { [weak self] in
                
                self?.cancelWalletEvents()
                
                guard $0.status.isSuccess else {
                    result(.failure(.unsucessfulTransaction))
                    return
                }
                
                self?.sendPushNotificationToRecipient(publicKey: publicKey)
                
                TariLogger.info("Transaction send successful.")
                Tracker.shared.track(eventWithCategory: "Transaction", action: "Transaction Accepted")
                result(.success)
            }
            .store(in: &cancellables)
    }

    private func sendPushNotificationToRecipient(publicKey: PublicKey) {

        do {
            try NotificationManager.shared.sendToRecipient(
                publicKey,
                onSuccess: { TariLogger.info("Recipient has been notified") },
                onError: { TariLogger.error("Failed to notify recipient", error: $0) }
            )
        } catch {
            TariLogger.error("Failed to notify recipient", error: error)
        }
    }

    private func cancelWalletEvents() {
        cancellables.forEach { $0.cancel() }
    }
}
