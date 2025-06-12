//  OverlayView.swift

/*
	Package MobileWallet
	Created by Konrad Faltyn on 03/03/2025
	Using Swift 6.0
	Running on macOS 15.3

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

enum Overlay {
    case restored
    case synced
    case notifications
    case startMining
    case disclaimer
}

class OverlayView: UIView {

    var onCloseButtonTap: (() -> Void)?
    var onSkipAfterDelay: (() -> Void)?

    var onCloseNotificationsButtonTap: (() -> Void)? {
        didSet {
            notificationView.onCloseButtonTap = onCloseNotificationsButtonTap
        }
    }

    var onPromptButtonTap: (() -> Void)? {
        didSet {
            notificationView.onPromptButtonTap = onPromptButtonTap
        }
    }

    var onStartMiningButtonTap: (() -> Void)? {
        didSet {
            miningView.onSendMiningLinkTap = onStartMiningButtonTap
        }
    }

    @View private var blurrView: UIView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false

        return blurView
    }()

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        onCloseButtonTap?()
    }

    @objc func handleViewTap(_ sender: UITapGestureRecognizer) {
        onCloseButtonTap?()
    }

    @View private var welcomeView: WelcomeView = {
        return WelcomeView()
    }()

    @View private var notificationView: NotificationsView = {
        return NotificationsView()
    }()

    @View private var miningView: MiningView = {
        return MiningView()
    }()

    @View var disclaimerView: DisclaimerView = {
        return DisclaimerView()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func setupViews() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)

        blurrView.alpha = 0.7
        translatesAutoresizingMaskIntoConstraints = false

        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        blurrView.addGestureRecognizer(backgroundTapGesture)

        let viewTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTap(_:)))
        viewTapGesture.cancelsTouchesInView = false
        viewTapGesture.delegate = self
        addGestureRecognizer(viewTapGesture)

        setupConstraints()
    }

    private func setupConstraints() {

        [blurrView, welcomeView, notificationView, miningView, disclaimerView].forEach(addSubview)

        let constraints = [
            blurrView.leftAnchor.constraint(equalTo: leftAnchor),
            blurrView.rightAnchor.constraint(equalTo: rightAnchor),
            blurrView.topAnchor.constraint(equalTo: topAnchor),
            blurrView.bottomAnchor.constraint(equalTo: bottomAnchor),
            welcomeView.bottomAnchor.constraint(equalTo: bottomAnchor),
            welcomeView.leftAnchor.constraint(equalTo: leftAnchor),
            welcomeView.rightAnchor.constraint(equalTo: rightAnchor),
            welcomeView.heightAnchor.constraint(equalToConstant: 594),
            notificationView.bottomAnchor.constraint(equalTo: bottomAnchor),
            notificationView.leftAnchor.constraint(equalTo: leftAnchor),
            notificationView.rightAnchor.constraint(equalTo: rightAnchor),
            notificationView.heightAnchor.constraint(equalToConstant: 594),
            miningView.bottomAnchor.constraint(equalTo: bottomAnchor),
            miningView.leftAnchor.constraint(equalTo: leftAnchor),
            miningView.rightAnchor.constraint(equalTo: rightAnchor),
            miningView.heightAnchor.constraint(equalToConstant: 594),
            disclaimerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            disclaimerView.leftAnchor.constraint(equalTo: leftAnchor),
            disclaimerView.rightAnchor.constraint(equalTo: rightAnchor),
            disclaimerView.heightAnchor.constraint(equalToConstant: 270)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    public func showOverlay(for overlay: Overlay, animated: Bool) {
        switch overlay {
            case .notifications:
                notificationView.isHidden = false
                welcomeView.isHidden = true
                miningView.isHidden = true
                disclaimerView.isHidden = true
            case .restored:
                notificationView.isHidden = true
                welcomeView.isHidden = false
                welcomeView.isPaperWalletRestored = false
                miningView.isHidden = true
                disclaimerView.isHidden = true
            case .synced:
                notificationView.isHidden = true
                welcomeView.isHidden = false
                welcomeView.isPaperWalletRestored = true
                miningView.isHidden = true
                disclaimerView.isHidden = true
            case .startMining:
                notificationView.isHidden = true
                welcomeView.isHidden = true
                miningView.isHidden = false
                disclaimerView.isHidden = true
            case .disclaimer:
                notificationView.isHidden = true
                welcomeView.isHidden = true
                miningView.isHidden = true
                disclaimerView.isHidden = false
        }

        if overlay == .synced || overlay == .restored {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if overlay == .synced || overlay == .restored {
                    self.onSkipAfterDelay?()
                }
            }
        }
        // animations
    }
}

// MARK: - UIGestureRecognizerDelegate
extension OverlayView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't handle taps on buttons or other interactive elements
        if touch.view is UIButton || touch.view is StylisedButton || touch.view?.isDescendant(of: welcomeView.subviews.first ?? UIView()) == true ||
           touch.view?.isDescendant(of: notificationView.subviews.first ?? UIView()) == true ||
           touch.view?.isDescendant(of: miningView.subviews.first ?? UIView()) == true ||
           touch.view?.isDescendant(of: disclaimerView.subviews.first ?? UIView()) == true {
            return false
        }
        return true
    }
}
