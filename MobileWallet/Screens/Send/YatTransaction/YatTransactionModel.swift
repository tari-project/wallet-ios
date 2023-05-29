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

enum YatTransactionViewState {
    case idle
    case initial(transaction: String, yatID: String)
    case playVideo(url: URL, scaleToFill: Bool)
    case completion
    case failed
}

final class YatTransactionModel {

    struct InputData {
        let address: String
        let amount: MicroTari
        let feePerGram: MicroTari
        let message: String
        let yatID: String
        let isOneSidedPayment: Bool
    }

    // MARK: - View Model

    @Published private(set) var viewState: YatTransactionViewState = .idle
    @Published private(set) var error: WalletTransactionsManager.TransactionError?

    // MARK: - Constants

    private let connectionTimeout = 30

    // MARK: - Properties

    private let inputData: InputData
    private let cacheManager = YatCacheManager()
    private let walletTransactionsManager = WalletTransactionsManager()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializers

    init(inputData: InputData) {
        self.inputData = inputData
    }

    // MARK: - Actions

    func start() {
        guard case .idle = viewState else { return }

        setupInitialViewState()
        sendTransactionToBlockchain()
        fetchAnimation()
    }

    private func setupInitialViewState() {
        let amount = "\(inputData.amount.formatted) \(NetworkManager.shared.selectedNetwork.tickerSymbol)"
        viewState = .initial(transaction: localized("yat_transaction.label.transaction.sending", arguments: amount), yatID: inputData.yatID)
    }

    private func show(error: WalletTransactionsManager.TransactionError) {
        self.error = error
        viewState = .failed
    }

    // MARK: - Yat Visualisation

    private func fetchAnimation() {
        Yat.api.emojiID.loadJsonPublisher(eid: inputData.yatID, key: "VisualizerFileLocations")
            .map(\.data)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] in self?.handle(fileLocations: $0) }
            )
            .store(in: &cancellables)
    }

    private func handle(fileLocations: [String: CodableValue]) {

        guard let path = fileLocations["v_video"] ?? fileLocations["video"], let rawPath = path.value as? String, let url = URL(string: rawPath) else { return }

        guard let cachedFileData = cacheManager.fetchFileData(name: url.lastPathComponent) else {
            download(assetURL: url)
            return
        }

        play(fileData: cachedFileData)
        Logger.log(message: "Play Yat visualisation from local cache", domain: .general, level: .info)
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
        guard let fileData = cacheManager.save(data: videoData, name: name) else { return }
        play(fileData: fileData)
        Logger.log(message: "Play Yat visualisation from web", domain: .general, level: .info)
    }

    private func play(fileData: YatCacheManager.FileData) {
        let scaleToFill = fileData.identifier == .verticalVideo
        viewState = .playVideo(url: fileData.url, scaleToFill: scaleToFill)
    }

    // MARK: - Wallet

    private func sendTransactionToBlockchain() {

        walletTransactionsManager.performTransactionPublisher(address: inputData.address, amount: inputData.amount, feePerGram: inputData.feePerGram, message: inputData.message, isOneSidedPayment: inputData.isOneSidedPayment)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.viewState = .completion
                case let .failure(error):
                    self?.show(error: error)
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }
}
