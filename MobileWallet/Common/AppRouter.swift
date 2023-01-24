//  AppRouter.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 02/09/2021
	Using Swift 5.0
	Running on macOS 12.0

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

enum AppRouter {

    private enum TransitionType {
        case moveDown
        case crossDissolve
        case none
    }

    static var isNavigationReady: Bool { tabBar != nil }
    private static var tabBar: MenuTabBarController? { UIApplication.shared.menuTabBarController }

    // MARK: - Transitions

    static func transitionToSplashScreen(animated: Bool = true, isWalletConnected: Bool = false) {

        let controller = SplashViewConstructor.buildScene(isWalletConnected: isWalletConnected)
        let navigationController = AlwaysPoppableNavigationController(rootViewController: controller)
        navigationController.setNavigationBarHidden(true, animated: false)

        transition(to: navigationController, type: animated ? .moveDown : .none)
    }

    static func transitionToOnboardingScreen(startFromLocalAuth: Bool) {

        let controller = WalletCreationViewController()
        controller.startFromLocalAuth = startFromLocalAuth

        transition(to: controller, type: .moveDown)
    }

    static func transitionToHomeScreen() {

        let tabBarController = MenuTabBarController()
        let navigationController = AlwaysPoppableNavigationController(rootViewController: tabBarController)

        transition(to: navigationController, type: .crossDissolve)
    }

    private static func transition(to controller: UIViewController, type: TransitionType) {

        guard let window = UIApplication.shared.windows.first else { return }

        guard type != .none else {
            window.rootViewController = controller
            return
        }

        let snapshot = UIScreen.main.snapshotView(afterScreenUpdates: false)
        controller.view.addSubview(snapshot)

        window.rootViewController = controller

        UIView.animate(
            withDuration: 0.4,
            animations: { update(snapshot: snapshot, controller: controller, transitionType: type) },
            completion: { _ in snapshot.removeFromSuperview() }
        )
    }

    private static func update(snapshot: UIView, controller: UIViewController, transitionType: TransitionType) {

        switch transitionType {
        case .moveDown:
            snapshot.frame.origin.y = controller.view.bounds.maxY
        case .crossDissolve:
            snapshot.alpha = 0.0
        case .none:
            return
        }
    }

    // MARK: - TabBar Actions

    static func moveToTransactionSend(deeplink: TransactionsSendDeeplink?) {
        tabBar?.homeViewController.onSend(deeplink: deeplink)
    }

    static func moveToProfile() {
        tabBar?.setTab(.profile)
    }

    // MARK: - Modal Actions

    static func presentVerifiySeedPhrase() {

        let controller = SeedWordsListConstructor.buildScene(backButtonType: .close)
        let navigationController = AlwaysPoppableNavigationController(rootViewController: controller)

        navigationController.setNavigationBarHidden(true, animated: false)
        tabBar?.present(navigationController, animated: true)
    }

    static func presentBackupSettings() {

        let controller = BackupWalletSettingsConstructor.buildScene(backButtonType: .close)
        let navigationController = AlwaysPoppableNavigationController(rootViewController: controller)

        navigationController.setNavigationBarHidden(true, animated: false)
        tabBar?.present(navigationController, animated: true)
    }

    static func presentBackupPasswordSettings() {

        let controller = SecureBackupViewController(backButtonType: .close)
        let navigationController = AlwaysPoppableNavigationController(rootViewController: controller)

        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.isModalInPresentation = true
        tabBar?.present(navigationController, animated: true)
    }
}
