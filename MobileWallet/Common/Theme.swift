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

    // TabBar
    let homeItem = UIImage(named: "navHome")
    let ttlItem = UIImage(named: "navTtl")
    let settingsItem = UIImage(named: "navSettings")

    // General icons
    let currencySymbol = UIImage(named: "Gem")
    let backArrow = UIImage(named: "BackArrow")
    let forwardArrow = UIImage(named: "ForwardArrow")
    let close = UIImage(named: "Close")
    let share = UIImage(named: "share")
    let txFee = UIImage(named: "TxFee")
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

    // Seed words list
    let expandButtonArrow = UIImage(named: "ExpandButtonArrow")

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
    let settingColorThemeIcon = UIImage(named: "icon-theme")

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

    // Color Themes

    let colorThemeSystem = UIImage(named: "Themes/System")
    let colorThemeLight = UIImage(named: "Themes/Light")
    let colorThemeDark = UIImage(named: "Themes/Dark")
    let colorThemePurple = UIImage(named: "Themes/Purple")
}

struct Fonts {

    let actionButton = UIFont.Avenir.heavy.withSize(16.0)
    let copiedLabel = UIFont.Avenir.black.withSize(13.0)

    // SplashCreatingWallet
    let createWalletSecondLabelFirstText = UIFont.Avenir.black.withSize(18.0)
    let createWalletSecondLabelSecondText = UIFont.Avenir.roman.withSize(18.0)
    let createWalletThirdLabel = UIFont.Avenir.medium.withSize(13.0)
    let createWalletEmojiIDFirstText = UIFont.Avenir.light.withSize(18.0)
    let createWalletEmojiIDSecondText = UIFont.Avenir.black.withSize(18.0)
    let createWalletNotificationsFirstLabel = UIFont.Avenir.light.withSize(18.0)
    let createWalletNotificationsSecondLabel = UIFont.Avenir.black.withSize(18.0)
    let createWalletNotificationsThirdLabel = UIFont.Avenir.medium.withSize(14.0)
    let tapToSeeFullEmojiLabel = UIFont.Avenir.heavy.withSize(12.0)

    // Profile
    let profileMiddleLabel = UIFont.Avenir.medium.withSize(14.0)

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
    let feedbackPopupDescription = UIFont.Avenir.medium.withSize(14.0)

    // Simple text button
    let textButton = UIFont.Avenir.medium.withSize(14.0)
    let copyButton = UIFont.Avenir.heavy.withSize(14.0)
    let textButtonCancel = UIFont.Avenir.medium.withSize(12.0)

    // Add recipient view
    let searchContactsInputBoxText = UIFont.Avenir.roman.withSize(14.0)

    // Add amount screen
    let keypadButton = UIFont.Avenir.heavy.withSize(36.0)
    let amountLabel = UIFont.Avenir.black.withSize(90.0)
    let amountWarningLabel = UIFont.Avenir.roman.withSize(13.0)

    // Add note screen
    let addNoteTitleLabel = UIFont.Avenir.heavy.withSize(16.0)
    let addNoteInputView = UIFont.Avenir.medium.withSize(20.0)
    let searchGiphyButtonTitle = UIFont.Avenir.black.withSize(9.0)

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
    let settingsFillablePhraseViewDescription = UIFont.Avenir.medium.withSize(12.0)

    let settingsPasswordTitle = UIFont.Avenir.medium.withSize(13.0)
    let settingsPasswordPlaceholder = UIFont.Avenir.roman.withSize(14.0)
    let settingsPasswordWarning = UIFont.Avenir.heavy.withSize(13.0)

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
    static var `static`: StaticColors.Type { StaticColors.self }
}

enum StaticColors {
    static var white: UIColor? { UIColor(named: "White") }
    static var black: UIColor? { UIColor(named: "Black") }
    static var purple: UIColor? { UIColor(named: "Purple") }
    static var red: UIColor? { UIColor(named: "Red") }
    static var mediumGrey: UIColor? { UIColor(named: "MediumGrey") }
    static var popupOverlay: UIColor? { .black.withAlphaComponent(0.7) }
}

extension Shadow {
    static var none: Self { Self(color: nil, opacity: 0.0, radius: 0.0, offset: .zero) }
}

// MARK: - Images

extension UIImage {
    static var security: SecurityImages.Type { SecurityImages.self }
    static var chat: ChatImages.Type { ChatImages.self }
    static var contactBook: ContactBookImages.Type { ContactBookImages.self }
    static var icons: IconsImages.Type { IconsImages.self }
    static var tabBar: TabBarImages.Type { TabBarImages.self }
}

// MARK: - Security

enum SecurityImages {
    static var onboarding: SecurityOnboardingImages.Type { SecurityOnboardingImages.self }
}

enum SecurityOnboardingImages {
    static var background: UIImage? { UIImage(named: "Images/Security/Onboarding/Background") }
    static var page1: UIImage? { UIImage(named: "Images/Security/Onboarding/Page1") }
    static var page2: UIImage? { UIImage(named: "Images/Security/Onboarding/Page2") }
    static var page3: UIImage? { UIImage(named: "Images/Security/Onboarding/Page3") }
    static var page4: UIImage? { UIImage(named: "Images/Security/Onboarding/Page4") }
}

// MARK: - Chat

enum ChatImages {
    static var placeholders: ChatPlaceholders.Type { ChatPlaceholders.self }
}

enum ChatPlaceholders {
    static var list: UIImage? { UIImage(named: "Images/Chat/Placeholders/List") }
    static var conversation: UIImage? { UIImage(named: "Images/Chat/Placeholders/Conversation") }
}

// MARK: - Contact Book

enum ContactBookImages {
    static var bleDialog: ContactBookBLEDialogImages.Type { ContactBookBLEDialogImages.self }
    static var buttons: ContactBookButtonImages.Type { ContactBookButtonImages.self }
    static var placeholders: ContactBookPlaceholderImages.Type { ContactBookPlaceholderImages.self }
}

enum ContactBookBLEDialogImages {
    static var icon: UIImage? { UIImage(named: "Images/Contact Book/BLE Dialog/Icon") }
    static var success: UIImage? { UIImage(named: "Images/Contact Book/BLE Dialog/Success") }
    static var failure: UIImage? { UIImage(named: "Images/Contact Book/BLE Dialog/Failure") }
}

enum ContactBookButtonImages {
    static var addContact: UIImage? { UIImage(named: "Images/Contact Book/Buttons/AddContact") }
    static var share: UIImage? { UIImage(named: "Images/Contact Book/Buttons/Share") }
}

enum ContactBookPlaceholderImages {
    static var contactsList: UIImage? { UIImage(named: "Images/Contact Book/Placeholders/ContactBookListPlaceholder") }
    static var favoritesContactsList: UIImage? { UIImage(named: "Images/Contact Book/Placeholders/ContactBookListFavPlaceholder") }
    static var transactionList: UIImage? { UIImage(named: "Images/Contact Book/Placeholders/TransactionList") }
    static var linkList: UIImage? { UIImage(named: "Images/Contact Book/Placeholders/LinkList") }
}

// MARK: - Tab Bar

enum TabBarImages {
    static var send: UIImage? { UIImage(named: "Images/TabBar/Send") }
}

// MARK: - Icons

enum IconsImages {

    static var contactTypes: IconsContactTypesImages.Type { IconsContactTypesImages.self }
    static var network: IconsNetworkImages.Type { IconsNetworkImages.self }
    static var rotaryMenu: IconsRotaryImages.Type { IconsRotaryImages.self }
    static var settings: IconsSettingsImages.Type { IconsSettingsImages.self }
    static var star: IconsStarImages.Type { IconsStarImages.self }
    static var tabBar: IconsTabBarImages.Type { IconsTabBarImages.self }

    static var analytics: UIImage? { UIImage(named: "Icons/Analytics") }
    static var bluetooth: UIImage? { UIImage(named: "Icons/Bluetooth") }
    static var checkmark: UIImage? { UIImage(named: "Icons/Checkmark") }
    static var close: UIImage? { UIImage(named: "Icons/Close") }
    static var link: UIImage? { UIImage(named: "Icons/Link") }
    static var magnifyingGlass: UIImage? { UIImage(named: "Icons/Magnifying Glass") }
    static var profile: UIImage? { UIImage(named: "Icons/Profile") }
    static var send: UIImage? { UIImage(named: "Icons/Send") }
    static var sendMessage: UIImage? { UIImage(named: "Icons/Send Message") }
    static var tariGem: UIImage? { UIImage(named: "Icons/Tari Gem") }
    static var qr: UIImage? { UIImage(named: "Icons/QR") }
    static var unlink: UIImage? { UIImage(named: "Icons/Unlink") }
    static var wallet: UIImage? { UIImage(named: "Icons/Wallet") }
}

enum IconsContactTypesImages {
    static var `internal`: UIImage? { UIImage(named: "Icons/Contact Types/Internal") }
    static var external: UIImage? { UIImage(named: "Icons/Contact Types/External") }
    static var linked: UIImage? { UIImage(named: "Icons/Contact Types/Linked") }
}

enum IconsNetworkImages {
    static var full: UIImage? { UIImage(named: "Icons/Network/Full") }
    static var limited: UIImage? { UIImage(named: "Icons/Network/Limited") }
    static var off: UIImage? { UIImage(named: "Icons/Network/Off") }
}

enum IconsRotaryImages {
    static var close: UIImage? { UIImage(named: "Icons/Rotary Menu/Close") }
    static var switchSide: UIImage? { UIImage(named: "Icons/Rotary Menu/Switch Side") }
}

enum IconsSettingsImages {
    static var bluetooth: UIImage? { UIImage(named: "Icons/Settings/Bluetooth") }
}

enum IconsStarImages {
    static var border: UIImage? { UIImage(named: "Icons/Star/Border") }
    static var filled: UIImage? { UIImage(named: "Icons/Star/Filled") }
}

enum IconsTabBarImages {
    static var chat: UIImage? { UIImage(named: "Icons/TabBar/Chat") }
    static var contactBook: UIImage? { UIImage(named: "Icons/TabBar/ContactBook") }
}
