//  WalletTransactions.swift

/*
    Package MobileWallet
    Created by Jason van den Berg on 2020/05/19
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

extension Wallet {
    var completedTransactions: (CompletedTransactions?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            CompletedTransactions(completedTransactionsPointer: wallet_get_completed_transactions(pointer, error))

        })
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var cancelledTransactions: (CompletedTransactions?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            CompletedTransactions(completedTransactionsPointer: wallet_get_cancelled_transactions(pointer, error), isCancelled: true)
        })
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var pendingOutboundTransactions: (PendingOutboundTransactions?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            PendingOutboundTransactions(
            pendingOutboundTransactionsPointer: wallet_get_pending_outbound_transactions(pointer, error))

        })
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var pendingInboundTransactions: (PendingInboundTransactions?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            PendingInboundTransactions(
            pendingInboundTransactionsPointer: wallet_get_pending_inbound_transactions(pointer, error))

        })
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    var groupedCompletedAndCancelledTransactions: ([[CompletedTransaction]], Error?) {
        let (completedTransactions, completedError) = self.completedTransactions
        guard completedError == nil else {
            return ([], completedError)
        }

        let (cancelledTransactions, cancelledError) = self.cancelledTransactions
        guard cancelledError == nil else {
            return ([], cancelledError)
        }

        let (completedList, completedListError) = completedTransactions!.list
        if completedListError != nil {
            return ([], completedListError)
        }

        let (cancelledList, cancelledListError) = cancelledTransactions!.list
        if cancelledListError != nil {
            return ([], cancelledListError)
        }

        var ungroupedTxs = completedList
        ungroupedTxs.append(contentsOf: cancelledList)

        let grouped = ungroupedTxs.groupSort { (tx) -> Date in
            let (date, error) = tx.date
            if error != nil {
                //TOOD figure out a way to handle a missing timestamp error inside this callback
                return Date()
            }

            return date!
        }

        return (grouped, nil)
    }
}
