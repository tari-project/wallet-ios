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
            return  "\(NSLocalizedString("wallet.error.generic_code", comment: "Wallet error")) \(code)."
        case .insufficientFunds(let microTariSpendable):
            return "\(NSLocalizedString("wallet.error.insufficient_funds", comment: "Wallet error")) \(microTariSpendable.formatted)."
        case .addUpdateContact:
            return NSLocalizedString("wallet.error.add_update_contact", comment: "Wallet error")
        case .removeContact:
            return NSLocalizedString("wallet.error.remove_contact", comment: "Wallet error")
        case .addOwnContact:
            return NSLocalizedString("wallet.error.add_own_contact", comment: "Wallet error")
        case .invalidPublicKeyHex:
            return NSLocalizedString("wallet.error.invalid_public_key_hex", comment: "Wallet error")
        case .generateTestData:
            return NSLocalizedString("wallet.error.test_data", comment: "Wallet error")
        case .generateTestReceiveTx:
            return NSLocalizedString("wallet.error.test_receieve_tx", comment: "Wallet error")
        case .sendingTx:
            return NSLocalizedString("wallet.error.send_tx", comment: "Wallet error")
        case .testTxBroadcast:
            return NSLocalizedString("wallet.error.broadcast", comment: "Wallet error")
        case .testTxMined:
            return NSLocalizedString("wallet.error.mine_tx", comment: "Wallet error")
        case .testSendCompleteTx:
            return NSLocalizedString("wallet.error.test_tx", comment: "Wallet error")
        case .completedTxById:
            return NSLocalizedString("wallet.error.find_completed_tx", comment: "Wallet error")
        case .cancelledTxById:
            return NSLocalizedString("wallet.error.find_canceled_tx", comment: "Wallet error")
        case .walletNotInitialized:
            return NSLocalizedString("wallet.error.wallet_not_initialized", comment: "Wallet error")
        case .invalidSignatureAndNonceString:
            return NSLocalizedString("wallet.error.invalid_signature", comment: "Wallet error")
        case .cancelNonPendingTx:
            return NSLocalizedString("wallet.error.cancel_non_pending_tx", comment: "Wallet error")
        case .txToCancel:
            return NSLocalizedString("wallet.error.fetch_txs_to_cancel", comment: "Wallet error")
        case .notEnoughFunds:
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

            return NSLocalizedString("key_server.error.server", comment: "Tari key server error") + " \(statusCode)."
        case .unknown:
            return NSLocalizedString("key_server.error.unknown", comment: "Tari key server error")
        case .invalidSignature:
            return NSLocalizedString("key_server.error.invalid_signature", comment: "Tari key server error")
        case .tooManyAllocationRequests:
            return NSLocalizedString("key_server.error.too_many_allocation_requests", comment: "Tari key server error")
        case .missingResponse:
            return NSLocalizedString("key_server.error.missing_response", comment: "Tari key server error")
        case .responseInvalid:
            return NSLocalizedString("key_server.error.response_invalid", comment: "Tari key server error")
        }
    }
}

//TODO add the other error enums
