//  Swaps.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 14.10.2025
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

extension Swaps {
    enum FieldFocus: Hashable {
        case amount, address
    }
}

struct Swaps: View {
    @Environment(\.dismiss) var dismiss
    @FocusState var fieldFocus: FieldFocus?
    @State var exolix = Exolix.shared
    @State var availableBalance: MicroTari?
    @State var amount = (0.1).formatted(maxDecimals: 1)
    @State var amountError: String?
    @State var withdrawalAddress = ""
    @State var withdrawalAddressError: String?
    @State var xtmCurrency: ExolixCurrency?
    @State var xtmNetwork: ExolixNetwork?
    @State var externalCurrency: ExolixCurrency?
    @State var externalNetwork: ExolixNetwork?
    @State var rate: ExolixRate?
    @State var errorMinAmount: Double?
    @State var errorMaxAmount: Double?
    @State var isFixedRate = false
    @State var isBuyingXtm = true
    @State var isLoading = true
    @State var isCurrencySelectionPresented = false
    @State var presentedDeposit: ExolixConfirmation?
    @State var presentedConfirmation: ExolixConfirmation?
    @State var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    sourceCurrency
                    reverseDirection
                }
                targetCurrency
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
        }
        .refreshable {
            updateRate()
        }
        .safeAreaInset(edge: .bottom) {
            TariButton("Next Step", style: .primary, size: .large) {
                swap()
            }
            .disabled(amount.isEmpty || amountError != nil || withdrawalAddressError != nil || externalCurrency == nil || rate == nil || (!isBuyingXtm && withdrawalAddress.isEmpty))
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .overlay(alignment: .bottom) {
            if fieldFocus == nil {
                ExolixLogo()
                    .padding(.bottom, 80)
            }
        }
        .background(Color.secondaryBackground)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { UIApplication.shared.hideKeyboard() }
        .toolbar {
            toolbarTitle("Select Pair")
            toolbarBackItem { dismiss() }
        }
        .alert(title: "Exolix error", message: $errorMessage)
        .navigationDestination(item: $presentedDeposit) {
            SwapDeposit(request: $0)
        }
        .navigationDestination(item: $presentedConfirmation) {
            SwapConfirmation(sellRequest: $0)
        }
        .fullScreenCover(isPresented: $isCurrencySelectionPresented) {
            SelectSwapCurrency() {
                select(currency: $0, network: $1)
            }
        }
        .onChange(of: amount) {
            updateAmount()
            updateRate()
        }
        .onChange(of: withdrawalAddress) {
            validateWithdrawalAddress()
        }
        .onChange(of: externalCurrency) {
            updateRate()
            validateWithdrawalAddress()
        }
        .onChange(of: isFixedRate) {
            updateRate()
        }
        .onReceive(Tari.mainWallet.walletBalance.$balance) {
            update(walletBalance: $0)
        }
        .onAppear { load() }
    }
}

private extension Swaps {
    var sourceCurrency: some View {
        VStack(spacing: 20) {
            Text("You send")
                .headingSmall()
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading) {
                if isBuyingXtm {
                    externalSource
                } else {
                    xtmSource
                }
                if let amountError {
                    Text(amountError)
                        .body2()
                        .foregroundStyle(.errorMain)
                }
                amountRange(min: minAmount, max: maxAmount)
            }
            .animation(.easeInOut, value: rate)
        }
    }
    
    var xtmSource: some View {
        HStack {
            amountField
            xtmTokenPicker
        }
    }

    func amountRange(min: Double?, max: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !isBuyingXtm, let availableBalance {
                Text("Available: \(availableBalance.taris.formatted()) XTM")
                    .body()
                    .foregroundStyle(.secondaryText)
            }
            if let min {
                rangeValue("Min", value: min)
            }
            if let max {
                rangeValue("Max", value: max)
            }
        }
        .frame(minHeight: 50, alignment: .top)
    }
    
    func rangeValue(_ label: String, value: Double) -> some View {
        Button(action: { amount = value.formatted().replacingOccurrences(of: " ", with: "") }) {
            HStack {
                Text("\(label):")
                    .body()
                    .foregroundStyle(.secondaryText)
                Text(value.formatted())
                    .headingMedium()
                    .foregroundStyle(.primaryText)
            }
        }
    }
    
    var externalSource: some View {
        VStack {
            if let externalCurrency {
                externalSourceAmount(currency: externalCurrency, network: externalNetwork)
            } else {
                externalSourceAmount(currency: .placeholder, network: .placeholder)
                    .redacted(reason: .placeholder)
            }
        }
    }
    
    func externalSourceAmount(currency: ExolixCurrency, network: ExolixNetwork?) -> some View {
        HStack {
            amountField
            tokenPicker(currency: currency, network: network)
        }
    }
    
    var targetCurrency: some View {
        VStack(spacing: 20) {
            Text("You receive")
                .headingSmall()
                .frame(maxWidth: .infinity)
            if isBuyingXtm {
                xtmTarget
            } else {
                externalTarget
            }
            fixedRateToggle
        }
    }
    
    var xtmTarget: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(rate?.toAmount.formatted() ?? "0")")
                    .heading2XL()
                    .foregroundStyle(.secondaryMain)
                Spacer()
                xtmTokenPicker
            }
            targetRate
                .padding(.bottom, 32)
            VStack(alignment: .leading, spacing: 12) {
                Text("Destination Address (XTM)")
                    .body()
                    .foregroundStyle(.primaryText)
                Text("Your new XTM will be sent to your current Tari wallet address on mobile.")
                    .body2()
                    .foregroundStyle(.primaryText)
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.accentBackground, stroke: .secondaryMain)
                    }
            }
        }
    }
    
    var externalTarget: some View {
        VStack(alignment: .leading) {
            HStack {
                if let externalCurrency {
                    Text("\(rate?.toAmount.formatted() ?? "0")")
                        .heading2XL()
                        .foregroundStyle(.secondaryMain)
                    Spacer()
                    tokenPicker(currency: externalCurrency, network: externalNetwork)
                }
            }
            targetRate
            HStack {
                Spacer()
                Button(action: scanQR) {
                    Image(.scanQR)
                        .renderingMode(.template)
                        .foregroundStyle(.primaryText)
                }
            }
            TariTextEditor($withdrawalAddress, placeholder: "Withdrawal address", error: withdrawalAddressError)
                .focused($fieldFocus, equals: .address)
        }
    }
    
    @ViewBuilder
    var targetRate: some View {
        if let rate, let externalCurrency {
            Text(isBuyingXtm
                 ? "1 \(externalCurrency.code) ≈ \(rate.rate.formatted()) XTM"
                 : "1 XTM ≈ \(rate.rate.formatted(maxDecimals: 10)) \(externalCurrency.code)"
            )
            .body()
            .foregroundStyle(.primaryText)
        }
    }
    
    func tokenPicker(currency: ExolixCurrency, network: ExolixNetwork?) -> some View {
        TokenPicker(
            icon: currency.icon,
            code: currency.code,
            network: network?.network
        ) {
            isCurrencySelectionPresented = true
        }
    }
    
    var xtmTokenPicker: some View {
        TokenPicker(icon: xtmNetwork?.icon, code: "XTM", network: xtmNetwork?.name ?? "Tari", action: nil)
    }
    
    var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(text: $amount, prompt: .placeholder("Amount to send")) { }
                .keyboardType(.decimalPad)
                .focused($fieldFocus, equals: .amount)
                .textFieldBorder()
        }
    }
    
    var fixedRateToggle: some View {
        HStack {
            Toggle("", isOn: $isFixedRate)
                .labelsHidden()
                .foregroundStyle(.secondary)
            Text("Fixed rate")
                .body2()
                .foregroundStyle(.primaryText)
            Spacer()
        }
    }
    
    var reverseDirection: some View {
        HStack(spacing: 24) {
            VStack { Divider() }
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.primaryMain)
                } else {
                    Button(action: reverseSwapDirection) {
                        Image(.swap)
                    }
                }
            }
            .frame(square: 44)
            
            VStack { Divider() }
        }
    }
}

#Preview {
    Swaps()
}
