//  SendingTariView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 04/02/2022
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

import UIKit
import TariCommon
import Lottie

final class SendingTariView: DynamicThemeView {

    struct InputModel {
        let numberOfSections: Int
    }

    // MARK: - Subviews

    @TariView private(set) var videoBackgroundView: VideoView = {
        let view = VideoView()
        view.url = Bundle.main.url(forResource: "sending-background", withExtension: "mp4")
        view.videoGravity = .resizeAspectFill
        return view
    }()

    @TariView private var logoView = AnimationView(name: "sendingTariAnimation")

    @TariView private var firstLabel: SendingTariLabel = {
        let view = SendingTariLabel()
        view.font = Theme.shared.fonts.sendingTariTitleLabelFirst
        view.label.textColor = .Text.primary
        return view
    }()

    @TariView private var secondLabel: SendingTariLabel = {
        let view = SendingTariLabel()
        view.font = Theme.shared.fonts.sendingTariTitleLabelSecond
        view.label.textColor = .Text.primary
        return view
    }()

    @TariView private(set) var progressBar = SendingTariProgressBar()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    func setup(model: InputModel) {
        progressBar.update(sections: model.numberOfSections)
    }

    private func setupConstraints() {

        firstLabel.label.textColor = .Text.primary
        secondLabel.label.textColor = .Text.primary

        [videoBackgroundView, logoView, firstLabel, secondLabel, progressBar].forEach(addSubview)

        let constraints = [
            videoBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            videoBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            logoView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -70.0),
            logoView.widthAnchor.constraint(equalToConstant: 55.0),
            logoView.heightAnchor.constraint(equalToConstant: 55.0),
            firstLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 30.0),
            firstLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30.0),
            firstLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30.0),
            secondLabel.topAnchor.constraint(equalTo: firstLabel.bottomAnchor),
            secondLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30.0),
            secondLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30.0),
            progressBar.topAnchor.constraint(equalTo: secondLabel.bottomAnchor, constant: 40.0),
            progressBar.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions

    func playInitialAnimation() {
        logoView.play(fromProgress: 0.0, toProgress: 0.2)
    }

    func playSuccessAnimation(completion: (() -> Void)? = nil) {
        logoView.play(fromProgress: 0.2, toProgress: 1.0) { _ in
            completion?()
        }
    }

    func playFailureAnimation(completion: (() -> Void)? = nil) {
        logoView.play(fromProgress: 0.2, toProgress: 0.0) { _ in
            completion?()
        }
    }

    func hideAllComponents(delay: TimeInterval, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 1.0, delay: delay, options: [], animations: { [weak self] in
            self?.firstLabel.alpha = 0.0
            self?.secondLabel.alpha = 0.0
            self?.progressBar.alpha = 0.0
        }, completion: { _ in
            completion?()
        })
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        firstLabel.label.textColor = .Text.primary
        secondLabel.label.textColor = .Text.primary
    }

    func update(firstText: String?, secondText: String?, completion: (() -> Void)?) {

        firstLabel.update(text: firstText)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.secondLabel.update(text: secondText) {
                completion?()
            }
        }
    }
}
