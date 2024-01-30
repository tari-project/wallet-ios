//  ThemeCoordinator.swift

/*
	Package MobileWallet
	Created by Browncoat on 25/11/2022
	Using Swift 5.0
	Running on macOS 13.0

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

final class ThemeCoordinator {

    enum ColorScheme {
        case system
        case light
        case dark
        case tariPurple
    }

    // MARK: - Properties

    static let shared = ThemeCoordinator()

    var colorScheme: ColorScheme = .light {
        didSet {
            updateTheme(colorScheme: colorScheme)
            updateColorMode(colorScheme: colorScheme)
            updateUserDefaults(colorScheme: colorScheme)
        }
    }

    @Published private(set) var theme: ColorTheme = .light
    private var uiStyle: UIUserInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle

    // MARK: - Initialisers

    private init() {
        setupColorScheme()
    }

    // MARK: - Setups

    func configure(window: TariWindow) {
        setupCallbacks(window: window)
    }

    private func setupColorScheme() {
        switch UserSettingsManager.colorScheme {
        case .system:
            colorScheme = .system
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .purple:
            colorScheme = .tariPurple
        }
    }

    private func setupCallbacks(window: TariWindow) {

        window.onUpdateUIStyle = { [weak self] in
            self?.handle(uiStyle: $0)
        }
    }

    // MARK: - Actions

    private func theme(colorScheme: ColorScheme) -> ColorTheme {

        switch colorScheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .tariPurple:
            return .tariPurple
        case .system:
            return uiStyle == .dark ? .dark : .light
        }
    }

    private func updateUserDefaults(colorScheme: ColorScheme) {
        switch colorScheme {
        case .system:
            UserSettingsManager.colorScheme = .system
        case .light:
            UserSettingsManager.colorScheme = .light
        case .dark:
            UserSettingsManager.colorScheme = .dark
        case .tariPurple:
            UserSettingsManager.colorScheme = .purple
        }
    }

    private func updateColorMode(colorScheme: ColorScheme) {
        switch colorScheme {
        case .system:
            UIApplication.shared.firstWindow?.overrideUserInterfaceStyle = .unspecified
        case .light:
            UIApplication.shared.firstWindow?.overrideUserInterfaceStyle = .light
        case .dark, .tariPurple:
            UIApplication.shared.firstWindow?.overrideUserInterfaceStyle = .dark
        }
    }

    private func updateTheme(colorScheme: ColorScheme) {
        theme = theme(colorScheme: colorScheme)
        updateYatUIStyle(colorScheme: colorScheme)
    }

    private func updateYatUIStyle(colorScheme: ColorScheme) {
        switch colorScheme {
        case .system:
            Yat.style = uiStyle == .dark ? .dark : .light
        case .light:
            Yat.style = .light
        case .dark, .tariPurple:
            Yat.style = .dark
        }
    }

    // MARK: = Handlers

    private func handle(uiStyle: UIUserInterfaceStyle) {
        self.uiStyle = uiStyle
        guard colorScheme == .system else { return }
        updateTheme(colorScheme: .system)
    }
}
