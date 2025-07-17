//  Theme.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/03
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

struct Theme {
    static let shared = Theme()

    // NOTE: Any new theme properties must be added to tests to ensure all assets are included before deployment
    let fonts = Fonts()
    let images = Images()
    let sizes = Sizes()
}

struct Images {
    // Create Wallet
    let createWalletDownArrow = UIImage(named: "notch_down")
    let createWalletNumpad = UIImage(named: "numpad")

    // General icons
    let currencySymbol = UIImage(named: "Gem")
    let backArrow = UIImage(named: "BackArrow")
    let forwardArrow = UIImage(named: "ForwardArrow")
    let close = UIImage(named: "Close")
    let share = UIImage(named: "share")
    let handWave = UIImage(named: "HandWave")
    let attentionIcon = UIImage(named: "AttentionIcon")
    let scheduledIcon = UIImage(named: "ScheduledIcon")
    let successIcon = UIImage(named: "SuccessIcon")
    let tariIcon = UIImage(named: "TariIcon")
    let cancelGiphy = UIImage(named: "cancelGiphy")
    let poweredByGiphy = UIImage(named: "poweredByGiphy")
    let searchIcon = UIImage(named: "SearchIcon")

    // Amount
    let delete = UIImage(named: "numpad-delete")

    let splashScreen = UIImage(named: "staticSplash")
}

struct Fonts {

    let actionButton = UIFont.Poppins.Bold.withSize(16.0)
    let copiedLabel = UIFont.Poppins.Black.withSize(13.0)

    // SplashCreatingWallet
    let createWalletSecondLabelFirstText = UIFont.Poppins.Black.withSize(18.0)
    let createWalletSecondLabelSecondText = UIFont.Poppins.SemiBold.withSize(18.0)
    let createWalletThirdLabel = UIFont.Poppins.Medium.withSize(13.0)
    let createWalletEmojiIDFirstText = UIFont.Poppins.Light.withSize(18.0)
    let createWalletEmojiIDSecondText = UIFont.Poppins.Black.withSize(18.0)
    let createWalletNotificationsFirstLabel = UIFont.Poppins.Light.withSize(18.0)
    let createWalletNotificationsSecondLabel = UIFont.Poppins.Black.withSize(18.0)
    let createWalletNotificationsThirdLabel = UIFont.Poppins.Medium.withSize(14.0)
    let tapToSeeFullEmojiLabel = UIFont.Poppins.Bold.withSize(12.0)

    // Profile
    let profileMiddleLabel = UIFont.Poppins.Medium.withSize(14.0)

    // Loadig gif button
    let loadingGifButtonTitle = UIFont.Poppins.Bold.withSize(14.0)

    // Tx cell
    let txCellUsernameLabel = UIFont.Poppins.Light.withSize(14.0)
    let txCellUsernameLabelHeavy = UIFont.Poppins.Bold.withSize(14.0)
    let txCellDescriptionLabel = UIFont.Poppins.SemiBold.withSize(15.0)
    let txCellValueLabel = UIFont.Poppins.Black.withSize(12.0)
    let txDateValueLabel = UIFont.Poppins.Medium.withSize(11.0)
    let txCellStatusLabel = UIFont.Poppins.SemiBold.withSize(12.0)

    // View tx screen
    let txScreenCurrencyValueLabel = UIFont.Poppins.Black.withSize(90.0)
    let txScreenSubheadingLabel = UIFont.Poppins.Medium.withSize(13.0)
    let txScreenTextLabel = UIFont.Poppins.SemiBold.withSize(14.0)
    let txFeeLabel = UIFont.Poppins.Bold.withSize(14.0)
    let txSectionTitleLabel = UIFont.Poppins.Medium.withSize(16.0)

    // Sending tari screen
    let sendingTariTitleLabelFirst = UIFont.Poppins.Light.withSize(18.0)
    let sendingTariTitleLabelSecond = UIFont.Poppins.Black.withSize(18.0)

    // Navigation bar
    let navigationBarTitle = UIFont.Poppins.Bold.withSize(16.0)

    // Popup User feedback
    let feedbackPopupTitle = UIFont.Poppins.Light.withSize(18.0)
    let feedbackPopupDescription = UIFont.Poppins.Medium.withSize(14.0)

    // Simple text button
    let copyButton = UIFont.Poppins.Bold.withSize(14.0)

    // Add recipient view
    let searchContactsInputBoxText = UIFont.Poppins.SemiBold.withSize(14.0)

    // Add amount screen
    let keypadButton = UIFont.Poppins.Bold.withSize(36.0)
    let amountLabel = UIFont.Poppins.Black.withSize(90.0)
    let amountWarningLabel = UIFont.Poppins.SemiBold.withSize(13.0)

    // Add note screen
    let addNoteTitleLabel = UIFont.Poppins.Bold.withSize(16.0)
    let addNoteInputView = UIFont.Poppins.Medium.withSize(20.0)

    // Refresh view
    let refreshViewLabel = UIFont.Poppins.Bold.withSize(12.0)

    // App table view
    let systemTableViewCellMarkDescription = UIFont.Poppins.Medium.withSize(14.0)

    // Restore pending view
    let restorePendingViewTitle = UIFont.Poppins.Light.withSize(18.0)
    let restorePendingViewDescription = UIFont.Poppins.Medium.withSize(14.0)

    // Settings
    let settingsDoneButton = UIFont.Poppins.Medium.withSize(16.0)
    let settingsViewHeader = UIFont.Poppins.Black.withSize(17.0)
    let settingsViewHeaderDescription = UIFont.Poppins.Medium.withSize(14.0)
    let settingsTableViewLastBackupDate = UIFont.Poppins.Medium.withSize(14.0)

    let settingsSeedPhraseCellTitle = UIFont.Poppins.Bold.withSize(14.0)
    let settingsSeedPhraseCellNumber = UIFont.Poppins.Medium.withSize(14.0)

    let settingsSeedPhraseDescription = UIFont.Poppins.Medium.withSize(14.0)
    let settingsSeedPhraseAgreement = UIFont.Poppins.Medium.withSize(12.0)
    let settingsFillablePhraseViewDescription = UIFont.Poppins.Medium.withSize(12.0)

    let settingsPasswordTitle = UIFont.Poppins.Medium.withSize(13.0)
    let settingsPasswordPlaceholder = UIFont.Poppins.SemiBold.withSize(14.0)
    let settingsPasswordWarning = UIFont.Poppins.Bold.withSize(13.0)

    // Restore Wallet From Seed Words
    let restoreFromSeedWordsToken = UIFont.Poppins.Bold.withSize(14.0)
    let restoreFormSeedWordsDescription = UIFont.Poppins.Medium.withSize(14.0)
    let restoreFromSeedWordsProgressOverlayTitle = UIFont.Poppins.Light.withSize(18.0)
    let restoreFromSeedWordsProgressOverlayDescription = UIFont.Poppins.Medium.withSize(14.0)
}

struct Sizes {
    let appSidePadding: CGFloat = 22
}

// MARK: - Shadow

extension Shadow {
    static var none: Self { Self(color: nil, opacity: 0.0, radius: 0.0, offset: .zero) }
}
