//  Transaction.swift

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

struct Transaction {
    let icon: UIImage
    let userName: String
    let description: String
    let value: UInt64
    let date: Date
    let sign: ValueSign
}

var dummyTransactions: [[Transaction]] {
    get {
        var txs: [Transaction] = []
        var sortedTxs: [[Transaction]] = []

        let dummyIconNames = [
            Theme.shared.transactionIcons.food,
            Theme.shared.transactionIcons.game,
            Theme.shared.transactionIcons.thanks,
            Theme.shared.transactionIcons.transfer,
            Theme.shared.transactionIcons.drinks,
            Theme.shared.transactionIcons.services
        ]

        var dummyIconNameIndex = 0

        for n in 1...25 {
            var value = n * 123456789
            var sign: ValueSign = .positive
            var date = Date()

            if n % 2 == 0 {
                sign = .negative
            }

            if value == 0 {
                value = 120
            }

            if n == 4 || n == 7 || n == 3 || n == 8 {
                date = DateConfig.mockPastDate(byDayValue: n)
            }

            dummyIconNameIndex += 1
            if dummyIconNameIndex >= dummyIconNames.count {
                dummyIconNameIndex = 0
            }

            let icon = dummyIconNames[dummyIconNameIndex]

            txs.append(Transaction(icon: icon, userName: "Username_\(n * 999)", description: "Payment for \(n) tacos", value: UInt64(value), date: date, sign: sign))
//                txs.sort(by: {$0.date < $1.date})
            sortedTxs = txs.groupSort(ascending: false, byDate: { $0.date })
        }
        return sortedTxs
    }
}
