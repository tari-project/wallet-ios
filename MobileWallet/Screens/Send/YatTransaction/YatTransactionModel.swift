//  YatTransactionModel.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 21/10/2021
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
import Foundation

enum YatTransactionViewState {
    case idle
    case initial(transaction: String, yatID: String)
    case playVideo(url: URL)
    case completion
    case failed
}

enum TransactionError: Error {
    case noConnection
    case general
}

final class YatTransactionModel {
    
    struct InputData {
        let publicKey: PublicKey
        let amount: MicroTari
        let message: String
        let yatID: String
    }
    
    // MARK: - View Model
    
    @Published private(set) var viewState: YatTransactionViewState = .idle
    @Published private(set) var error: TransactionError?
    
    // MARK: - Constants
    
    private let connectionTimeout = 30
    
    // MARK: - Properties
    
    private let inputData: InputData
    private let cacheManager = YatCacheManager()
    
    private var txId: UInt64?
    private var cancellables = Set<AnyCancellable>()
    private var walletEventsCancellables = Set<AnyCancellable>()
    
    // MARK: - Initializers
    
    init(inputData: InputData) {
        self.inputData = inputData
    }
    
    // MARK: - Actions
    
    func start() {
        guard case .idle = viewState else { return }
        
        self.setupInitialViewState()
        
        waitForConnection { [weak self] in
            self?.verifyWalletStateAndSendTransactionToBlockchain()
            self?.fetchAnimation()
        }
    }
    
    private func setupInitialViewState() {
        let amount = "\(inputData.amount.formatted) \(NetworkManager.shared.selectedNetwork.tickerSymbol)"
        viewState = .initial(transaction: localized("yat_transaction.label.transaction.sending", arguments: amount), yatID: inputData.yatID)
    }
    
    private func show(error: TransactionError) {
        self.error = error
        viewState = .failed
    }
    
    private func waitForConnection(completed: @escaping () -> Void) {
        
        let connectionState = ConnectionMonitor.shared.state
        
        switch connectionState.reachability {
        case .offline, .unknown:
            show(error: .noConnection)
        default:
            break
        }
        
        let startDate = Date()
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            
            if connectionState.torStatus == .connected, connectionState.torBootstrapProgress == 100 {
                timer.invalidate()
                completed()
                return
            }
            
            guard let self = self, Int(-startDate.timeIntervalSinceNow) > self.connectionTimeout else { return }
            timer.invalidate()
            self.show(error: .general)
        }
    }
    
    // MARK: - Yat Visualisation
    
    private func fetchAnimation() {
        
        Yat.api.fetchFromKeyValueStorePublisher(forEmojiID: inputData.yatID, dataType: VisualizerFileLocations.self)
            .compactMap(\.data.video)
            .compactMap { URL(string: $0) }
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] in self?.handle(assetURL: $0) }
            )
            .store(in: &cancellables)
    }
    
    private func handle(assetURL: URL) {
        
        guard let cachedFileURL = cacheManager.fetchFileURL(name: assetURL.lastPathComponent) else {
            download(assetURL: assetURL)
            return
        }
        
        viewState = .playVideo(url: cachedFileURL)
        TariLogger.info("Play Yat visualisation from local cache")
    }
    
    private func download(assetURL: URL) {
        URLSession.shared.dataTaskPublisher(for: assetURL)
            .map(\.data)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] data in
                    self?.save(videoData: data, name: assetURL.lastPathComponent)
                }
            )
            .store(in: &cancellables)
    }
    
    private func save(videoData: Data, name: String) {
        guard let fileURL = cacheManager.save(data: videoData, name: name) else { return }
        viewState = .playVideo(url: fileURL)
        TariLogger.info("Play Yat visualisation from web")
    }
    
    // MARK: - Wallet
    
    private func verifyWalletStateAndSendTransactionToBlockchain() {
        
        var cancel: AnyCancellable?

        cancel = TariLib.shared.walletStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] walletState in
                switch walletState {
                case .started:
                    cancel?.cancel()
                    self?.sendTransactionToBlockchain()
                case .startFailed:
                    cancel?.cancel()
                    self?.show(error: .general)
                case .notReady, .starting:
                    break
                }
            }
        
        cancel?.store(in: &cancellables)
    }
    
    private func sendTransactionToBlockchain() {
        guard let wallet = TariLib.shared.tariWallet else { return }
        do {
            txId = try wallet.sendTx(destination: inputData.publicKey, amount: inputData.amount, feePerGram: Wallet.defaultFeePerGram, message: inputData.message)
            startListeningForWalletEvents()
        } catch {
            show(error: .general)
        }
    }
    
    private func startListeningForWalletEvents() {
        
        let directSendPublisher = TariEventBus.events(forType: .directSend)
            .compactMap { $0.object as? CallbackTxResult }
            .filter { [weak self] in $0.id == self?.txId }
        
        let storeAndForwardPublisher = TariEventBus.events(forType: .storeAndForwardSend)
            .compactMap { $0.object as? CallbackTxResult }
            .filter { [weak self] in $0.id == self?.txId }
        
        directSendPublisher
            .filter(\.success)
            .sink { [weak self] _ in
                self?.cancelWalletEvents()
                self?.sendPushNotificationToRecipient()
                TariLogger.info("Direct send successful.")
                Tracker.shared.track(eventWithCategory: "Transaction", action: "Transaction Accepted - Synchronous")
            }
            .store(in: &walletEventsCancellables)
        
        storeAndForwardPublisher
            .filter(\.success)
            .sink { [weak self] _ in
                self?.cancelWalletEvents()
                self?.sendPushNotificationToRecipient()
                TariLogger.info("Store and forward send successful.")
                Tracker.shared.track(eventWithCategory: "Transaction", action: "Transaction Stored")
            }
            .store(in: &walletEventsCancellables)
        
        Publishers.CombineLatest(directSendPublisher, storeAndForwardPublisher)
            .filter { $0.success == false && $1.success == false}
            .sink { [weak self] _ in
                self?.cancelWalletEvents()
                self?.show(error: .general)
            }
            .store(in: &walletEventsCancellables)
    }
    
    private func sendPushNotificationToRecipient() {
        
        do {
            try NotificationManager.shared.sendToRecipient(
                inputData.publicKey,
                onSuccess: { TariLogger.info("Recipient has been notified") },
                onError: { TariLogger.error("Failed to notify recipient", error: $0) }
            )
        } catch {
            TariLogger.error("Failed to notify recipient", error: error)
        }
        
        viewState = .completion
    }
    
    private func cancelWalletEvents() {
        walletEventsCancellables.forEach { $0.cancel() }
    }
}
