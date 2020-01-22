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

struct Colors: Loopable {
    let actionButtonBackgroundSimple = UIColor(named: "ActionButtonBackgroundSimple")
    let actionButtonBackgroundGradient1 = UIColor(named: "ActionButtonBackgroundGradient1")
    let actionButtonBackgroundGradient2 = UIColor(named: "ActionButtonBackgroundGradient2")

    let transactionTableBackground = UIColor(named: "TransactionTableBackground")
    let splashBackground = UIColor(named: "SplashBackground")
    let appBackground = UIColor(named: "AppBackground")

    //Home screen
    let homeScreenBackground = UIColor(named: "HomeScreenBackground")
    let homeScreenTotalBalanceLabel = UIColor(named: "HomeScreenTotalBalanceLabel")
    let homeScreenTotalBalanceValueLabel = UIColor(named: "HomeScreenTotalBalanceLabel")
    let floatingPanelGrabber = UIColor(named: "FloatingPanelGrabber")
    let qrButtonBackground = UIColor(named: "QRButtonBackground")

    //Transaction cell
    let transactionCellUsername = UIColor(named: "TransactionCellUsername")
    let transactionCellDescription = UIColor(named: "TransactionCellDescription")
    let transactionCellValueNegativeBackground = UIColor(named: "TransactionCellValueNegativeBackground")
    let transactionCellValuePositiveBackground = UIColor(named: "TransactionCellValuePositiveBackground")
    let transactionCellValueNegativeText = UIColor(named: "TransactionCellValueNegativeText")
    let transactionCellValuePositiveText = UIColor(named: "TransactionCellValuePositiveText")
    let transactionSmallSubheadingLabel = UIColor(named: "SmallSubheading")

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

    //Feedback
    let feedbackPopupBackground = UIColor(named: "FeedbackScreenBackground")
    let errorFeedbackPopupTitle = UIColor(named: "Heading")
    let errorFeedbackPopupDescription = UIColor(named: "SmallSubheading")
}

struct Fonts: Loopable {
    let splashTestnetFooterLabel = UIFont(name: "AvenirLTStd-Heavy", size: 9.0)
    let actionButton = UIFont(name: "AvenirLTStd-Heavy", size: 16.0)

    //Home screen
    let homeScreenTotalBalanceLabel = UIFont(name: "AvenirLTStd-Roman", size: 14.0)
    let homeScreenTotalBalanceValueLabel = UIFont(name: "AvenirLTStd-Black", size: 39.0)
    let homeScreenTotalBalanceValueLabelDecimals = UIFont(name: "AvenirLTStd-Black", size: 15.6)

    //Transaction cell
    let transactionCellUsernameLabel = UIFont(name: "AvenirLTStd-Heavy", size: 13.0)
    let transactionCellDescriptionLabel = UIFont(name: "AvenirLTStd-Roman", size: 12.0)
    let transactionCellValueLabel = UIFont(name: "AvenirLTStd-Black", size: 12.0)
    let transactionDateValueLabel = UIFont(name: "AvenirLTStd-Medium", size: 12.0)

    //View transaction screen
    let transactionScreenCurrencyValueLabel = UIFont(name: "AvenirLTStd-Black", size: 90.0)
    let transactionScreenSubheadingLabel = UIFont(name: "AvenirLTStd-Medium", size: 13.0)
    let transactionScreenTextLabel = UIFont(name: "AvenirLTStd-Roman", size: 14.0)
    let transactionScreenTxIDLabel = UIFont(name: "AvenirLTStd-Roman", size: 13.0)
    let transactionListEmptyTitleLabel = UIFont(name: "AvenirLTStd-Black", size: 33.0)
    let transactionListEmptyMessageLabel = UIFont(name: "AvenirLTStd-Medium", size: 13.0)

    //Navigation bar
    let navigationBarTitle = UIFont(name: "AvenirLTStd-Heavy", size: 16.5) //Design spec size is 14.0

    //Popup User feedback
    let errorFeedbackPopupTitle = UIFont(name: "AvenirLTStd-Light", size: 18)
    let errorFeedbackPopupDescription = UIFont(name: "AvenirLTStd-Medium", size: 14)
}

struct Images: Loopable {
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
    let close = UIImage(named: "Close")

    //Background images
    let homeBackgroundImage = UIImage(named: "HomePattern")

    //Empty state
    let emptyStateTransactionList = UIImage(named: "EmptyStateTransactions")
}

struct Theme {
    static let shared = Theme()

    //NOTE: Any new theme properties must be added to tests to ensure all assets are included before deployment

    let colors = Colors()
    let images = Images()
    let fonts = Fonts()

    let transactionIcons = Images() //FIXME delete this and change all references to it
}
