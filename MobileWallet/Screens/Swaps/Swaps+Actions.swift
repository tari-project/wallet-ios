//  Swaps+Actions.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 21.10.2025
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

extension Swaps: QRScaner {
    func scanQR() {
        scanQR(expectedDataTypes: [.text]) { data in
            guard case let .text(text) = data else { return }
            withdrawalAddress = text
        }
    }
}

extension Swaps {
    var minAmount: Double? {
        rate?.minAmount ?? errorMinAmount
    }
    var maxAmount: Double? {
        rate?.maxAmount ?? errorMaxAmount
    }
    
    func load() {
        Task {
            externalCurrency = try await exolix.getCurrencies(page: 1, size: 1).currencies.first
            externalNetwork = externalCurrency?.defaultNetwork
            xtmCurrency = try await exolix.getXtmCurrency()
            xtmNetwork = xtmCurrency?.defaultNetwork // try await exolix.getXtmNetwork()
            isLoading = false
            updateRate()
        }
    }
    
    func select(currency: ExolixCurrency, network: ExolixNetwork) {
        rate = nil
        errorMinAmount = nil
        errorMaxAmount = nil
        externalCurrency = currency
        externalNetwork = network
        updateRate()
    }
    
    func update(walletBalance: WalletBalance) {
        availableBalance = MicroTari(walletBalance.available)
    }
    
    func updateRate() {
        guard let externalCurrency else { return }
        if isBuyingXtm {
            guard amount.double != nil else { return }
            loadRate(from: externalCurrency.code, to: "xtm", amount: amount)
        } else {
            guard (try? MicroTari(tariValue: amount)) != nil else { return }
            loadRate(from: "xtm", to: externalCurrency.code, amount: amount)
        }
    }
    
    func loadRate(from sourceCurrency: String, to targetCurrency: String, amount: String) {
        Task {
            do {
                rate = try await exolix.getRate(
                    from: sourceCurrency,
                    to: targetCurrency,
                    amount: amount.withDecimalDot,
                    rateType: isFixedRate ? .fixed : .float
                )
            } catch {
                if case let ExolixError.rate(error) = error {
                    errorMinAmount = error.minAmount
                    errorMaxAmount = error.maxAmount
                }
                rate = nil
            }
            updateAmount()
        }
    }
    
    func updateAmount() {
        withAnimation {
            do {
                if amount.isEmpty {
                    amountError = nil
                    rate = nil
                } else {
                    if isBuyingXtm {
                        if let tokenAmount = amount.double {
                            validateAmount(tokenAmount)
                        } else {
                            amountError = "Error parsing amount"
                            rate = nil
                        }
                    } else {
                        let microTariAmount = try MicroTari(tariValue: amount)
                        if let availableBalance, microTariAmount < availableBalance {
                            validateAmount(microTariAmount.taris)
                        } else {
                            amountError = "Amount must be less than Available amount"
                        }
                    }
                }
            } catch {
                amountError = "Error parsing amount"
                rate = nil
            }
        }
    }
    
    func validateAmount(_ amount: Double) {
        if let minAmount, amount < minAmount {
            amountError = "Amount must be greater than \(minAmount)"
        } else if let maxAmount, maxAmount < amount {
            amountError = "Amount must be less than \(maxAmount)"
        } else {
            amountError = nil
        }
    }
    
    func validateWithdrawalAddress() {
        guard let addresRegex = externalCurrency?.addresRegex else { return }
        if withdrawalAddress.matches(addresRegex) {
            withdrawalAddressError = nil
        } else {
            withdrawalAddressError = "Invalid address"
        }
    }
    
    func reverseSwapDirection() {
        withAnimation {
            rate = nil
            errorMinAmount = nil
            errorMaxAmount = nil
            fieldFocus = nil
            isBuyingXtm.toggle()
        }
        updateRate()
    }
    
    func swap() {
        guard let xtmCurrency, let xtmNetwork, let externalCurrency, let externalNetwork, let rate,
              let tariAddress = try? Tari.mainWallet.address.components.fullRaw, amount.double != nil
        else { return }
        let rateType = isFixedRate ? ExolixRateType.fixed : .float
        if isBuyingXtm {
            presentedDeposit = ExolixConfirmation(
                coinFrom: externalCurrency,
                networkFrom: externalNetwork,
                coinTo: xtmCurrency,
                networkTo: xtmNetwork,
                amount: amount,
                rate: rate,
                rateType: rateType,
                withdrawalAddress: tariAddress,
                withdrawalExtraId: nil
            )
        } else {
            presentedConfirmation = ExolixConfirmation(
                coinFrom: xtmCurrency,
                networkFrom: xtmNetwork,
                coinTo: externalCurrency,
                networkTo: externalNetwork,
                amount: amount,
                rate: rate,
                rateType: rateType,
                withdrawalAddress: withdrawalAddress,
                withdrawalExtraId: nil
            )
        }
    }
}
