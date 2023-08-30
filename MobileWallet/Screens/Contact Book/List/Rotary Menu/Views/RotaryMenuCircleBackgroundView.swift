//  RotaryMenuCircleBackgroundView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 12/06/2023
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

import TariCommon

final class RotaryMenuCircleBackgroundView: UIView {

    // MARK: - Constants

    private let avatarViewHeight: CGFloat = 170.0
    private let animationTime: TimeInterval = 0.05

    // MARK: - Subviews

    @View private var avatarView: RoundedAvatarView = {
        let view = RoundedAvatarView()
        view.backgroundColorType = .static
        view.alpha = 0.0
        return view
    }()

    @View private var firstCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = .static.white?.withAlphaComponent(0.7)
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.white.cgColor
        view.alpha = 0.0
        return view
    }()

    @View private var secondCircleView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.static.white?.withAlphaComponent(0.8).cgColor
        view.alpha = 0.0
        return view
    }()

    @View private var thirdCircleView: RotaryMenuOuterCircleView = {
        let view = RotaryMenuOuterCircleView()
        view.alpha = 0.0
        return view
    }()

    // MARK: - Properties

    var avatar: RoundedAvatarView.Avatar {
        get { avatarView.avatar }
        set { avatarView.avatar = newValue }
    }

    private var avatarViewSizeConstraints: [NSLayoutConstraint] = []

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupConstaints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstaints() {

        [thirdCircleView, secondCircleView, firstCircleView, avatarView].forEach(addSubview)

        avatarViewSizeConstraints = [
            avatarView.widthAnchor.constraint(equalToConstant: avatarViewHeight / 2.0),
            avatarView.heightAnchor.constraint(equalToConstant: avatarViewHeight / 2.0)
        ]

        let constraints = [
            thirdCircleView.topAnchor.constraint(equalTo: topAnchor),
            thirdCircleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            thirdCircleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            thirdCircleView.bottomAnchor.constraint(equalTo: bottomAnchor),
            secondCircleView.topAnchor.constraint(equalTo: thirdCircleView.topAnchor, constant: 46.0),
            secondCircleView.leadingAnchor.constraint(equalTo: thirdCircleView.leadingAnchor, constant: 46.0),
            secondCircleView.trailingAnchor.constraint(equalTo: thirdCircleView.trailingAnchor, constant: -46.0),
            secondCircleView.bottomAnchor.constraint(equalTo: thirdCircleView.bottomAnchor, constant: -46.0),
            firstCircleView.topAnchor.constraint(equalTo: secondCircleView.topAnchor, constant: 34.0),
            firstCircleView.leadingAnchor.constraint(equalTo: secondCircleView.leadingAnchor, constant: 34.0),
            firstCircleView.trailingAnchor.constraint(equalTo: secondCircleView.trailingAnchor, constant: -34.0),
            firstCircleView.bottomAnchor.constraint(equalTo: secondCircleView.bottomAnchor, constant: -34.0),
            avatarView.topAnchor.constraint(equalTo: firstCircleView.topAnchor, constant: 28.0),
            avatarView.leadingAnchor.constraint(equalTo: firstCircleView.leadingAnchor, constant: 28.0),
            avatarView.trailingAnchor.constraint(equalTo: firstCircleView.trailingAnchor, constant: -28.0),
            avatarView.bottomAnchor.constraint(equalTo: firstCircleView.bottomAnchor, constant: -28.0),
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]

        NSLayoutConstraint.activate(constraints + avatarViewSizeConstraints)
    }

    // MARK: - Actions

    func show() async {

        avatarViewSizeConstraints.forEach { $0.constant = avatarViewHeight }

        await UIView.animate(duration: animationTime, options: [.curveEaseInOut]) {
            self.avatarView.alpha = 1.0
            self.firstCircleView.alpha = 1.0
            self.layoutIfNeeded()
        }

        await UIView.animate(duration: animationTime, options: [.curveEaseInOut]) {
            self.secondCircleView.alpha = 1.0
        }

        await UIView.animate(duration: animationTime, options: [.curveEaseInOut]) {
            self.thirdCircleView.alpha = 1.0
        }
    }

    func hide() async {

        await UIView.animate(duration: animationTime, options: [.curveEaseInOut]) {
            self.thirdCircleView.alpha = 0.0
        }

        await UIView.animate(duration: animationTime, options: [.curveEaseInOut]) {
            self.secondCircleView.alpha = 0.0
        }

        avatarViewSizeConstraints.forEach { $0.constant = avatarViewHeight / 2.0 }

        await UIView.animate(duration: animationTime, options: [.curveEaseInOut]) {
            self.avatarView.alpha = 0.0
            self.firstCircleView.alpha = 0.0
            self.layoutIfNeeded()
        }
    }

    // MARK: - Autolayout

    override func layoutSubviews() {
        super.layoutSubviews()
        firstCircleView.layer.cornerRadius = firstCircleView.bounds.height / 2.0
        secondCircleView.layer.cornerRadius = secondCircleView.bounds.height / 2.0
        thirdCircleView.layer.cornerRadius = thirdCircleView.bounds.height / 2.0
    }
}
