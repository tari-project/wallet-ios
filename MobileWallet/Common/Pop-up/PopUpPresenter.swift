//  PopUpPresenter.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 10/04/2022
	Using Swift 5.0
	Running on macOS 12.3

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
import SwiftEntryKit

enum PopUpPresenter {

    enum HapticType {
        case success
        case error
        case none
    }

    struct Configuration {
        let displayDuration: TimeInterval?
        let dismissOnTapOutsideOrSwipe: Bool
        let hapticType: HapticType
    }

    // MARK: - Properties

    private static let sideOffset = 14.0
    private static let verticalOffset = hasNotch ? -14.0 : 14.0

    private static let defaultAttributes: EKAttributes = {
        var attributes = EKAttributes.bottomFloat
        attributes.entryBackground = .clear

        if let overlayColor = UIColor.static.popupOverlay {
            attributes.screenBackground = .color(color: EKColor(overlayColor))
        }

        attributes.positionConstraints.size = EKAttributes.PositionConstraints.Size(width: .offset(value: sideOffset), height: .intrinsic)
        attributes.positionConstraints.verticalOffset = verticalOffset
        attributes.screenInteraction = .absorbTouches
        attributes.entryInteraction = .forward
        attributes.displayDuration = .infinity
        attributes.precedence = .enqueue(priority: .normal)
        return attributes
    }()

    // MARK: - Actions

    @MainActor static func show(popUp: TariPopUp, configuration: Configuration? = nil, tag: String? = nil) {

        var attributes = defaultAttributes
        attributes.name = tag

        if let configuration = configuration {
            attributes.displayDuration = configuration.displayDuration ?? .infinity
            attributes.screenInteraction = configuration.dismissOnTapOutsideOrSwipe ? .dismiss : .absorbTouches
            attributes.scroll = configuration.dismissOnTapOutsideOrSwipe ? .enabled(swipeable: true, pullbackAnimation: .easeOut) : .disabled
            attributes.hapticFeedbackType = makeHapticFeedbackType(configuration: configuration)
        }

        SwiftEntryKit.display(entry: popUp, using: attributes)
        UIApplication.shared.hideKeyboard()
    }

    static func dismissPopup(tag: String? = nil, onCompletion: (() -> Void)? = nil) {

        let dismissalDescriptor: SwiftEntryKit.EntryDismissalDescriptor

        if let tag {
            dismissalDescriptor = .specific(entryName: tag)
        } else {
            dismissalDescriptor = .displayed
        }

        SwiftEntryKit.dismiss(dismissalDescriptor) {
            onCompletion?()
        }
    }

    static func layoutIfNeeded() {
        SwiftEntryKit.layoutIfNeeded()
    }

    // MARK: - Helpers

    private static func makeHapticFeedbackType(configuration: Configuration) -> EKAttributes.NotificationHapticFeedback {
        switch configuration.hapticType {
        case .none:
            return .none
        case .success:
            return .success
        case .error:
            return .error
        }
    }
}
