//  GifManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 26/04/2024
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

final class GifManager {

    // MARK: - Properites

    @Published private(set) var selectedGifID: String?

    private let gifDelegateHandler = GifDelegateHandler()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {
        gifDelegateHandler.$selectedGifID
            .assign(to: &$selectedGifID)
    }

    // MARK: - Actions

    func showGifPicker(controller: UIViewController) {
        let gifController = GiphyViewController()
        gifController.mediaTypeConfig = [.recents, .gifs, .clips, .emoji, .stickers, .text]
        gifController.delegate = gifDelegateHandler
        controller.present(gifController, animated: true)
    }
}

final class GifDelegateHandler {

    @Published private(set) var selectedGifID: String?
}

extension GifDelegateHandler: GiphyDelegate {

    func didSelectMedia(giphyViewController: GiphyUISDK.GiphyViewController, media: GiphyUISDK.GPHMedia) {
        selectedGifID = media.id
        giphyViewController.dismiss(animated: true)
    }

    func didDismiss(controller: GiphyUISDK.GiphyViewController?) {
    }
}
