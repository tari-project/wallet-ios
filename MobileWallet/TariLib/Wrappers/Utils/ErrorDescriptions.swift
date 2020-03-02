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
            return  "\(NSLocalizedString("Generic error code:", comment: "Wallet errors")) \(code)."
        case .insufficientFunds(let microTariSpendable):
            return "\(NSLocalizedString("Insufficient funds. Available spendable Tari:", comment: "Wallet errors")) \(microTariSpendable.formatted)."
        case .addUpdateContact:
            return NSLocalizedString("Failed to add/update contact.", comment: "Wallet errors")
        case .removeContact:
            return NSLocalizedString("Failed to remove contact.", comment: "Wallet errors")
        case .addOwnContact:
            return NSLocalizedString("Cannot add your own public key as a contact.", comment: "Wallet errors")
        case .invalidPublicKeyHex:
            return NSLocalizedString("Invalid public key hex.", comment: "Wallet errors")
        case .generateTestData:
            return NSLocalizedString("Failed to generate test data.", comment: "Wallet errors")
        case .generateTestReceiveTransaction:
            return NSLocalizedString("Failed to generate test receieve transaction.", comment: "Wallet errors")
        case .sendingTransaction:
            return NSLocalizedString("Failed to send transaction.", comment: "Wallet errors")
        case .testTransactionBroadcast:
            return NSLocalizedString("Failed to broadcast test transaction.", comment: "Wallet errors")
        case .testTransactionMined:
            return NSLocalizedString("Failed to mine test transaction.", comment: "Wallet errors")
        case .testSendCompleteTransaction:
            return NSLocalizedString("Failed to complete test transaction.", comment: "Wallet errors")
        case .completedTransactionById:
            return NSLocalizedString("Failed to find completed transaction by ID.", comment: "Wallet errors")
        case .walletNotInitialized:
            return NSLocalizedString("Tari wallet not yet initialized", comment: "Wallet errors")
        case .invalidSignatureAndNonceString:
            return NSLocalizedString("Invalid signature created", comment: "Wallet errors")
        }
    }
}

extension TestnetKeyServerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .server(let statusCode, let message):
            if message != nil {
                return message
            }

            return NSLocalizedString("Tari faucet server error. Status code: \(statusCode).", comment: "Tari key server error")
        case .unknown:
            return NSLocalizedString("Unknown Tari faucet error.", comment: "Tari key server error")
        case .invalidSignature:
            return NSLocalizedString("Invalid signature sent to Tari key server.", comment: "Tari key server error")
        case .allCoinsAllAllocated:
            return NSLocalizedString("All coins are allocated.", comment: "Tari key server error")
        case .missingResponse:
            return NSLocalizedString("Missing response from Tari key server.", comment: "Tari key server error")
        case .responseInvalid:
            return NSLocalizedString("Invalid response from Tari key server.", comment: "Tari key server error")
        }
    }
}

//TODO add the other error enums
