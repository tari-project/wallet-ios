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

enum UserFeedbackTypes {
    case error
    case info
}

class UserFeedback {
    static let shared = UserFeedback()
    private let VERTICAL_OFFSET: CGFloat = 14

    private var defaultAttributes: EKAttributes {
        var attributes = EKAttributes.bottomFloat
        attributes.screenBackground = .color(color: EKColor(Theme.shared.colors.feedbackPopupBackground!))
        attributes.entryBackground = .clear
        attributes.positionConstraints.size = .init(width: .offset(value: VERTICAL_OFFSET), height: .intrinsic)
        attributes.positionConstraints.verticalOffset = VERTICAL_OFFSET
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .forward

        return attributes
    }

    func error(title: String, description: String, error: Error? = nil) {
        let errorFeedbackView = FeedbackView()

        var descriptionText = description
        if let e = error {
            descriptionText.append("\n\(e.localizedDescription)")
        }

        errorFeedbackView.setupError(title: title, description: descriptionText)
        var attributes = defaultAttributes
        attributes.displayDuration = 12
        attributes.hapticFeedbackType = .error

        SwiftEntryKit.display(entry: errorFeedbackView, using: attributes)
    }

    func info(title: String, description: String) {
        let infoFeedbackView = FeedbackView()
        infoFeedbackView.setupInfo(title: title, description: description) {
            SwiftEntryKit.dismiss()
        }

        var attributes = defaultAttributes
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .none
        attributes.entranceAnimation = .init(translate: .init(duration: 0.25, anchorPosition: .bottom, spring: .init(damping: 1, initialVelocity: 0)))

        SwiftEntryKit.display(entry: infoFeedbackView, using: attributes)
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
    }

    func callToAction(title: String, description: String, cancelTitle: String, actionTitle: String, onAction: @escaping () -> Void) {
        let ctaFeedbackView = FeedbackView()
        ctaFeedbackView.setupCallToAction(title: title, description: description, cancelTitle: cancelTitle, actionTitle: actionTitle, onClose: {
            SwiftEntryKit.dismiss()
        }, onAction: onAction)

        var attributes = defaultAttributes
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .success

        SwiftEntryKit.display(entry: ctaFeedbackView, using: attributes)
    }
}
