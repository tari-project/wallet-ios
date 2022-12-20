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
    let createWalletTouchID = UIImage(named: "fingerprint")
    let createWalletFaceID = UIImage(named: "faceId")
    let createWalletNofications = UIImage(named: "bell7")
    let createWalletDownArrow = UIImage(named: "notch_down")
    let createWalletNumpad = UIImage(named: "numpad")

    // TabBar
    let homeItem = UIImage(named: "navHome")
    let ttlItem = UIImage(named: "navTtl")
    let sendItem = UIImage(named: "navSend")?.withRenderingMode(.alwaysOriginal)
    let profileItem = UIImage(named: "navProfile")
    let settingsItem = UIImage(named: "navSettings")

    // General icons
    let currencySymbol = UIImage(named: "Gem")
    let qrButton = UIImage(named: "QRButton")
    let backArrow = UIImage(named: "BackArrow")
    let forwardArrow = UIImage(named: "ForwardArrow")
    let forwardArrowRed = UIImage(named: "ForwardArrowRed")
    let downArrow = UIImage(named: "DownArrow")
    let close = UIImage(named: "Close")
    let share = UIImage(named: "share")
    let txFee = UIImage(named: "TxFee")
    let profileIcon = UIImage(named: "profileIcon")
    let storeIcon = UIImage(named: "store-icon")
    let storeButton = UIImage(named: "store-button")
    let giftButton = UIImage(named: "gift-button")
    let storeModal = UIImage(named: "store-modal")
    let unknownUser = UIImage(named: "unknownUser")
    let handWave = UIImage(named: "HandWave")
    let attentionIcon = UIImage(named: "AttentionIcon")
    let scheduledIcon = UIImage(named: "ScheduledIcon")
    let successIcon = UIImage(named: "SuccessIcon")
    let tariIcon = UIImage(named: "TariIcon")
    let cancelGiphy = UIImage(named: "cancelGiphy")
    let cancelGrey = UIImage(named: "cancelGrey")
    let poweredByGiphy = UIImage(named: "poweredByGiphy")
    let searchIcon = UIImage(named: "SearchIcon")
    let yatLogo = UIImage(named: "YatLogo")
    let yatButtonOff = UIImage(named: "YatButtonOff")
    let yatButtonOn = UIImage(named: "YatButtonOn")

    // Amount
    let delete = UIImage(named: "numpad-delete")
    let helpButton = UIImage(named: "QuestionMark")

    // Profile
    let settings = UIImage(named: "settings")
    
    // Seed words list
    let expandButtonArrow = UIImage(named: "ExpandButtonArrow")
    
    // Home Icons
    let homeWalletIcon = UIImage(named: "icon-wallet")
    
    // UTXOs Wallet Icons
    let utxoFaucet = UIImage(named: "icon-faucet")
    let utxoTileViewIcon = UIImage(named: "icon-blockview")
    let utxoTextListIcon = UIImage(named: "icon-listview")
    let utxoStatusHourglass = UIImage(named: "icon-hourglass")
    let utxoActionJoin = UIImage(named: "icon-join")
    let utxoActionSplit = UIImage(named: "icon-split")
    let utxoActionJoinSplit = UIImage(named: "icon-join-split")
    
    // Settings Icons
    let settingsAboutIcon = UIImage(named: "icon-about")
    let settingsBaseNodeIcon = UIImage(named: "icon-base-node")
    let settingsBlockExplorerIcon = UIImage(named: "icon-block-explorer")
    let settingsBridgeConfigIcon = UIImage(named: "icon-bridge-config")
    let settingsContributeIcon = UIImage(named: "icon-contribute")
    let settingsDeleteIcon = UIImage(named: "icon-delete")
    let settingsDisclaimerIcon = UIImage(named: "icon-disclaimer")
    let settingsNetworkIcon = UIImage(named: "icon-network")
    let settingsPrivacyPolicyIcon = UIImage(named: "icon-privacy-policy")
    let settingsReportBugIcon = UIImage(named: "icon-report-bug")
    let settingsUserAgreementIcon = UIImage(named: "icon-user-agreement")
    let settingsVisitTariIcon = UIImage(named: "icon-visit-tari")
    let settingsWalletBackupsIcon = UIImage(named: "icon-wallet-backups")
    let settingsYatIcon = UIImage(named: "icon-yat")
    
    // Connection Details Icons
    let connectionInternetIcon = UIImage(named: "icon-internet")
    let connectionTorIcon = UIImage(named: "icon-tor")
    let connectionSyncIcon = UIImage(named: "icon-sync")
    
    // UTXOs Wallet
    
    let utxoTick = UIImage(named: "tick")
    let utxoWalletPlaceholder = UIImage(named: "UtxoWalletPlaceholder")
    let utxoWalletPickerMinus = UIImage(named: "ValuePickerMinus")
    let utxoWalletPickerPlus = UIImage(named: "ValuePickerPlus")
    let utxoSuccessImage = UIImage(named: "UtxoSuccess")
    
    // Adjustable fees
    
    let speedometerLow = UIImage(named: "speedometer-low")
    let speedometerMid = UIImage(named: "speedometer-mid")
    let speedometerHigh = UIImage(named: "speedometer-high")
    
    // Connection Indicator
    
    let connectionIndicatorConnectedIcon = UIImage(named: "network-full")
    let connectionIndicatorLimitedConnectonIcon = UIImage(named: "network-limited")
    let connectionIndicatorDisconnectedIcon = UIImage(named: "network-off")
}

struct Fonts {
    
    let actionButton = UIFont.Avenir.heavy.withSize(16.0)
    let copiedLabel = UIFont.Avenir.black.withSize(13.0)

    // SplashCreatingWallet
    let createWalletFirstLabel = UIFont.Avenir.black.withSize(18.0)
    let createWalletSecondLabelFirstText = UIFont.Avenir.black.withSize(18.0)
    let createWalletSecondLabelSecondText = UIFont.Avenir.roman.withSize(18.0)
    let createWalletThirdLabel = UIFont.Avenir.medium.withSize(13.0)
    let createWalletEmojiIDFirstText = UIFont.Avenir.light.withSize(18.0)
    let createWalletEmojiIDSecondText = UIFont.Avenir.black.withSize(18.0)
    let createWalletNotificationsFirstLabel = UIFont.Avenir.light.withSize(18.0)
    let createWalletNotificationsSecondLabel = UIFont.Avenir.black.withSize(18.0)
    let createWalletNotificationsThirdLabel = UIFont.Avenir.medium.withSize(14.0)
    let tapToSeeFullEmojiLabel = UIFont.Avenir.heavy.withSize(12.0)
    let restoreWalletButton = UIFont.Avenir.medium.withSize(13.0)

    // Profile
    let profileTitleLightLabel = UIFont.Avenir.light.withSize(18.0)
    let profileTitleRegularLabel = UIFont.Avenir.black.withSize(18.0)
    let profileCopyEmojiButton = UIFont.Avenir.medium.withSize(12.0)
    let profileMiddleLabel = UIFont.Avenir.medium.withSize(14.0)

    // Home screen
    let homeScreenTotalBalanceLabel = UIFont.Avenir.medium.withSize(12.0)
    let homeScreenTotalBalanceValueLabel = UIFont.Avenir.black.withSize(30.0)
    let homeScreenTotalBalanceValueLabelDecimals = UIFont.Avenir.heavy.withSize(12.0)

    // Loadig gif button
    let loadingGifButtonTitle = UIFont.Avenir.heavy.withSize(14.0)

    // Tx cell
    let txCellUsernameLabel = UIFont.Avenir.light.withSize(14.0)
    let txCellUsernameLabelHeavy = UIFont.Avenir.heavy.withSize(14.0)
    let txCellDescriptionLabel = UIFont.Avenir.roman.withSize(15.0)
    let txCellValueLabel = UIFont.Avenir.black.withSize(12.0)
    let txDateValueLabel = UIFont.Avenir.medium.withSize(11.0)
    let txCellStatusLabel = UIFont.Avenir.roman.withSize(12.0)

    // View tx screen
    let txScreenCurrencyValueLabel = UIFont.Avenir.black.withSize(90.0)
    let txScreenSubheadingLabel = UIFont.Avenir.medium.withSize(13.0)
    let txScreenTextLabel = UIFont.Avenir.roman.withSize(14.0)
    let txScreenTxIDLabel = UIFont.Avenir.roman.withSize(13.0)
    let txListEmptyTitleLabel = UIFont.Avenir.black.withSize(33.0)
    let txListEmptyMessageLabel = UIFont.Avenir.medium.withSize(14.0)
    let txFeeLabel = UIFont.Avenir.heavy.withSize(14.0)
    let txFeeButton = UIFont.Avenir.roman.withSize(13.0)
    let txSectionTitleLabel = UIFont.Avenir.medium.withSize(16.0)

    // Sending tari screen
    let sendingTariTitleLabelFirst = UIFont.Avenir.light.withSize(18.0)
    let sendingTariTitleLabelSecond = UIFont.Avenir.black.withSize(18.0)

    // Navigation bar
    let navigationBarTitle = UIFont.Avenir.heavy.withSize(16.0)

    // Popup User feedback
    let feedbackPopupTitle = UIFont.Avenir.light.withSize(18.0)
    let feedbackPopupHeavy = UIFont.Avenir.black.withSize(18.0)
    let feedbackPopupDescription = UIFont.Avenir.medium.withSize(14.0)
    let feedbackPopupDescriptionBold = UIFont.Avenir.black.withSize(14.0)

    // Simple text button
    let textButton = UIFont.Avenir.medium.withSize(14.0)
    let copyButton = UIFont.Avenir.heavy.withSize(14.0)
    let textButtonCancel = UIFont.Avenir.medium.withSize(12.0)

    // Intro to wallet
    let introTitleBold = UIFont.Avenir.black.withSize(18.0)
    let introTitle = UIFont.Avenir.light.withSize(18.0)

    // Add recipient view
    let searchContactsInputBoxText = UIFont.Avenir.roman.withSize(14.0)
    let contactCellAlias = UIFont.Avenir.heavy.withSize(15.0)
    let contactCellAliasLetter = UIFont.Avenir.heavy.withSize(24.0)

    // Add amount screen
    let keypadButton = UIFont.Avenir.heavy.withSize(36.0)
    let amountLabel = UIFont.Avenir.black.withSize(90.0)
    let warningBoxTitleLabel = UIFont.Avenir.heavy.withSize(14.0)
    let amountWarningLabel = UIFont.Avenir.roman.withSize(13.0)

    // Add note screen
    let addNoteTitleLabel = UIFont.Avenir.heavy.withSize(16.0)
    let addNoteInputView = UIFont.Avenir.medium.withSize(20.0)
    let searchGiphyButtonTitle = UIFont.Avenir.black.withSize(9.0)

    // Add note screen
    let scannerTitleLabel = UIFont.Avenir.heavy.withSize(16.0)

    // Refresh view
    let refreshViewLabel = UIFont.Avenir.heavy.withSize(12.0)

    // App table view
    let systemTableViewCell = UIFont.Avenir.medium.withSize(15.0)
    let systemTableViewCellMarkDescription = UIFont.Avenir.medium.withSize(14.0)
    let systemTableViewCellMarkDescriptionSmall = UIFont.Avenir.medium.withSize(11.0)
    let tableViewSection = UIFont.Avenir.medium.withSize(14.0)

    // Restore pending view
    let restorePendingViewTitle = UIFont.Avenir.light.withSize(18.0)
    let restorePendingViewDescription = UIFont.Avenir.medium.withSize(14.0)

    // Settings
    let settingsDoneButton = UIFont.Avenir.medium.withSize(16.0)
    let settingsViewHeader = UIFont.Avenir.black.withSize(17.0)
    let settingsViewHeaderDescription = UIFont.Avenir.medium.withSize(14.0)
    let settingsTableViewLastBackupDate = UIFont.Avenir.medium.withSize(14.0)

    let settingsSeedPhraseCellTitle = UIFont.Avenir.heavy.withSize(14.0)
    let settingsSeedPhraseCellNumber = UIFont.Avenir.medium.withSize(14.0)

    let settingsSeedPhraseDescription = UIFont.Avenir.medium.withSize(14.0)
    let settingsSeedPhraseAgreement = UIFont.Avenir.medium.withSize(12.0)
    let settingsRecoveryPhraseWorld = UIFont.Avenir.heavy.withSize(14.0)
    let settingsFillablePhraseViewDescription = UIFont.Avenir.medium.withSize(12.0)

    let settingsPasswordTitle = UIFont.Avenir.medium.withSize(13.0)
    let settingsPasswordPlaceholder = UIFont.Avenir.roman.withSize(14.0)
    let settingsPasswordWarning = UIFont.Avenir.heavy.withSize(13.0)

    let tooltip = UIFont.Avenir.heavy.withSize(12.0)

    // Text Field
    let textField = UIFont.Avenir.light.withSize(14.0)

    // Restore Wallet From Seed Words
    let restoreFromSeedWordsToken = UIFont.Avenir.heavy.withSize(14.0)
    let restoreFormSeedWordsDescription = UIFont.Avenir.medium.withSize(14.0)
    let restoreFromSeedWordsProgressOverlayTitle = UIFont.Avenir.light.withSize(18.0)
    let restoreFromSeedWordsProgressOverlayDescription = UIFont.Avenir.medium.withSize(14.0)
}

struct Sizes {
    let appSidePadding: CGFloat = 22
    // TODO move other constants here
}

// MARK: - Color Pallete

extension UIColor {
    
    enum `static` {
        static var white: UIColor? { UIColor(named: "White") }
        static var black: UIColor? { UIColor(named: "Black") }
        static var purple: UIColor? { UIColor(named: "Purple") }
        static var mediumGrey: UIColor? { UIColor(named: "MediumGrey") }
        static var popupOverlay: UIColor? { .black.withAlphaComponent(0.7) }
    }
}

extension Shadow {
    static var none: Self { Self(color: nil, opacity: 0.0, radius: 0.0, offset: .zero) }
}
