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
        var errorCode: Int32 = -1
        let filePathPointer = UnsafeMutablePointer<Int8>(mutating: (dbPath as NSString).utf8String)!

        let didGenerateData = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_test_generate_data(self.pointer, filePathPointer, error)
        })

        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }

        if !didGenerateData {
            throw WalletErrors.generateTestData
        }
    }

    func generateTestReceiveTx() throws {
        var errorCode: Int32 = -1
        let didCreateTestReceiveTx = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_test_receive_transaction(self.pointer, error)
        })
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        if !didCreateTestReceiveTx {
            throw WalletErrors.generateTestReceiveTx
        }
    }

    func testTxBroadcast(txID: UInt64) throws {
        var errorCode: Int32 = -1
        let didtestTxBroadcast = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_test_broadcast_transaction(
            self.pointer,
            txID,
            error)

        })
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        if !didtestTxBroadcast {
            throw WalletErrors.testTxBroadcast
        }
    }

    func testTxMined(txID: UInt64) throws {
        var errorCode: Int32 = -1
        let didCompleteTx = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_test_mine_transaction(
            self.pointer,
            txID,
            error)}
        )
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        if !didCompleteTx {
            throw WalletErrors.testTxMined
        }
    }

    func testCompleteSend(pendingOutboundTx: PendingOutboundTx) throws {
        var errorCode: Int32 = -1
        let didCompleteTx = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_test_complete_sent_transaction(
            self.pointer,
            pendingOutboundTx.pointer,
            error)}
        )
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        if !didCompleteTx {
            throw WalletErrors.testSendCompleteTx
        }
    }

    func testFinalizedReceivedTx(pendingInboundTx: PendingInboundTx) throws {
        var errorCode: Int32 = -1
        let didCompleteTx = withUnsafeMutablePointer(to: &errorCode, { error in
            wallet_test_finalize_received_transaction(
            self.pointer,
            pendingInboundTx.pointer,
            error)}
        )
        guard errorCode == 0 else {
            throw WalletErrors.generic(errorCode)
        }
        if !didCompleteTx {
            throw WalletErrors.testSendCompleteTx
        }
    }
}
