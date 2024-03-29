//  TransactionDynamicModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 09/07/2023
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

import GiphyUISDK

final class TransactionDynamicModel {

    enum GifDataState {
        case none
        case loading
        case loaded(GPHMedia)
        case failed
    }

    // MARK: - Properties

    @Published private(set) var formattedTimestamp: String = ""
    @Published private(set) var gif: GifDataState = .none

    private let timestamp: TimeInterval
    private let giphyID: String?

    // MARK: - Initialisers

    init(timestamp: TimeInterval, giphyID: String?) {
        self.timestamp = timestamp
        self.giphyID = giphyID
        setupTimer()
        updateFormattedTimestamp()
        fetchGif()
    }

    // MARK: - Setups

    private func setupTimer() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateFormattedTimestamp()
        }
    }

    // MARK: - Actions

    private func updateFormattedTimestamp() {
        formattedTimestamp = Date(timeIntervalSince1970: timestamp).relativeDayFromToday() ?? ""
    }

    func fetchGif() {

        guard let giphyID else {
            gif = .none
            return
        }

        TxGifManager.shared.cancelDownloadGif(gifID: giphyID)

        gif = .loading

        if let cachedGif = TxGifManager.shared.getGifFromCache(gifID: giphyID) {
            gif = .loaded(cachedGif)
            return
        }

        TxGifManager.shared.downloadGif(gifID: giphyID) { [weak self] result in
            switch result {
            case let .success(media):
                self?.gif = .loaded(media)
            case .failure:
                self?.gif = .failed
            }
        }
    }
}
