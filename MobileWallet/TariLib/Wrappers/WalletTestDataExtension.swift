//  WalletTestData.swift

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

extension Wallet {
    func generateTestData() throws {
        let didGenerateData = wallet_test_generate_data(self.pointer)

        if !didGenerateData {
            throw WalletErrors.generateTestData
        }
    }

    func generateTestReceiveTransaction() throws {
        let didCreateTestReceiveTransaction = wallet_test_receive_transaction(self.pointer)

        if !didCreateTestReceiveTransaction {
            throw WalletErrors.generateTestReceiveTransaction
        }
    }

    func testTransactionBroadcast(pendingInboundTransaction: PendingInboundTransaction) throws {
        let didTestTransactionBroadcast = wallet_test_transaction_broadcast(self.pointer, pendingInboundTransaction.pointer)

        if !didTestTransactionBroadcast {
            throw WalletErrors.testTransactionBroadcast
        }
    }

    func testTransactionMined(completedTransaction: CompletedTransaction) throws {
        let didCompleteTransaction = wallet_test_mined(self.pointer, completedTransaction.pointer)

        if !didCompleteTransaction {
            throw WalletErrors.testTransactionMined
        }
    }
}
