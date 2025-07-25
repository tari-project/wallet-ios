//  SecureViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 20/02/2024
	Using Swift 5.0
	Running on macOS 14.2

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

class SecureViewController<MainView: UIView>: UIViewController {

    // MARK: - Views

    var mainView: MainView { secureWrapper.view }

    var screenshotPreventionStatus: ScreenshotPreventionStatus {
        get { secureWrapper.screenshotPreventionStatus }
        set { secureWrapper.screenshotPreventionStatus = newValue }
    }

    private let secureWrapper = SecureWrapperView<MainView>()

    // MARK: - View lifecycle

    override func loadView() {
        view = secureWrapper
        if let mainView = mainView as? BaseNavigationContentView {
            mainView.navigationBar.onBackButtonAction = { [weak self] in
                if let navigationController = self?.navigationController {
                    navigationController.popViewController(animated: true)
                } else {
                    self?.dismiss(animated: true)
                }
            }
        }
    }
}
