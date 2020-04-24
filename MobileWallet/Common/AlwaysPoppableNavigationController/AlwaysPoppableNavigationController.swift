//  AlwaysPoppableNavigationController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 23.04.2020
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

class AlwaysPoppableNavigationController: UINavigationController {

    private weak var alwaysPoppableDelegate: AlwaysPoppableDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.alwaysPoppableDelegate = AlwaysPoppableDelegate(navigationController: self, originalDelegate: self.interactivePopGestureRecognizer!.delegate!)
        self.interactivePopGestureRecognizer!.delegate = self.alwaysPoppableDelegate
    }
}

private class AlwaysPoppableDelegate: NSObject, UIGestureRecognizerDelegate {

    weak var navigationController: AlwaysPoppableNavigationController?
    weak var originalDelegate: UIGestureRecognizerDelegate?

    init(navigationController: AlwaysPoppableNavigationController, originalDelegate: UIGestureRecognizerDelegate) {
        self.navigationController = navigationController
        self.originalDelegate = originalDelegate
    }

    // For handling iOS before 13.4
    @objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let navigationController = navigationController, navigationController.isNavigationBarHidden && navigationController.viewControllers.count > 1 {
            return true
        } else if let originalDelegate = originalDelegate {
            return originalDelegate.gestureRecognizer!(gestureRecognizer, shouldReceive: touch)
        } else {
            return false
        }
    }

    // For handling iOS 13.4+
    @objc func _gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveEvent event: UIEvent) -> Bool {
        if let navigationController = navigationController, navigationController.isNavigationBarHidden && navigationController.viewControllers.count > 1 {
            return true
        } else if let originalDelegate = originalDelegate {
            let selector = #selector(_gestureRecognizer(_:shouldReceiveEvent:))
            if originalDelegate.responds(to: selector) {
                let result = originalDelegate.perform(selector, with: gestureRecognizer, with: event)
                return result != nil
            }
        }

        return false
    }

    override func responds(to aSelector: Selector) -> Bool {
        if #available(iOS 13.4, *) {
            // iOS 13.4+ does not need to override responds(to:) behavior, it only uses forwardingTarget
            return originalDelegate?.responds(to: aSelector) ?? false
        } else {
            if aSelector == #selector(gestureRecognizer(_:shouldReceive:)) {
                return true
            } else {
                return originalDelegate?.responds(to: aSelector) ?? false
            }
        }
    }

    override func forwardingTarget(for aSelector: Selector) -> Any? {
        if #available(iOS 13.4, *), aSelector == #selector(_gestureRecognizer(_:shouldReceiveEvent:)) {
            return nil
        } else {
            return self.originalDelegate
        }
    }
}
