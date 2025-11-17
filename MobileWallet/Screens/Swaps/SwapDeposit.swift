//  SwapDeposit.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 29.10.2025
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

import SwiftUI

struct SwapDeposit: View {
    @AppStorage("swapInProgressId") var swapInProgressId: String?
    @Environment(SheetRouter.self) var router
    @Environment(\.dismiss) var dismiss
    @State var isQrHidden = true
    @State var transaction: ExolixTransactionResponse?
    @State var presentedTransactionProgress: ExolixTransactionResponse?
    @State var isTransactionCancelled = false
    @State var errorMessage: String?
    
    let exolix: Exolix
    let request: ExolixConfirmation
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Send the exact amount to the address below in one transaction")
                    .headingLarge()
                    .foregroundStyle(.primaryText)
                    .multilineTextAlignment(.leading)
                depositInfo
            }
            Text("Send funds to the address above only once.")
                .headingSmall()
                .foregroundStyle(.successDark)
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.systemSecondaryGreen, stroke: .successDark)
                }
                .padding(.top, 8)
            Spacer()
            
            TariButton("Cancel transaction", style: .destructiveText, size: .medium) {
                swapInProgressId = nil
                router.isSwapPresented = false
            }
        }
        .padding(.top, 40)
        .padding([.horizontal, .bottom], 24)
        .frame(maxWidth: .infinity)
        .background(Color.secondaryBackground)
        .navigationBarBackButtonHidden()
        .toolbar {
            toolbarTitle("Send funds")
            toolbarBackItem { dismiss() }
        }
        .alert(title: "Exolix error", message: $errorMessage)
        .navigationDestination(item: $presentedTransactionProgress) {
            SwapProgress(exolix: exolix, transaction: $0)
        }
        .onAppear { load() }
        .onDisappear {
            isTransactionCancelled = true
        }
    }
}

private extension SwapDeposit {
    var depositInfo: some View {
        VStack(spacing: 14) {
            if let transaction {
                VStack(alignment: .leading, spacing: 4) {
                    depositItem("You need to send",
                        value: "\(transaction.amount) \(transaction.coinFrom.coinCode)",
                        copy: "\(transaction.amount)",
                        subtitle: transaction.coinFrom.networkName
                    )
                }
                VStack(alignment: .leading, spacing: 4) {
                    depositItem("To Exolix address", value: transaction.depositAddress)
                }
                if let depositId = transaction.depositExtraId {
                    depositItem("Deposit id", value: depositId)
                }
                if isQrHidden {
                    TariButton("Show QR Code", style: .primary, size: .medium) {
                        withAnimation {
                            isQrHidden.toggle()
                        }
                    }
                } else {
                    QRImage(transaction.depositAddress)
                        .frame(square: 180)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: 160)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primaryBackground)
        }
    }
    
    func depositItem(_ header: String, value: String, copy copyValue: String? = nil, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(header)
                .headingSmall()
                .foregroundStyle(.secondaryText)
            HStack(spacing: 14) {
                Text(value)
                    .body2()
                    .foregroundStyle(.primaryText)
                if let subtitle {
                    Text(subtitle)
                        .body2()
                        .foregroundStyle(.secondaryText)
                }
                Spacer()
                copy(copyValue ?? value)
            }
        }
    }
    
    func copy(_ value: String) -> some View {
        CopyButton(value: value, color: .secondaryMain)
    }
}
