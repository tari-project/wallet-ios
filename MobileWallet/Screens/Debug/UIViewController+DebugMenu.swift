//  UIViewController+DebugMenu.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 13/10/2022
	Using Swift 5.0
	Running on macOS 12.6

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
import SwiftUI

extension UIViewController {

    // MARK: - Motion

    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        guard motion == .motionShake, self == UIApplication.shared.topController else { return }
        handleShakeGesture()
    }

    // MARK: - Actions

    private func handleShakeGesture() {
        let headerSection = PopUpHeaderView()
        let contentSection = PopUpButtonsTableView()
        let buttonsSection = PopUpButtonsView()

        headerSection.label.text = localized("debug.popup.title")

        contentSection.update(options: [
            localized("debug.popup.options.designs"),
            "New Design System",
            localized("debug.popup.options.logs"),
            localized("debug.popup.options.bug_report")
        ])

        contentSection.onSelectedRow = { [weak self] in self?.handle(selectedIndexPath: $0) }
        contentSection.update(footer: AppVersionFormatter.version)
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.cancel"), type: .text, callback: { PopUpPresenter.dismissPopup() }))

        PopUpPresenter.show(popUp: TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection), configuration: .dialog(hapticType: .none))
    }

    private func handle(selectedIndexPath: IndexPath) {
        PopUpPresenter.dismissPopup()

        switch selectedIndexPath.row {
        case 0:
            moveToDesignsScene()
        case 1:
            moveToNewDesignsScene()
        case 2:
            moveToLogsScene()
        case 3:
            moveToReportBugScene()
        default:
            break
        }
    }

    private func moveToLogsScene() {
        if navigationController?.topViewController is LogsListViewController { return }
        let logsViewController = LogsListConstructor.buildScene()
        let navigationController = AlwaysPoppableNavigationController(rootViewController: logsViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        present(navigationController, animated: true)
    }

    private func moveToDesignsScene() {
        if navigationController?.topViewController is DesignSystemViewController { return }
        let designViewController = DesignSystemViewController()
        let navigationController = AlwaysPoppableNavigationController(rootViewController: designViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        present(navigationController, animated: true)
    }
    
    private func moveToNewDesignsScene() {
        if navigationController?.topViewController is UIHostingController<NewDesignSystem> { return }
        let designViewController = UIHostingController(rootView: NewDesignSystem())
        let navigationController = AlwaysPoppableNavigationController(rootViewController: designViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        present(navigationController, animated: true)
    }

    private func moveToReportBugScene() {
        let controller = BugReportingConstructor.buildScene()
        present(controller, animated: true)
    }
}
