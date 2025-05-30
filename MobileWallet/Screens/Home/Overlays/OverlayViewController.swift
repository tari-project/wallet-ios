//  OverlayViewController.swift

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

class FadeOutAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    // Duration of the animation
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)
    -> TimeInterval {
        return 0.45
    }

    // The actual fade-out animation
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 'fromView' is the modal being dismissed
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let fromView = fromVC.view
        else {
            return
        }

        let duration = transitionDuration(using: transitionContext)

        UIView.animate(withDuration: duration, animations: {
            fromView.alpha = 0
        }, completion: { _ in
            // Clean up and notify the system that the transition is complete
            fromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

class FadeInAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    // Duration of the animation
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)
    -> TimeInterval {
        return 0.45
    }

    // The actual fade-out animation
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 'fromView' is the modal being dismissed
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let fromView = fromVC.view
        else {
            return
        }

        let duration = transitionDuration(using: transitionContext)

        UIView.animate(withDuration: duration, animations: {
            fromView.alpha = 1
        }, completion: { _ in
            // Clean up and notify the system that the transition is complete
            fromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

class OverlayViewController: SecureViewController<OverlayView> {
    var onCloseButtonTap: (() -> Void)?
    var onPromptButtonTap: (() -> Void)?
    var onNoPromptClose: (() -> Void)?
    var onStartMiningButtonTap: (() -> Void)?

    // Track these with static properties that exist only for the app session
    private static var wasDisclaimerShown = false

    var activeOverlay: Overlay = .synced
    var totalBalance: String = ""
    var availableBalance: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Handle only disclaimer overlay specifically - it should only show once unless explicitly requested
        if activeOverlay == .disclaimer {
            let shouldShowDisclaimer = UserDefaults.standard.bool(forKey: "ShouldShowDisclaimerOverlay")
            if !shouldShowDisclaimer {
                self.onCloseButtonTap?()
                return
            }
            // Set flag to false after showing disclaimer
            UserDefaults.standard.set(false, forKey: "ShouldShowDisclaimerOverlay")
        }
        // Welcome overlays (restored/synced) are controlled by the flags in HomeViewController
        // Mining overlay always shows when requested
        // Notification overlay is handled by NotificationManager

        mainView.showOverlay(for: activeOverlay, animated: false)
        mainView.disclaimerView.totalBalance = totalBalance
        mainView.disclaimerView.availableBalance = availableBalance

        mainView.onCloseButtonTap = { [weak self] in
            if self?.activeOverlay == .restored || self?.activeOverlay == .synced || self?.activeOverlay == .none {
                NotificationManager.shared.shouldPromptForNotifications { show in
                    DispatchQueue.main.async {
                        if show {
                            self?.mainView.showOverlay(for: .notifications, animated: true)
                        } else {
                            self?.onCloseButtonTap?()
                        }
                    }
                }
            } else {
                self?.onCloseButtonTap?()
            }
        }

        mainView.onSkipAfterDelay = { [weak self] in
            if self?.activeOverlay == .restored || self?.activeOverlay == .synced || self?.activeOverlay == .none {
                NotificationManager.shared.shouldPromptForNotifications { show in
                    DispatchQueue.main.async {
                        if show {
                            self?.mainView.showOverlay(for: .notifications, animated: true)
                        } else {
                            self?.onCloseButtonTap?()
                        }
                    }
                }
            } else {
                self?.onCloseButtonTap?()
            }
        }

        mainView.onCloseNotificationsButtonTap = { [weak self] in
            self?.onCloseButtonTap?()
        }

        mainView.onPromptButtonTap = { [weak self] in
            self?.onPromptButtonTap?()
        }

        mainView.onStartMiningButtonTap = { [weak self] in
            self?.onStartMiningButtonTap?()
        }

        mainView.disclaimerView.onCloseButtonTap = { [weak self] in
            self?.onCloseButtonTap?()
        }
    }
}

extension OverlayViewController: UIViewControllerTransitioningDelegate {

    // Return nil for presenting if you want the default animation, or provide a custom animator too
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        return FadeInAnimator()
    }

    // Provide your custom animator for dismiss
    func animationController(forDismissed dismissed: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        return FadeOutAnimator()
    }
}
