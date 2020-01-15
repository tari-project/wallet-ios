//  PendingInboundTransactions.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/18
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

import Foundation

enum PendingInboundTransactionsErrors: Error {
    case pendingInboundTransactionNotFound
    case generic(_ errorCode: Int32)
}

class PendingInboundTransactions: TransactionsProtocol {
    typealias Tx = PendingInboundTransaction

    private var ptr: OpaquePointer

    var pointer: OpaquePointer {
        return ptr
    }

    var count: (UInt32, Error?) {
        var errorCode: Int32 = -1
        let result = pending_inbound_transactions_get_length(ptr, UnsafeMutablePointer<Int32>(&errorCode))

        return (result, errorCode != 0 ? PendingInboundTransactionsErrors.generic(errorCode) : nil)
    }

    init(pendingInboundTransactionsPointer: OpaquePointer) {
        ptr = pendingInboundTransactionsPointer
    }

    var list: ([PendingInboundTransaction], Error?) {
        let (count, countError) = self.count
        guard countError == nil else {
            return ([], countError)
        }

        var list: [PendingInboundTransaction] = []

        if count > 0 {
            for n in 0...count - 1 {
                do {
                    let tx = try self.at(position: n)
                    list.append(tx)
                } catch {
                    return ([], error)
                }
            }
        }

        let sortedList = list.sorted(by: { $0.localDate.0?.compare($1.localDate.0!) == .orderedDescending })

        return (sortedList, nil)
    }

    func at(position: UInt32) throws -> PendingInboundTransaction {
        var errorCode: Int32 = -1
        let pendingInboundTransactionPointer = pending_inbound_transactions_get_at(ptr, position, UnsafeMutablePointer<Int32>(&errorCode))
        guard errorCode == 0 else {
            throw PendingInboundTransactionsErrors.generic(errorCode)
        }

        if pendingInboundTransactionPointer == nil {
            throw PendingInboundTransactionsErrors.pendingInboundTransactionNotFound
        }

        return PendingInboundTransaction(pendingInboundTransactionPointer: pendingInboundTransactionPointer!)
    }

    deinit {
        pending_inbound_transactions_destroy(ptr)
    }
}
