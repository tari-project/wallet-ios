//  FormattedTransaction.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 07.07.2025
	Using Swift 6.0
	Running on macOS 15.5

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

import SwiftUI

struct FormattedTransaction: Identifiable, Hashable {
    var id: UInt64
    let emojiId: String
    let titleComponents: [StylizedLabel.StylizedText]
    let timestamp: TimeInterval
    let amount: AmountBadge.ViewModel
    let status: String?
    let note: String?
    
    var formattedTimestamp: String {
        Date(timeIntervalSince1970: timestamp).relativeDayFromToday() ?? ""
    }
    
    var title: String {
        titleComponents.map { $0.text }.joined(separator: " ")
    }
    
    var formattedAmount: NSAttributedString {
        var signString = NSAttributedString()
        if amount.valueType == .positive {
            signString = NSAttributedString(string: "+ ", attributes: [.foregroundColor: UIColor.systemGreen])
        } else if amount.valueType == .negative {
            signString = NSAttributedString(string: "- ", attributes: [.foregroundColor: UIColor.systemRed])
        }
        let valueString = amount.amount ?? ""
        let amount = NSAttributedString(
            string: valueString.filter { $0 != "-" && $0 != " " && $0 != "+"} + " " + NetworkManager.shared.currencySymbol,
            attributes: [.foregroundColor: UIColor.primaryText]
        )
        let amountText =  NSMutableAttributedString()
        amountText.append(signString)
        amountText.append(amount)
        return amountText
    }
}
