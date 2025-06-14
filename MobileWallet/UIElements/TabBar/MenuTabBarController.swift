//  MenuTabBarController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 22.07.2020
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

final class MenuTabBarController: UITabBarController {

    enum Tab: Int {
        case home
        case profile
        case settings
    }

    public var walletState: AppRouter.WalletState = .current {
        didSet {
            // ALWAYS set default to false first
            homeViewController.showWalletSyncedOnPresentation = false
            homeViewController.showWalletRestoredOnPresentation = false

            // Only when a wallet is explicitly created or restored AND flag is true, show welcome overlay
            let shouldShowWelcome = UserDefaults.standard.bool(forKey: "ShouldShowWelcomeOverlay")

            if shouldShowWelcome && (walletState == .newSynced || walletState == .newRestored) {
                // Set the presentation flags based on wallet state
                homeViewController.showWalletSyncedOnPresentation = walletState == .newSynced
                homeViewController.showWalletRestoredOnPresentation = walletState == .newRestored
            }
        }
    }

    private let homeViewController = HomeConstructor.buildScene()
    private let storeViewController = WebBrowserViewController()
    private let contactBookViewController = ProfileViewController()
    private let settingsViewController = SettingsViewController()
    private let customTabBar = CustomTabBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        setValue(customTabBar, forKey: "tabBar")
        self.delegate = self
        tabBar.isTranslucent = false

        storeViewController.url = URL(string: TariSettings.shared.storeUrl)

        viewControllers = [homeViewController, contactBookViewController, settingsViewController]
        viewControllers?.enumerated().forEach { setup(controller: $1, index: $0) }

        for tabBarItem in tabBar.items! {
            if hasNotch { // On phones without notches the icons should stay vertically centered
                tabBarItem.imageInsets = UIEdgeInsets(top: 13, left: 0, bottom: -13, right: 0)
            }
        }
    }

    override var childForStatusBarStyle: UIViewController? {
        return selectedViewController?.childForStatusBarStyle ?? selectedViewController
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func setTab(_ tab: Tab) {
        selectedIndex = tab.rawValue
    }

    private func setup(controller: UIViewController, index: Int) {
        guard let tab = Tab(rawValue: index) else { return }
        controller.tabBarItem.tag = tab.rawValue
        controller.tabBarItem.image = tab.icon?.withRenderingMode(.alwaysTemplate)
        controller.tabBarItem.selectedImage = tab.selectedIcon?.withRenderingMode(.alwaysTemplate)
    }
}

extension MenuTabBarController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {

//        guard Tab(rawValue: viewController.tabBarItem.tag) == .transactions else { return true }

//        let controller = TransactionsConstructor.buildScene()
//        let navigationController = AlwaysPoppableNavigationController(rootViewController: controller)
//        navigationController.setNavigationBarHidden(true, animated: false)
//        navigationController.modalPresentationStyle = .fullScreen
//        present(navigationController, animated: true)

//        return false

        return true
    }

    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return TabBarTransition(viewControllers: tabBarController.viewControllers)
    }
}

private class TabBarTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let viewControllers: [UIViewController]?
    let transitionDuration: Double = CATransaction.animationDuration()

    init(viewControllers: [UIViewController]?) {
        self.viewControllers = viewControllers
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return TimeInterval(transitionDuration)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let fromView = fromVC.view,
            let fromIndex = index(ofViewController: fromVC),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let toView = toVC.view,
            let toIndex = index(ofViewController: toVC)
            else {
                transitionContext.completeTransition(false)
                return
        }

        let frame = transitionContext.initialFrame(for: fromVC)
        var fromFrameEnd = frame
        var toFrameStart = frame
        fromFrameEnd.origin.x = toIndex > fromIndex ? frame.origin.x - frame.width : frame.origin.x + frame.width
        toFrameStart.origin.x = toIndex > fromIndex ? frame.origin.x + frame.width : frame.origin.x - frame.width
        toView.frame = toFrameStart

        DispatchQueue.main.async {
            transitionContext.containerView.addSubview(toView)
            UIView.animate(withDuration: self.transitionDuration, animations: {
                fromView.frame = fromFrameEnd
                toView.frame = frame
            }, completion: {success in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(success)
            })
        }
    }

    private func index(ofViewController viewController: UIViewController) -> Int? {
        viewControllers?.firstIndex(of: viewController)
    }
}

private extension MenuTabBarController.Tab {
    var icon: UIImage? {
        switch self {
        case .home:
            return .homeTabBar
        case .profile:
            return .contactsTabBar
        case .settings:
            return .settingsTabBar
        }
    }

    var selectedIcon: UIImage? {
        switch self {
        case .home:
            return .homeTabBarSelected
        case .profile:
            return .selectedContactsTabBar
        case .settings:
            return .selectedSettingsTabBar
        }
    }
}
