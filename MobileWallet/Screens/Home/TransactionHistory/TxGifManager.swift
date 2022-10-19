//  TxGifManager.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 24.09.2020
	Using Swift 5.0
	Running on macOS 10.15

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
import GiphyUISDK
import GiphyCoreSDK

class TxGifManager {
    typealias OnCompletion = ((Result<GPHMedia, Error>) -> Void)

    enum TxGifManagerError: Error {
        case downloadTimeout
    }

    static let shared = TxGifManager()

    private var cachedMedia = NSCache<NSString, GPHMedia>()
    private var operations = [String: Operation]()
    private var completions = [String: [OnCompletion]]()
    private init() { }

    func getGifFromCache(gifID: String) -> GPHMedia? {
        return cachedMedia.object(forKey: gifID as NSString)
    }

    func cancelDownloadGif(gifID: String) {
        if let operation = operations[gifID], operation.isExecuting {
            operations[gifID]?.cancel()
            operations.removeValue(forKey: gifID)
            cachedMedia.removeObject(forKey: gifID as NSString)
            completions.removeValue(forKey: gifID)
        }
    }

    func downloadGif(gifID: String, onCompletion: @escaping OnCompletion) {
        if completions[gifID] != nil {
            completions[gifID]?.append(onCompletion)
        } else {
            completions[gifID] = [onCompletion]
        }

        if operations[gifID] != nil { return }

        let downloadOperation = GiphyCore.shared.gifByID(gifID) { [weak self] (response, error) in
            self?.operations.removeValue(forKey: gifID)

            if let error {
                Logger.log(message: "Failed to load gif: \(error.localizedDescription)", domain: .general, level: .error)
                self?.completions[gifID]?.forEach({ $0(.failure(error)) })
                self?.completions.removeValue(forKey: gifID)
                return
            }
            if let media = response?.data {
                self?.cachedMedia.setObject(media, forKey: gifID as NSString)
                self?.completions[gifID]?.forEach({ $0(.success(media)) })
                self?.completions.removeValue(forKey: gifID)
            }
        }
        operations[gifID] = downloadOperation

        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) {[weak self](timer) in
            timer.invalidate()
            self?.operations[gifID]?.cancel()
            self?.completions[gifID]?.forEach({ $0(.failure(TxGifManagerError.downloadTimeout)) })
        }
    }
}
