//  RotaryMenuOverlayView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 09/06/2023
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

final class RotaryMenuOverlayView: UIView {

    enum PresentationSide {
        case left
        case right
    }

    // MARK: - Subviews

    @View private var backgroundView = RotaryMenuCircleBackgroundView()
    @View private var rotaryMenu = RotaryMenuView()

    @View private var switchSideButton: RoundedButton = {
        let view = RoundedButton()
        view.setImage(.icons.rotaryMenu.switchSide, for: .normal)
        view.backgroundColor = .static.white?.withAlphaComponent(0.4)
        view.tintColor = .static.black
        view.alpha = 0.0
        return view
    }()

    @View private var closeButton: RoundedButton = {
        let view = RoundedButton()
        view.setImage(.icons.rotaryMenu.close, for: .normal)
        view.backgroundColor = .static.white?.withAlphaComponent(0.8)
        view.tintColor = .static.black
        view.alpha = 0.0
        return view
    }()

    // MARK: - Properties

    var models: [RotaryMenuView.MenuButtonViewModel] = []

    var avatar: RoundedAvatarView.Avatar {
        get { backgroundView.avatar }
        set { backgroundView.avatar = newValue }
    }

    var onMenuButtonTap: ((UInt) -> Void)?
    var onCloseButtonTap: (() -> Void)?
    var onSwitchSideButtonTap: (() -> Void)?

    private(set) var presentationSide: PresentationSide
    private var previousTouchLocation: CGPoint?

    private var rotationAngle: CGFloat = 0.0 {
        didSet { rotaryMenu.transform = CGAffineTransform(rotationAngle: rotationAngle) }
    }

    private var leftSidePresentationConstraints: [NSLayoutConstraint] = []
    private var rightSidePresentationConstraints: [NSLayoutConstraint] = []

    // MARK: - Initalisers

    init(presentationSide: PresentationSide) {
        self.presentationSide = presentationSide
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        setupGestures()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        backgroundColor = .static.popupOverlay
    }

    private func setupConstraints() {

        [backgroundView, rotaryMenu, switchSideButton, closeButton].forEach(addSubview)

        leftSidePresentationConstraints = [
            backgroundView.centerXAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),
            rotaryMenu.centerXAnchor.constraint(equalTo: leadingAnchor),
            rotaryMenu.centerYAnchor.constraint(equalTo: centerYAnchor),
            rotaryMenu.widthAnchor.constraint(equalTo: backgroundView.widthAnchor),
            rotaryMenu.heightAnchor.constraint(equalTo: backgroundView.heightAnchor),
            switchSideButton.centerXAnchor.constraint(equalTo: trailingAnchor),
            switchSideButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            switchSideButton.widthAnchor.constraint(equalToConstant: 62.0),
            switchSideButton.heightAnchor.constraint(equalToConstant: 62.0),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -25.0),
            closeButton.widthAnchor.constraint(equalToConstant: 40.0),
            closeButton.heightAnchor.constraint(equalToConstant: 40.0)
        ]

        rightSidePresentationConstraints = [
            backgroundView.centerXAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),
            rotaryMenu.centerXAnchor.constraint(equalTo: trailingAnchor),
            rotaryMenu.centerYAnchor.constraint(equalTo: centerYAnchor),
            rotaryMenu.widthAnchor.constraint(equalTo: backgroundView.widthAnchor),
            rotaryMenu.heightAnchor.constraint(equalTo: backgroundView.heightAnchor),
            switchSideButton.centerXAnchor.constraint(equalTo: leadingAnchor),
            switchSideButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            switchSideButton.widthAnchor.constraint(equalToConstant: 62.0),
            switchSideButton.heightAnchor.constraint(equalToConstant: 62.0),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -25.0),
            closeButton.widthAnchor.constraint(equalToConstant: 40.0),
            closeButton.heightAnchor.constraint(equalToConstant: 40.0)
        ]

        switch presentationSide {
        case .left:
            NSLayoutConstraint.activate(leftSidePresentationConstraints)
        case .right:
            NSLayoutConstraint.activate(rightSidePresentationConstraints)
        }
    }

    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))
        addGestureRecognizer(panGesture)
    }

    private func setupCallbacks() {

        rotaryMenu.onButtonTap = { [weak self] in
            self?.onMenuButtonTap?($0)
        }

        closeButton.onTap = { [weak self] in
            self?.onCloseButtonTap?()
        }

        switchSideButton.onTap = { [weak self] in
            self?.onSwitchSideButtonTap?()
        }
    }

    // MARK: - Updates

    private func updateBackgroundViewsLayout() {

        NSLayoutConstraint.deactivate(leftSidePresentationConstraints)
        NSLayoutConstraint.deactivate(rightSidePresentationConstraints)

        switch presentationSide {
        case .left:
            NSLayoutConstraint.activate(leftSidePresentationConstraints)
        case .right:
            NSLayoutConstraint.activate(rightSidePresentationConstraints)
        }
    }

    private func updateButtons() {
        rotaryMenu.update(buttonViewModels: models, iconLocation: presentationSide.iconLocation)
    }

    private func updateAngle(newLocation: CGPoint) {

        guard let previousTouchLocation else { return }

        let centerPoint = rotaryMenu.center

        let xValue = (newLocation.x - centerPoint.x) * (previousTouchLocation.x - centerPoint.x) + (newLocation.y - centerPoint.y) * (previousTouchLocation.y - centerPoint.y)
        let yValue = (newLocation.x - centerPoint.x) * (previousTouchLocation.y - centerPoint.y) - (newLocation.y - centerPoint.y) * (previousTouchLocation.x - centerPoint.x)
        let angle = atan2(xValue, yValue) - (.pi / 2.0)

        rotationAngle += angle
    }

    // MARK: - Actions

    func show() async {
        rotationAngle = 0.0
        updateBackgroundViewsLayout()
        updateButtons()
        await backgroundView.show()
        await rotaryMenu.show()
        updateButtons(areVisible: true)
    }

    func hide() async {
        updateButtons(areVisible: false)
        await rotaryMenu.hide()
        await backgroundView.hide()
    }

    func switchSide(presentationSide: PresentationSide) async {
        self.presentationSide = presentationSide
        await hide()
        await show()
    }

    private func updateButtons(areVisible: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseInOut]) {
            self.switchSideButton.alpha = areVisible ? 1.0 : 0.0
            self.closeButton.alpha = areVisible ? 1.0 : 0.0
        }
    }

    private func springBack() {
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.0, options: [.curveEaseInOut]) {
            self.rotationAngle = 0.0
        }
    }

    // MARK: - Handlers

    @objc private func handle(panGesture: UIPanGestureRecognizer) {

        let location = panGesture.location(in: self)

        switch panGesture.state {
        case .began:
            previousTouchLocation = location
        case .changed:
            updateAngle(newLocation: location)
            previousTouchLocation = location
        case .cancelled, .ended:
            previousTouchLocation = nil
            springBack()
        default:
            break
        }
    }
}

private extension RotaryMenuOverlayView.PresentationSide {

    var iconLocation: RotaryMenuButton.IconLocation {
        switch self {
        case .left:
            return .left
        case .right:
            return .right
        }
    }
}
