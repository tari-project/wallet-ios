//  SelectSwapCurrency.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 15.10.2025
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

struct SelectSwapCurrency: View {
    @Environment(\.dismiss) var dismiss
    @State var currencies = [ExolixCurrency]()
    @State var totalCurrencyCount: Int?
    @State var filter = ""
    @State var page: Int = 1
    @State var isLoading = true
    
    let exolix = Exolix.shared
    let select: (ExolixCurrency, ExolixNetwork) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(currencies) { currency in
                        ForEach(currency.networks) { network in
                            item(currency: currency, network: network)
                        }
                    }
                    if totalCurrencyCount == nil || currencies.count < (totalCurrencyCount ?? 0) {
                        if isLoading {
                            ProgressView()
                        } else {
                            ScrollTrigger { loadMore() }
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .background(Color.secondaryBackground)
            .overlay {
                if totalCurrencyCount == 0 {
                    Text("No token found")
                        .body2()
                }
            }
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarTitle("Select Currency")
                toolbarCloseItem { dismiss() }
            }
        }
        .searchable(text: $filter)
        .onChange(of: filter) { load() }
        .onAppear { load() }
    }
    
    func item(currency: ExolixCurrency, network: ExolixNetwork) -> some View {
        Button(action: { select(currency, network); dismiss() }) {
            VStack(spacing: 2) {
                HStack {
                    TokenIcon(currency.icon, size: 32)
                    VStack(alignment: .leading) {
                        Text(currency.code + ": " + currency.name)
                            .body()
                            .foregroundStyle(.primaryText)
                        Text(network.name)
                            .body2()
                            .foregroundStyle(.secondaryText)
                    }
                    .multilineTextAlignment(.leading)
                    Spacer()
                }
                Divider()
            }
        }
    }
}

private extension SelectSwapCurrency {
    func load() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                page = 1
                let response = try await exolix.getCurrencies(page: 1, size: 20, filter: filter)
                currencies = response.currencies
                totalCurrencyCount = response.count
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func loadMore() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                page += 1
                let moreCurrencies = try await exolix.getCurrencies(page: page, size: 20, filter: filter).currencies
                currencies.append(contentsOf: moreCurrencies)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
