//  UIViewController.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/28
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

var navBarEmojis: EmoticonView?

var hasNotch: Bool {
    let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
    return bottom > 0
}

extension UIViewController {
    func hideKeyboardWhenTappedAroundOrSwipedDown() {
        hideKeyboardWhenTappedAroundOrSwipedDown(view: view)
    }

    func hideKeyboardWhenTappedAroundOrSwipedDown(view: UIView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        swipeDown.direction = UISwipeGestureRecognizer.Direction.down
        view.addGestureRecognizer(swipeDown)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc var navBarHeight: CGFloat {
        return (UIApplication.shared.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }

    func setNavigationBarLeftCloseButton(action: Selector) {
        let closeButtonItem = UIBarButtonItem.customNavBarItem(target: self, image: Theme.shared.images.close!, action: action)
        navigationItem.leftBarButtonItem = closeButtonItem
    }

    func styleNavigatorBar(isHidden: Bool, animated: Bool = false) {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)

        if let navController = navigationController {
            let navBar = navController.navigationBar

            navBar.barTintColor = Theme.shared.colors.navigationBarBackground
            navBar.titleTextAttributes = [NSAttributedString.Key.font: Theme.shared.fonts.navigationBarTitle]
            navBar.setBackgroundImage(UIImage(color: Theme.shared.colors.navigationBarBackground!), for: .default)
            navBar.isTranslucent = true
            navBar.tintColor = Theme.shared.colors.navigationBarTint

            navBar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.navigationBarTint!,
                NSAttributedString.Key.font: Theme.shared.fonts.navigationBarTitle
            ]

            //Remove border
            navBar.shadowImage = UIImage()

            //TODO fix size
            navBar.backIndicatorImage = Theme.shared.images.backArrow
            navBar.backIndicatorTransitionMaskImage = Theme.shared.images.backArrow

            navController.setNavigationBarHidden(isHidden, animated: animated)
        }
    }
}
