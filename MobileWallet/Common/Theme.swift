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

protocol Loopable {
    func allProperties() throws -> [String: Any?]
}

extension Loopable {
    func allProperties() throws -> [String: Any?] {
        var result: [String: Any?] = [:]
        let mirror = Mirror(reflecting: self)

        // Optional check to make sure we're iterating over a struct or class
        guard let style = mirror.displayStyle, style == .struct || style == .class else {
            throw NSError()
        }

        for (property, value) in mirror.children {
            guard let property = property else {
                continue
            }

            result[property] = value
        }

        return result
    }
}

struct Theme {
    static let shared = Theme()

    //NOTE: Any new theme properties must be added to tests to ensure all assets are included before deployment
    let fonts = Fonts()
    let colors = Colors()
    let images = Images()
    let sizes = Sizes()
    let transitions = Transitions()
}

struct Colors: Loopable {
    let gradientStartColor = UIColor(named: "GradientStartColor")
    let gradientEndColor = UIColor(named: "GradientEndColor")

    let accessAnimationViewShadow = UIColor(named: "AccessAnimationViewShadow")

    let actionButtonBackgroundSimple = UIColor(named: "ActionButtonBackgroundSimple")
    let actionButtonTitle = UIColor(named: "ActionButtonTitle")

    let actionButtonBackgroundDisabled = UIColor(named: "ActionButtonBackgroundDisabled")
    let actionButtonTitleDisabled = UIColor(named: "ActionButtonTitleDisabled")

    let transactionTableBackground = UIColor(named: "TransactionTableBackground")
    let splashBackground = UIColor(named: "SplashBackground")
    let appBackground = UIColor(named: "AppBackground")

    let inputPlaceholder = UIColor(named: "Placeholder")
    let systemTableViewCellBackground = UIColor(named: "SystemMenuTableViewCellBackground")

    let checkBoxBorderColor = UIColor(named: "CheckboxBorderColor")

    // Splash
    let splashTitle = UIColor(named: "SplashTitle")
    let splashSubtitle = UIColor(named: "SplashSubtitle")
    let splashVersionLabel = UIColor(named: "SplashVersionLabel")

    //SplashCreatingWallet
    let creatingWalletFirstLabel = UIColor(named: "CreatingWalletBlackLabel")
    let creatingWalletSecondLabel = UIColor(named: "CreatingWalletBlackLabel")
    let creatingWalletThirdLabel = UIColor(named: "CreatingWalletOtherLabel")
    let creatingWalletBackground = UIColor(named: "CreatingWalletBackground")
    let creatingWalletEmojisLabelBackground = UIColor(named: "CreatingWalletEmojisLabel")
    let tapToSeeFullEmoji = UIColor(named: "CreatingWalletTapToSeeFullEmoji")
    let tapToSeeFullEmojiBackground = UIColor(named: "CreatingWalletTapToSeeFullEmojiIDBackground")

    // Profile
    let profileTitleTextColor = UIColor(named: "ProfileTitleTextBlack")
    let profileMiddleLabel = UIColor(named: "ProfileMiddleLabel")
    let profileQRShadow = UIColor(named: "ProfileQRShadow")
    let profileBackground = UIColor(named: "ProfileBackground")

    // Settings
    let settingsTableStyleBackground = UIColor(named: "SettingsTableStyleBackground")
    let settingsDoneButtonTitle = UIColor(named: "SettingsDoneButtonTitle")
    let settingsNavBarSeparator = UIColor(named: "SettingsNavBarSeparator")
    let settingsViewDescription = UIColor(named: "SettingsViewDescription")
    let cettingsSeedPhraseCellTitle = UIColor(named: "SettingsSeedPhraseCell")
    let settingsSeedPhraseAgreement = UIColor(named: "SettingsSeedPhraseAgreement")
    let settingsRecoveryPhraseWorldText = UIColor(named: "SettingsRecoveryPhraseWorldText")
    let settingsRecoveryPhraseWorldBorder = UIColor(named: "SettingsRecoveryPhraseWorldBorder")
    let settingsVerificationPhraseViewBackground = UIColor(named: "SettingsVerificationPhraseViewBackground")
    let settingsFillablePhraseViewDescription = UIColor(named: "SettingsFillablePhraseViewDescription")
    let settingsTableViewLastBackupDate = UIColor(named: "SettingsTableViewLastBackupDate")
    let settingsTableViewMarkDescriptionSuccess = UIColor(named: "SettingsTableViewMarkDescriptionSuccess")
    let settingsTableViewMarkDescriptionWarning = UIColor(named: "SettingsTableViewMarkDescriptionWarning")
    let settingsTableViewMarkDescriptionInProgress = UIColor(named: "SettingsTableViewMarkDescriptionInProgress")
    let settingsPasswordWarning = UIColor(named: "SettingsPasswordWarning")

    //Home screen
    let homeScreenBackground = UIColor(named: "HomeScreenBackground")
    let homeScreenTotalBalanceLabel = UIColor(named: "HomeScreenTotalBalanceLabel")
    let homeScreenTotalBalanceValueLabel = UIColor(named: "HomeScreenTotalBalanceLabel")
    let floatingPanelGrabber = UIColor(named: "FloatingPanelGrabber")
    let qrButtonBackground = UIColor(named: "QRButtonBackground")
    let transactionsListNavBar = UIColor(named: "TransactionsListNavBar")

    let auroraGradient1 = UIColor(named: "auroraGradient1")
    let auroraGradient2 = UIColor(named: "auroraGradient2")
    let auroraGradient3 = UIColor(named: "auroraGradient3")
    let auroraGradient4 = UIColor(named: "auroraGradient4")
    let auroraGradient5 = UIColor(named: "auroraGradient5")
    let auroraGradient6 = UIColor(named: "auroraGradient6")
    let auroraGradient7 = UIColor(named: "auroraGradient7")
    let auroraGradient8 = UIColor(named: "auroraGradient8")
    let auroraGradient9 = UIColor(named: "auroraGradient9")

    //Transaction cell
    let transactionCellAlias = UIColor(named: "TableCellContactAlias")
    let transactionCellDescription = UIColor(named: "TransactionCellDescription")
    let transactionCellValueNegativeBackground = UIColor(named: "TransactionCellValueNegativeBackground")
    let transactionCellValuePositiveBackground = UIColor(named: "TransactionCellValuePositiveBackground")
    let transactionCellValueCancelledBackground = UIColor(named: "TransactionCellValueCancelledBackground")
    let transactionCellValueNegativeText = UIColor(named: "TransactionCellValueNegativeText")
    let transactionCellValuePositiveText = UIColor(named: "TransactionCellValuePositiveText")
    let transactionCellValueCancelledText = UIColor(named: "TransactionCellValueCancelledText")
    let transactionSmallSubheadingLabel = UIColor(named: "SmallSubheading")

    // Sending Tari
    let sendingTariTitle = UIColor(named: "SendingTariTitleText")
    let sendingTariBackground = UIColor(named: "SendingTariBackground")
    let sendingTariPassiveProgressBackground = UIColor(named: "SendingTariPassiveProgressBackground")
    let sendingTariActiveProgressBackground = UIColor(named: "SendingTariActiveProgressBackground")
    let sendingTariProgress = UIColor(named: "SendingTariProgress")

    //Navigation bar
    let navigationBarTint = UIColor(named: "Heading")
    let navigationBarBackground = UIColor(named: "NavBarBackground")

    //Transaction view
    let transactionViewValueLabel = UIColor(named: "Heading")
    let transactionViewValueContainer = UIColor(named: "TransactionViewValueBackground")
    let transactionScreenDivider = UIColor(named: "DividerColor")
    let transactionScreenSubheadingLabel = UIColor(named: "SmallSubheading")
    let transactionScreenTextLabel = UIColor(named: "SmallText")
    let transactionScreenEmptyTitleLabel = UIColor(named: "Heading")

    //Shadows
    let actionButtonShadow = UIColor(named: "ActionButtonShadow")
    let defaultShadow = UIColor(named: "DefaultShadow")

    //Feedback
    let feedbackPopupBackground = UIColor(named: "FeedbackScreenBackground")
    let feedbackPopupTitle = UIColor(named: "Heading")
    let feedbackPopupDescription = UIColor(named: "SmallSubheading")
    let successFeedbackPopupBackground = UIColor(named: "SuccessFeedbackBackground")
    let successFeedbackPopupTitle = UIColor(named: "SuccessFeedbackText")

    //Emoji button
    let emojiButtonShadow = UIColor(named: "EmojiButtonShadow")
    let emojiButtonBackground = UIColor(named: "AppBackground")
    let emojiButtonClip = UIColor(named: "EmojiClip")

    //Simple text button
    let textButton = UIColor(named: "TextButton")
    let textButtonSecondary = UIColor(named: "TextButtonSecondary")
    let warningButtonTitle = UIColor(named: "Warning")

    //Add recipient view
    let contactCellAlias = UIColor(named: "TableCellContactAlias")
    let contactCellImageBackground = UIColor(named: "TableCellContactImageBackground")
    let contactCellImage = UIColor(named: "TableCellContactImage")

    //Amount screen
    let keypadButton = UIColor(named: "KeypadButton")
    let warningBoxBorder = UIColor(named: "Warning")
    let amountWarningLabel = UIColor(named: "AmountWarningLabel")
    let amountLabel = UIColor(named: "InputText")

    //Add note screen
    let addNoteTitleLabel = UIColor(named: "Heading")
    let addNoteInputView = UIColor(named: "InputText")

    //EmoticonView
    let emoticonBlackBackgroundAlpha = UIColor(named: "EmoticonBlackBackgroundAlpha")

    //ScannerView
    let scannerTitle = UIColor(named: "ScannerTitle")

    // EmoticonView
    let emojisSeparator = UIColor(named: "CreatingWalletEmojiSeparator")
    let emojisSeparatorExpanded = UIColor(named: "CreatingWalletEmojiSeparatorExpanded")

    //Refresh view
    let refreshViewLabelLoading = UIColor(named: "RefreshViewLabelLoading")
    let refreshViewLabelSuccess = UIColor(named: "RefreshViewLabelSuccess")

    //Restore pending view
    let restorePendingViewTitle = UIColor(named: "RestorePendingViewTitle")
    let restorePendingViewDescription = UIColor(named: "RestorePendingViewDescription")
    let restorePendingViewProgressView = UIColor(named: "RestorePendingViewProgressView")

}

struct Images: Loopable {
    // Create Wallet
    let createWalletTouchID = UIImage(named: "fingerprint")
    let createWalletFaceID = UIImage(named: "faceId")
    let createWalletNofications = UIImage(named: "bell7")
    let createWalletDownArrow = UIImage(named: "notch_down")
    let createWalletNumpad = UIImage(named: "numpad")

    //Transaction icons
    let food = UIImage(named: "food")
    let game = UIImage(named: "game")
    let thanks = UIImage(named: "thanks")
    let transfer = UIImage(named: "transfer")
    let drinks = UIImage(named: "drinks")
    let services = UIImage(named: "services")

    //General icons
    let currencySymbol = UIImage(named: "Gem")
    let qrButton = UIImage(named: "QRButton")
    let backArrow = UIImage(named: "BackArrow")
    let forwardArrow = UIImage(named: "ForwardArrow")
    let downArrow = UIImage(named: "DownArrow")
    let close = UIImage(named: "Close")
    let share = UIImage(named: "share")
    let transactionFee = UIImage(named: "TransactionFee")
    let profileIcon = UIImage(named: "profileIcon")
    let storeIcon = UIImage(named: "store-icon")
    let storeButton = UIImage(named: "store-button")
    let storeModal = UIImage(named: "store-modal")
    let unknownUser = UIImage(named: "unknownUser")
    let handWave = UIImage(named: "HandWave")
    let attentionIcon = UIImage(named: "AttentionIcon")
    let successIcon = UIImage(named: "SuccessIcon")
    let tariIcon = UIImage(named: "TariIcon")

    //Amount
    let delete = UIImage(named: "numpad-delete")

    //profile
    let settings = UIImage(named: "settings")
}

struct Fonts: Loopable {
    let splashVersionFooterLabel = UIFont.Avenir.heavy.withSize(9.0)
    let actionButton = UIFont.Avenir.heavy.withSize(16.0)
    let copiedLabel = UIFont.Avenir.black.withSize(13.0)

    //Splash
    let splashTitleLabel = UIFont.Avenir.black.withSize(30.0)
    let splashSubtitleLabel = UIFont.Avenir.medium.withSize(14.0)
    let splashDisclaimerLabel = UIFont.Avenir.medium.withSize(12.0)

    //SplashCreatingWallet
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

    //Profile
    let profileTitleLightLabel = UIFont.Avenir.light.withSize(18.0)
    let profileTitleRegularLabel = UIFont.Avenir.black.withSize(18.0)
    let profileCopyEmojiButton = UIFont.Avenir.medium.withSize(12.0)
    let profileMiddleLabel = UIFont.Avenir.medium.withSize(14.0)

    //Home screen
    let homeScreenTotalBalanceLabel = UIFont.Avenir.roman.withSize(14.0)
    let homeScreenTotalBalanceValueLabel = UIFont.Avenir.black.withSize(39.0)
    let homeScreenTotalBalanceValueLabelDecimals = UIFont.Avenir.black.withSize(16.0)

    //Transaction cell
    let transactionCellUsernameLabel = UIFont.Avenir.heavy.withSize(15.0)
    let transactionCellDescriptionLabel = UIFont.Avenir.roman.withSize(14.0)
    let transactionCellValueLabel = UIFont.Avenir.black.withSize(12.0)
    let transactionDateValueLabel = UIFont.Avenir.medium.withSize(12.0)

    //View transaction screen
    let transactionScreenCurrencyValueLabel = UIFont.Avenir.black.withSize(90.0)
    let transactionScreenSubheadingLabel = UIFont.Avenir.medium.withSize(13.0)
    let transactionScreenTextLabel = UIFont.Avenir.roman.withSize(14.0)
    let transactionScreenTxIDLabel = UIFont.Avenir.roman.withSize(13.0)
    let transactionListEmptyTitleLabel = UIFont.Avenir.black.withSize(33.0)
    let transactionListEmptyMessageLabel = UIFont.Avenir.medium.withSize(14.0)
    let transactionFeeLabel = UIFont.Avenir.heavy.withSize(14.0)
    let transactionFeeButton = UIFont.Avenir.roman.withSize(13.0)

    // Sending tari screen
    let sendingTariTitleLabelFirst = UIFont.Avenir.light.withSize(18.0)
    let sendingTariTitleLabelSecond = UIFont.Avenir.black.withSize(18.0)

    //Navigation bar
    let navigationBarTitle = UIFont.Avenir.heavy.withSize(16.0)

    //Popup User feedback
    let feedbackPopupTitle = UIFont.Avenir.light.withSize(18.0)
    let feedbackPopupHeavy = UIFont.Avenir.black.withSize(18.0)
    let feedbackPopupDescription = UIFont.Avenir.medium.withSize(14.0)

    //Simple text button
    let textButton = UIFont.Avenir.medium.withSize(14.0)
    let copyButton = UIFont.Avenir.heavy.withSize(14.0)
    let textButtonCancel = UIFont.Avenir.medium.withSize(12.0)

    //Intro to wallet
    let introTitleBold = UIFont.Avenir.black.withSize(18.0)
    let introTitle = UIFont.Avenir.light.withSize(18.0)

    //Add recipient view
    let searchContactsInputBoxText = UIFont.Avenir.roman.withSize(14.0)
    let contactCellAlias = UIFont.Avenir.heavy.withSize(15.0)
    let contactCellAliasLetter = UIFont.Avenir.heavy.withSize(24.0)

    //Add amount screen
    let keypadButton = UIFont.Avenir.heavy.withSize(22.0)
    let amountLabel = UIFont.Avenir.black.withSize(80.0)
    let warningBoxTitleLabel = UIFont.Avenir.heavy.withSize(14.0)
    let amountWarningLabel = UIFont.Avenir.roman.withSize(13.0)

    //Add note screen
    let addNoteTitleLabel = UIFont.Avenir.heavy.withSize(16.0)
    let addNoteInputView = UIFont.Avenir.medium.withSize(20.0)

    //Add note screen
    let scannerTitleLabel = UIFont.Avenir.heavy.withSize(16.0)

    //Refresh view
    let refreshViewLabel = UIFont.Avenir.heavy.withSize(12.0)

    //App table view
    let systemTableViewCell = UIFont.Avenir.medium.withSize(15.0)
    let systemTableViewCellMarkDescription = UIFont.Avenir.medium.withSize(14.0)

    //Restore pending view
    let restorePendingViewTitle = UIFont.Avenir.light.withSize(18.0)
    let restorePendingViewDescription = UIFont.Avenir.medium.withSize(14.0)

    //Settings
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
    let settingsPassword = UIFont.Avenir.roman.withSize(14.0)
    let settingsPasswordWarning = UIFont.Avenir.heavy.withSize(13.0)
}

struct Sizes {
    let appSidePadding: CGFloat = 25 //TODO maybe adjust for smaller phones
    //TODO move other constants here
}

struct Transitions {
    var pullDownOpen: CATransition {
        let transition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromBottom

        return transition
    }

    var pushUpClose: CATransition {
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.reveal
        transition.subtype = CATransitionSubtype.fromTop

        return transition
    }
}
