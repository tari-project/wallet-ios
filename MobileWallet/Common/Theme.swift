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

//TODO create tests on this to ensure all assets are included in the bundle

struct Colors {
    let sendButtonBackground = UIColor(named: "SendButtonBackground")
    let homeBackground = UIColor(named: "HomeBackground")
    let transactionTableBackground = UIColor(named: "TransactionTableBackground")
    let splashBackground = UIColor(named: "SplashBackground")

    //Transaction cell
    let transactionCellUsername = UIColor(named: "TransactionCellUsername")
    let transactionCellDescription = UIColor(named: "TransactionCellDescription")
    let transactionCellValueNegativeBackground = UIColor(named: "TransactionCellValueNegativeBackground")
    let transactionCellValuePositiveBackground = UIColor(named: "TransactionCellValuePositiveBackground")
    let transactionCellValueNegativeText = UIColor(named: "TransactionCellValueNegativeText")
    let transactionCellValuePositiveText = UIColor(named: "TransactionCellValuePositiveText")
}

struct Fonts {
    let splashTestnetFooterLabel = UIFont(name: "AvenirLTStd-Heavy", size: 9.0)!
    let sendActionButton = UIFont(name: "AvenirLTStd-Heavy", size: 16.0)!

    //Transaction cell
    let transactionCellUsernameLabel = UIFont(name: "AvenirLTStd-Heavy", size: 13.0)!
    let transactionCellDescriptionLabel = UIFont(name: "AvenirLTStd-Roman", size: 12.0)!
    let transactionCellValueLabel = UIFont(name: "AvenirLTStd-Black", size: 12.0)!
}

struct TransactionIcons {
    let food = UIImage(named: "food")!
    let game = UIImage(named: "game")!
    let thanks = UIImage(named: "thanks")!
    let transfer = UIImage(named: "transfer")!
    let drinks = UIImage(named: "drinks")!
    let services = UIImage(named: "services")!
}

class Theme {
    static let shared = Theme()

    let colors = Colors()
    let transactionIcons = TransactionIcons()
    let fonts = Fonts()
}
