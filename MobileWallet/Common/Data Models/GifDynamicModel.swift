//  GifDynamicModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 25/04/2024
	Using Swift 5.0
	Running on macOS 14.4

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

final class GifDynamicModel {

    enum GifDataState {
        case none
        case loading
        case loaded(data: GPHMedia)
        case failed
    }

    // MARK: - Properties

    @Published private(set) var gif: GifDataState = .none
    private var identifier: String?

    // MARK: - Actions

    func fetchGif(identifier: String) {

        gif = .loading
        self.identifier = identifier

        GiphyCore.shared.gifByID(identifier) { [weak self] response, error in

            if error != nil {
                self?.gif = .failed
                return
            }

            guard let response, let data = response.data else {
                self?.gif = .failed
                return
            }

            guard let expectedID = self?.identifier, data.id == expectedID else {
                self?.gif = .none
                return
            }

            self?.gif = .loaded(data: data)
        }
    }

    func clearData() {
        self.identifier = nil
        gif = .none
    }
}
