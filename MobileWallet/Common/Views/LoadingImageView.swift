//  LoadingImageView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 21/03/2023
	Using Swift 5.0
	Running on macOS 13.0

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

import TariCommon
import Lottie

final class LoadingImageView: UIView {

    enum State {
        case loading
        case image(_ image: UIImage?)
    }

    // MARK: - Subviews

    @TariView private var loadingView: AnimationView = {
        let view = AnimationView()
        view.backgroundBehavior = .pauseAndRestore
        view.animation = .named(.pendingCircleAnimation)
        view.loopMode = .loop
        view.play()
        return view
    }()

    @TariView private var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.alpha = 0.0
        return view
    }()

    // MARK: - Properties

    var state: State = .loading {
        didSet { update(state: state) }
    }

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [loadingView, imageView].forEach(addSubview)

        let constraints = [
            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 44.0),
            loadingView.heightAnchor.constraint(equalToConstant: 44.0),
            loadingView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            loadingView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            loadingView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            loadingView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    private func update(state: State) {
        UIView.animate(withDuration: 0.3) {
            switch state {
            case .loading:
                self.loadingView.alpha = 1.0
                self.imageView.alpha = 0.0
            case let .image(image):
                self.loadingView.alpha = 0.0
                self.imageView.alpha = 1.0
                self.imageView.image = image
            }
        }
    }
}
