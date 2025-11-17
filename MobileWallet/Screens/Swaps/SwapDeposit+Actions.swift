//  SwapDeposit+Actions.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 30.10.2025
	Using Swift 6.0
	Running on macOS 26.0

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

extension SwapDeposit: SwapTransactionMonitoring {
    var latestTransaction: ExolixTransactionResponse? {
        get { transaction }
        nonmutating set { transaction = newValue }
    }
    
    var isTransactionProcessed: Bool { transaction?.isFunded ?? false }
    
    func finaliseTransaction() {
        presentedTransactionProgress = transaction
    }
}

extension SwapDeposit {
    func load() {
        Task {
            do {
                let response = try await exolix.postTransaction(
                    request: request,
                    refundAddress: Tari.mainWallet.address.components.fullRaw,
                    refundExtraId: nil
                )
                swapInProgressId = response.id
                if response.isFunded {
                    presentedTransactionProgress = response
                } else {
                    await monitorTransactionStatus(transactionId: response.id)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

extension ExolixTransactionResponse {
    var isFunded: Bool {
        switch status {
        case .success, .refunded, .confirmation, .confirmed, .exchanging, .sending, .overdue:
            return true
        case .wait, .none:
            return false
        }
    }
    
    var isProcessed: Bool {
        switch status {
        case .wait, .confirmation, .confirmed, .exchanging, .sending, .none:
            return false
        case .success, .refunded, .overdue:
            return true
        }
    }
}
