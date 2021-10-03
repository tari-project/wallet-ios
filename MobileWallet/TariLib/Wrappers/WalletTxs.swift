//  WalletTxs.swift

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

    func completedTransactions() throws -> CompletedTxs {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode) {
            CompletedTxs(completedTxsPointer: wallet_get_completed_transactions(pointer, $0))
        }

        guard errorCode == 0 else { throw WalletErrors.generic(errorCode) }
        return result
    }

    func cancelledTransactions() throws -> CompletedTxs {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode) {
            CompletedTxs(completedTxsPointer: wallet_get_cancelled_transactions(pointer, $0), isCancelled: true)
        }

        guard errorCode == 0 else { throw WalletErrors.generic(errorCode) }
        return result
    }

    func pendingOutboundTransactions() throws -> PendingOutboundTxs {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode) {
            PendingOutboundTxs(pendingOutboundTxsPointer: wallet_get_pending_outbound_transactions(pointer, $0))
        }

        guard errorCode == 0 else { throw WalletErrors.generic(errorCode) }
        return result
    }

    func pendingInboundTransactions() throws -> PendingInboundTxs {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode) {
            PendingInboundTxs(pendingInboundTxsPointer: wallet_get_pending_inbound_transactions(pointer, $0))
        }

        guard errorCode == 0 else { throw WalletErrors.generic(errorCode) }
        return result
    }

    @available(*, deprecated, message: "Please use completedTransactions() instead")
    var completedTxs: (CompletedTxs?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            CompletedTxs(completedTxsPointer: wallet_get_completed_transactions(pointer, error))

        })
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    @available(*, deprecated, message: "Please use pendingOutboundTransactions() instead")
    var pendingOutboundTxs: (PendingOutboundTxs?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            PendingOutboundTxs(
            pendingOutboundTxsPointer: wallet_get_pending_outbound_transactions(pointer, error))

        })
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }

    @available(*, deprecated, message: "Please use pendingInboundTransactions() instead")
    var pendingInboundTxs: (PendingInboundTxs?, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            PendingInboundTxs(
            pendingInboundTxsPointer: wallet_get_pending_inbound_transactions(pointer, error))

        })
        guard errorCode == 0 else {
            return (nil, WalletErrors.generic(errorCode))
        }
        return (result, nil)
    }
}
