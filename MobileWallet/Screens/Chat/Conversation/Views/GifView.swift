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
import Lottie

final class GifView: UIView {

    // MARK: - Subviews

    private var mediaView: GPHMediaView?

    @View private var spinnerView: AnimationView = {
        let view = AnimationView()
        view.backgroundBehavior = .pauseAndRestore
        view.animation = Animation.named(.pendingCircleAnimation)
        view.loopMode = .loop
        view.play()
        return view
    }()

    // MARK: - Properties

    var gifID: String? {
        didSet { handle(gifID: gifID) }
    }

    var onStateUpdate: (() -> Void)?

    private let dynamicModel = GifDynamicModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupCallbacks()
        setupConstraints()
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

    private func setupConstraints() {

        [spinnerView].forEach(addSubview)

        let constraints = [
            spinnerView.topAnchor.constraint(equalTo: topAnchor),
            spinnerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            spinnerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            spinnerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    private func update(dataState: GifDynamicModel.GifDataState) {

        switch dataState {
        case .none:
            removeGifView()
            updateSpinnerView(isVisible: false)
        case .loading:
            updateSpinnerView(isVisible: true)
        case let .loaded(data):
            updateSpinnerView(isVisible: false)
            removeGifView()
            addGifView(media: data)
        case .failed:
            updateSpinnerView(isVisible: false)
        }

        onStateUpdate?()
    }

    // MARK: - Actions

    private func addGifView(media: GPHMedia) {

        @View var mediaView = GPHMediaView()
        mediaView.media = media
        addSubview(mediaView)

        mediaView.subviews.forEach { $0.isHidden = true }

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

    private func updateSpinnerView(isVisible: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.spinnerView.alpha = isVisible ? 1.0 : 0.0
        }
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
