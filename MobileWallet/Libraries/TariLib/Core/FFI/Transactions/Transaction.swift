//  Transaction.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 26/09/2022
	Using Swift 5.0
	Running on macOS 12.4

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

enum TransactionStatus: Int32 {
    case unknown = -2
    case txNullError = -1
    case completed
    case broadcast
    case minedUnconfirmed
    case imported
    case pending
    case coinbase
    case minedConfirmed
    case rejected
    case oneSidedUnconfirmed
    case oneSidedConfirmed
    case queued
    case coinbaseUnconfirmed
    case coinbaseConfirmed
    case coinbaseNotInBlockChain
}

protocol Transaction {
    var identifier: UInt64 { get throws }
    var amount: UInt64 { get throws }
    var isOutboundTransaction: Bool { get throws }
    var status: TransactionStatus { get throws }
    var message: String { get throws }
    var timestamp: UInt64 { get throws }
    var address: TariAddress { get throws }
    var isCancelled: Bool { get }
    var isPending: Bool { get }
}

extension Transaction {

    var isOneSidedPayment: Bool {
        get throws {
            let status = try status
            return status == .oneSidedConfirmed || status == .oneSidedUnconfirmed
        }
    }

    var isCoinbase: Bool {
        get throws {
            let status = try status
            return status == .coinbase || status == .coinbaseUnconfirmed || status == .coinbaseConfirmed || status == .coinbaseNotInBlockChain
        }
    }

    var formattedTimestamp: String {
        get throws { Date(timeIntervalSince1970: Double(try timestamp)).relativeDayFromToday() ?? "" }
    }
}

extension Array where Element == Transaction {

    func filterDuplicates() -> Self {

        var uniqueTransactions: Self = []

        forEach {
            guard let identifier = try? $0.identifier, uniqueTransactions.first(where: { (try? $0.identifier) == identifier }) == nil else { return }
            uniqueTransactions.append($0)
        }

        return uniqueTransactions
    }
}
