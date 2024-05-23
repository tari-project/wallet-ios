//  GifView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 23/04/2024
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
import TariCommon
import Combine

final class GifView: UIView {

    // MARK: - Subviews

    private var mediaView: GPHMediaView?

    // MARK: - Properties

    var gifID: String? {
        didSet { handle(gifID: gifID) }
    }

    private let dynamicModel = GifDynamicModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupCallbacks() {
        dynamicModel.$gif
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.update(dataState: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Updates

    private func update(dataState: GifDynamicModel.GifDataState) {
        switch dataState {
        case .none:
            removeGifView()
        case .loading:
            break
        case let .loaded(data):
            addGifView(media: data)
        case .failed:
            break
        }
    }

    // MARK: - Actions

    private func addGifView(media: GPHMedia) {

        @View var mediaView = GPHMediaView()
        mediaView.media = media
        addSubview(mediaView)

        let constraints = [
            mediaView.topAnchor.constraint(equalTo: topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mediaView.widthAnchor.constraint(equalTo: mediaView.heightAnchor, multiplier: media.aspectRatio)
        ]

        NSLayoutConstraint.activate(constraints)

        self.mediaView = mediaView
    }

    private func removeGifView() {
        guard let mediaView else { return }
        NSLayoutConstraint.deactivate(mediaView.constraints)
        mediaView.removeFromSuperview()
        self.mediaView = nil
    }

    // MARK: - Handlers

    private func handle(gifID: String?) {

        guard let gifID = gifID else {
            dynamicModel.clearData()
            return
        }

        dynamicModel.fetchGif(identifier: gifID)
    }
}
