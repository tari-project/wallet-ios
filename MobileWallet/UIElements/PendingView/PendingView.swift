//  RestoreWalletPendingView.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 11.06.2020
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

import UIKit
import Lottie

class PendingView: UIView {

    private let containerStackView = UIStackView()
    private let title: String?
    private let definition: String?

    init(title: String?, definition: String?) {
        self.title = title
        self.definition = definition
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showPendingView(completion: (() -> Void)? = nil) {
        setupPendingView()
        UIView.animate(withDuration: CATransaction.animationDuration(), animations: { [weak self] in
            self?.alpha = 1.0
        }) { (_) in
            completion?()
        }
    }

    func hidePendingView(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: CATransaction.animationDuration(), animations: { [weak self] in
            self?.alpha = 0.0
        }) { [weak self] (_) in
            self?.removeFromSuperview()
            completion?()
        }
    }

    private func setupPendingView() {
        let view: UIView
        if let keyWindow = UIApplication.shared.keyWindow {
            view = keyWindow
        } else if let topController = UIApplication.shared.topController() {
            view = topController.view
        } else { return }

        view.addSubview(self)
        alpha = 0.0
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func setupSubviews() {
        backgroundColor = Theme.shared.colors.appBackground
        setupContainerView()
        setupPendingAnimation()
    }

    private func setupContainerView() {
        containerStackView.distribution = .fill
        containerStackView.alignment = .center
        containerStackView.axis = .vertical

        addSubview(containerStackView)

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 25).isActive = true
        containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -25).isActive = true

        setupImageView()
        setupTitle()
        setupDescription()
    }

    private func setupImageView() {
        let imageView = UIImageView()
        imageView.image = Theme.shared.images.tariIcon

        imageView.widthAnchor.constraint(equalToConstant: 55.0).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 55.0).isActive = true

        containerStackView.addArrangedSubview(imageView)
        containerStackView.setCustomSpacing(30.0, after: imageView)
    }

    private func setupTitle() {
        let title = UILabel()

        title.text = self.title
        title.font = Theme.shared.fonts.restorePendingViewTitle
        title.textColor = Theme.shared.colors.restorePendingViewTitle

        containerStackView.addArrangedSubview(title)
        containerStackView.setCustomSpacing(10.0, after: title)
    }

    private func setupDescription() {
        let description = UILabel()
        description.numberOfLines = 0
        description.textAlignment = .center

        description.text = self.definition
        description.font = Theme.shared.fonts.restorePendingViewDescription
        description.textColor = Theme.shared.colors.restorePendingViewDescription

        containerStackView.addArrangedSubview(description)
    }

    private func setupPendingAnimation() {
        let pendingAnimationView = AnimationView()
        pendingAnimationView.backgroundBehavior = .pauseAndRestore
        pendingAnimationView.animation = Animation.named(.pendingCircleAnimation)

        addSubview(pendingAnimationView)
        pendingAnimationView.translatesAutoresizingMaskIntoConstraints = false
        pendingAnimationView.widthAnchor.constraint(equalToConstant: 45).isActive = true
        pendingAnimationView.heightAnchor.constraint(equalToConstant: 45).isActive = true
        pendingAnimationView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        pendingAnimationView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30).isActive = true

        pendingAnimationView.play(fromProgress: 0, toProgress: 1, loopMode: .loop)
    }
}
