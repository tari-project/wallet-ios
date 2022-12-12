//  SceneDelegate.swift

/*
    Package MobileWallet
    Created by Jason van den Berg on 2019/10/29
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
import YatLib

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // If the user opens the app from a notification when the app is closed
        if let notification = connectionOptions.notificationResponse {
            _ = notification.notification.request.content.userInfo
            // TODO handle notification content here
        }

        // If the user opens a deep link while the app is closed
        if let url = connectionOptions.urlContexts.first?.url {
            try? DeeplinkHandler.handle(deeplink: url)
        }

        // If the user opens a home screen shortcut while the app is closed
        if let shortcutItem = connectionOptions.shortcutItem {
            ShortcutsManager.handle(shortcut: shortcutItem)
        }

        if let appReturnLink = TariSettings.shared.yatReturnLink, let organizationName = TariSettings.shared.yatOrganizationName, let organizationKey = TariSettings.shared.yatOrganizationKey {
            Yat.configuration = YatConfiguration(appReturnLink: appReturnLink, organizationName: organizationName, organizationKey: organizationKey)
        }
        
        if let yatWebServiceURL = TariSettings.shared.yatWebServiceURL, let yatApiURL = TariSettings.shared.yatApiURL {
            Yat.urls = YatURLs(webServiceURL: yatWebServiceURL, apiURL: yatApiURL)
        }
        
        setupYatIntegration()
        
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()
        AppRouter.transitionToSplashScreen(animated: false)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        try? DeeplinkHandler.handle(deeplink: url)
        Yat.integration.handle(deeplink: url)
        BackupManager.shared.handle(url: url)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        ShortcutsManager.executeQueuedShortcut()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        LogFilesManager.cleanupLogs()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        ShortcutsManager.handle(shortcut: shortcutItem)
    }
    
    private func setupYatIntegration() {
        Yat.integration.onYatConnected = {
            TariSettings.shared.walletSettings.connectedYat = $0
        }
    }
}
