//  KeyboardAvoidingContentView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 28/07/2021
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

import UIKit
import Combine

class KeyboardAvoidingContentView: UIView {

    // MARK: - Subviews

    private let scrollView: ContentScrollView = {
        let view = ContentScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var contentView: UIView { scrollView.contentView }

    // MARK: - Properties

    private var bottomConstraint: NSLayoutConstraint?
    private var cancelables: Set<AnyCancellable> = []

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupConstraints()
        setupFeedbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        addSubview(scrollView)

        let bottomConstraint = scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        self.bottomConstraint = bottomConstraint

        let constraints = [
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomConstraint
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupFeedbacks() {

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] in self?.handle(onKeyboardWillShowNotification: $0) }
            .store(in: &cancelables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] in self?.handle(onKeyboardWillHideNotification: $0) }
            .store(in: &cancelables)
    }

    // MARK: - Actions

    private func update(bottomMargin: CGFloat, animationTime: TimeInterval) {

        bottomConstraint?.constant = -bottomMargin

        UIView.animate(withDuration: animationTime, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut]) { [weak self] in
            self?.layoutIfNeeded()
        }

    }

    // MARK: - Handlers

    private func handle(onKeyboardWillShowNotification notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationTime = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else { return }
        update(bottomMargin: keyboardFrame.height, animationTime: animationTime)
    }

    private func handle(onKeyboardWillHideNotification notification: Notification) {
        guard let animationTime = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        update(bottomMargin: 0.0, animationTime: animationTime)
    }
}
