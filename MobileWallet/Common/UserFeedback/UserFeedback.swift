//  UserFeedback.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/23
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

import Foundation
import SwiftEntryKit

class UserFeedback {
    static let shared = UserFeedback()
    private let VERTICAL_OFFSET: CGFloat = hasNotch ? -14 : 14
    private let SIDE_OFFSET: CGFloat = 14

    private var defaultAttributes: EKAttributes {
        var attributes = EKAttributes.bottomFloat
        attributes.screenBackground = .color(color: EKColor(Theme.shared.colors.feedbackPopupBackground!))
        attributes.entryBackground = .clear
        attributes.positionConstraints.size = .init(width: .offset(value: SIDE_OFFSET), height: .intrinsic)
        attributes.positionConstraints.verticalOffset = VERTICAL_OFFSET
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .forward

        return attributes
    }

    private func closeKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIApplication.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    func error(title: String, description: String, error: Error? = nil, onClose: (() -> Void)? = nil) {
        let errorFeedbackView = FeedbackView()

        var descriptionText = description
        if TariSettings.shared.environment == .debug, let e = error {
            descriptionText.append("\n\(e.localizedDescription)")
        }

        if onClose == nil {
            errorFeedbackView.setupError(title: title, description: descriptionText)
        } else {
            errorFeedbackView.setupError(title: title, description: descriptionText, onClose: {
                SwiftEntryKit.dismiss()
                onClose?()
            })
        }

        var attributes = defaultAttributes
        attributes.displayDuration = onClose == nil ? 12 : .infinity
        attributes.hapticFeedbackType = .error
        attributes.screenInteraction =  onClose == nil ? .dismiss : .absorbTouches

        SwiftEntryKit.display(entry: errorFeedbackView, using: attributes)
        closeKeyboard()
        TariLogger.error("User feedback: title=\(title) description=\(description)", error: error)
    }

    func info(title: String, description: String) {
        let infoFeedbackView = FeedbackView()
        infoFeedbackView.setupInfo(title: title, description: description) {
            SwiftEntryKit.dismiss()
        }

        var attributes = defaultAttributes
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .none
        attributes.screenInteraction = .dismiss
        attributes.entranceAnimation = .init(translate: .init(duration: 0.25, anchorPosition: .bottom, spring: .init(damping: 1, initialVelocity: 0)))

        SwiftEntryKit.display(entry: infoFeedbackView, using: attributes)
        closeKeyboard()
        TariLogger.verbose("User feedback: title=\(title) description=\(description)")
    }

    func success(title: String) {
        let successFeedbackView = FeedbackView()
        successFeedbackView.setupSuccess(title: title)
        var attributes = EKAttributes.topToast

        attributes.entryBackground = .color(color: EKColor(Theme.shared.colors.successFeedbackPopupBackground!))
        attributes.screenBackground = .clear
        attributes.shadow = .active(with: .init(color: EKColor(Theme.shared.colors.feedbackPopupBackground!), opacity: 0.35, radius: 10, offset: .zero))
        attributes.displayDuration = 2
        attributes.hapticFeedbackType = .success
        attributes.screenInteraction = .forward

        SwiftEntryKit.display(entry: successFeedbackView, using: attributes)
        closeKeyboard()
        TariLogger.verbose("User success feedback: title=\(title)")
    }

    func callToAction(title: String, boldedTitle: String? = nil, description: String, actionTitle: String, cancelTitle: String, onAction: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        let ctaFeedbackView = FeedbackView()
        ctaFeedbackView.setupCallToAction(
            title: title,
            boldedTitle: boldedTitle,
            description: description,
            cancelTitle: cancelTitle,
            actionTitle: actionTitle,
            onClose: {
                SwiftEntryKit.dismiss()
                onCancel?()
            }, onAction: {
                SwiftEntryKit.dismiss()
                onAction()
            }
        )

        var attributes = defaultAttributes
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .success
        attributes.screenInteraction = .absorbTouches

        SwiftEntryKit.display(entry: ctaFeedbackView, using: attributes)
        closeKeyboard()
        TariLogger.verbose("User call to action: title=\(title) description=\(description)")
    }

    func acceptUserInput(title: String, cancelTitle: String, actionTitle: String, inputs: [UserFeedbackFormInput], onSubmit: @escaping ([String: String]) -> Void) {
        let successFeedbackView = FeedbackView()
        successFeedbackView.setupForm(
            title: title,
            cancelTitle: cancelTitle,
            actionTitle: actionTitle,
            inputs: inputs,
            onClose: {
                SwiftEntryKit.dismiss()
            }, onSubmit: onSubmit)

        var attributes = EKAttributes.float

        attributes.screenBackground = .visualEffect(style: .dark)
        attributes.shadow = .active(with: .init(color: EKColor(Theme.shared.colors.feedbackPopupBackground!), opacity: 0.35, radius: 10, offset: .zero))
        attributes.displayDuration = .infinity
        attributes.screenInteraction = .absorbTouches
        attributes.entryInteraction = .absorbTouches

        SwiftEntryKit.display(entry: successFeedbackView, using: attributes)
        closeKeyboard()
        TariLogger.verbose("User call accept user input: title=\(title)")
    }

    // MARK: - Custom pop ups
    func callToActionStore() {
        let imageTop: CGFloat = 55 //Distance image should stick out by
        let containerView = UIView()
        let ctaFeedbackView = FeedbackView()
        ctaFeedbackView.setupCallToActionDetailed(
            containerView: containerView,
            image: Theme.shared.images.storeModal!,
            imageTop: imageTop,
            title: String(
                format: NSLocalizedString(
                    "store_modal.title.with_param",
                    comment: "Store modal"
                ),
                TariSettings.shared.network.currencyDisplayTicker
            ),
            boldedTitle: NSLocalizedString("store_modal.bold_title", comment: "Store modal"),
            description: String(
                format: NSLocalizedString(
                    "store_modal.description",
                    comment: "Store modal"
                ),
                TariSettings.shared.network.currencyDisplayTicker
            ),
            cancelTitle: NSLocalizedString("store_modal.cancel", comment: "Store modal"),
            actionTitle: NSLocalizedString("store_modal.action", comment: "Store modal"),
            actionIcon: Theme.shared.images.storeIcon!,
            onClose: {
                SwiftEntryKit.dismiss()
            }) { [weak self] in
                SwiftEntryKit.dismiss()
                guard let url = URL(string: TariSettings.shared.storeUrl) else {
                    return
                }
                self?.openWebBrowser(url: url)
                TariLogger.verbose("Opened store link")
            }

        ctaFeedbackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(ctaFeedbackView)
        ctaFeedbackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: imageTop).isActive = true
        ctaFeedbackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        ctaFeedbackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        ctaFeedbackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

        var attributes = defaultAttributes
        attributes.displayDuration = .infinity
        attributes.screenInteraction = .dismiss

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        SwiftEntryKit.display(entry: containerView, using: attributes)
        closeKeyboard()
        TariLogger.verbose("User call to action store")
    }

    func showDebugConnectionStatus() {
        let infoFeedbackView = FeedbackView()

        let setupView = {
            infoFeedbackView.setupInfo(title: "Connection status", description: ConnectionMonitor.shared.state.formattedDisplayItems.joined(separator: "\n\n")) {
                SwiftEntryKit.dismiss()
                TariEventBus.unregister(self, eventType: .connectionMonitorStatusChanged)
            }
        }

        setupView()
        TariEventBus.onMainThread(self, eventType: .connectionMonitorStatusChanged) { (_) in
            setupView()
        }

        var attributes = defaultAttributes
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .none
        attributes.screenInteraction = .dismiss
        attributes.entranceAnimation = .init(translate: .init(duration: 0.25, anchorPosition: .bottom, spring: .init(damping: 1, initialVelocity: 0)))

        SwiftEntryKit.display(entry: infoFeedbackView, using: attributes)
        closeKeyboard()
    }

    func openWebBrowser(url: URL) {
        guard let topController = UIApplication.shared.topController() else { return }
        let webBrowserViewController = WebBrowserViewController()
        webBrowserViewController.url = url
        webBrowserViewController.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .automatic :.popover
        topController.present(webBrowserViewController, animated: true)
    }
}
