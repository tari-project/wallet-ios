//  ErrorDescriptions.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/29
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

extension WalletErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .generic(let code):
            //TODO create a map of Tari errors from rust
            return  "\(localized("wallet.error.generic_code")) \(code)."
        case .insufficientFunds(let microTariSpendable):
            return "\(localized("wallet.error.insufficient_funds")) \(microTariSpendable.formatted)."
        case .addUpdateContact:
            return localized("wallet.error.add_update_contact")
        case .removeContact:
            return localized("wallet.error.remove_contact")
        case .addOwnContact:
            return localized("wallet.error.add_own_contact")
        case .invalidPublicKeyHex:
            return localized("wallet.error.invalid_public_key_hex")
        case .generateTestData:
            return localized("wallet.error.test_data")
        case .generateTestReceiveTx:
            return localized("wallet.error.test_receieve_tx")
        case .sendingTx:
            return localized("wallet.error.send_tx")
        case .testTxBroadcast:
            return localized("wallet.error.broadcast")
        case .testTxMined:
            return localized("wallet.error.mine_tx")
        case .testSendCompleteTx:
            return localized("wallet.error.test_tx")
        case .completedTxById:
            return localized("wallet.error.find_completed_tx")
        case .cancelledTxById:
            return localized("wallet.error.find_canceled_tx")
        case .walletNotInitialized:
            return localized("wallet.error.wallet_not_initialized")
        case .invalidSignatureAndNonceString:
            return localized("wallet.error.invalid_signature")
        case .cancelNonPendingTx:
            return localized("wallet.error.cancel_non_pending_tx")
        case .txToCancel:
            return localized("wallet.error.fetch_txs_to_cancel")
        case .notEnoughFunds:
            return nil
        case .fundsPending:
            return nil
        }
    }
}

extension KeyServerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .server(let statusCode, let message):
            if message != nil {
                return message
            }

            return localized("key_server.error.server") + " \(statusCode)."
        case .unknown:
            return localized("key_server.error.unknown")
        case .invalidSignature:
            return localized("key_server.error.invalid_signature")
        case .tooManyAllocationRequests:
            return localized("key_server.error.too_many_allocation_requests")
        case .missingResponse:
            return localized("key_server.error.missing_response")
        case .responseInvalid:
            return localized("key_server.error.response_invalid")
        }
    }
}

//TODO add the other error enums
