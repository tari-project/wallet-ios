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
    
    static var isNavigationReady: Bool { tabBar != nil }
    private static var tabBar: MenuTabBarController? { UIApplication.shared.menuTabBarController }
    
    // MARK: - Transitions

    static func transitionToSplashScreen(window: UIWindow? = UIApplication.shared.windows.first) {
        
        guard let window = window else { return }
        
        BackupScheduler.shared.stopObserveEvents()
        let navigationController = AlwaysPoppableNavigationController(rootViewController: SplashViewController())
        navigationController.setNavigationBarHidden(true, animated: false)
        
        transition(to: navigationController)
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    static func transitionToHomeScreen() {
        DispatchQueue.main.async {
            
            guard let window = UIApplication.shared.windows.first else { return }
            
            let tabBarController = MenuTabBarController()
            let navigationController = AlwaysPoppableNavigationController(rootViewController: tabBarController)
            
            self.transition(to: tabBarController)
            window.rootViewController = navigationController
        }
    }
    
    private static func transition(to controller: UIViewController) {
        
        let snapshot = UIScreen.main.snapshotView(afterScreenUpdates: false)
        controller.view.addSubview(snapshot)
        
        UIView.animate(withDuration: 0.4, delay: 0.0, options: .transitionCrossDissolve, animations: {
            snapshot.alpha = 0.0
        }, completion: { _ in
            snapshot.removeFromSuperview()
        })
    }
    
    // MARK: - TabBar Actions
    
    static func moveToTransactionSend(deeplink: TransactionsSendDeeplink?) {
        tabBar?.homeViewController.onSend(deeplink: deeplink)
    }
    
    static func moveToProfile() {
        tabBar?.setTab(.profile)
    }
}
