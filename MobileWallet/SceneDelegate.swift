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
import LocalAuthentication

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private var window: TariWindow?

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
            DispatchQueue.main.async {
                try? DeeplinkHandler.handle(rawDeeplink: url.absoluteString, showDefaultDialogIfNeeded: true)
            }
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
        let window = TariWindow(windowScene: windowScene)
        self.window = window
        window.makeKeyAndVisible()

        ThemeCoordinator.shared.configure(window: window)
        AppRouter.transitionToSplashScreen(animated: false)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        do {
            try DeeplinkHandler.handle(rawDeeplink: url.absoluteString, showDefaultDialogIfNeeded: true)
        } catch {
            print("Failed to handle deeplink in SceneDelegate: \(error)")
            // If it's a login deeplink, try again after a short delay
            if url.path == "/airdrop/auth" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    try? DeeplinkHandler.handle(rawDeeplink: url.absoluteString, showDefaultDialogIfNeeded: true)
                }
            }
        }
        Yat.integration.handle(deeplink: url)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        ShortcutsManager.executeQueuedShortcut()
        TabState.shared.checkRequiredVersion()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        Logger.log(message: "App State: Foreground", domain: .general, level: .info)
        UIApplication.shared.applicationIconBadgeNumber = 0
        LogFilesManager.cleanupLogs()

        // IMPORTANT: When app comes to foreground from terminated state,
        // make sure we don't show welcome overlay unless wallet was just created/restored
        UserDefaults.standard.set(false, forKey: "ShouldShowWelcomeOverlay")

        // When app comes to foreground, set wallet config state to initialized if wallet exists
        // This will trigger the authentication screen when required
        if Tari.shared.wallet(.main).isWalletDBExist {
            // Set configuration state to initialized to trigger authentication
            TariSettings.shared.walletSettings.configurationState = .initialized

            // Instead of transitioning to a new splash screen, trigger auth directly if we're on the home screen
            if let _ = UIApplication.shared.topController {
                // We're already in the app, show the local auth view controller
                let authVC = LocalAuthViewController()
                authVC.onAuthenticationSuccess = {
                    // Authentication successful, update config state and enable auto-reconnection
                    TariSettings.shared.walletSettings.configurationState = .authorized
                    Tari.shared.canAutomaticalyReconnectWallet = true
                    authVC.dismiss(animated: true)
                }
                authVC.onAuthenticationFailure = {
                    // Authentication failed or was canceled, stay on the auth screen
                    Logger.log(message: "Authentication canceled by user while app in foreground", domain: .general, level: .info)
                }

                // Present the auth view controller
                UIApplication.shared.topController?.present(authVC, animated: true)
            }
            // If we're not in the app yet, the splash screen will handle auth naturally
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        Logger.log(message: "App State: Background", domain: .general, level: .info)
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
