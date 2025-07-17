//  Home.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 26.06.2025
	Using Swift 6.0
	Running on macOS 15.5

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
import Combine

struct Home: View {
    @ObservedObject var network = NetworkManager.shared
    @State var activeMiners = " "
    @State var totalBalance = ""
    @State var availableBalance = ""
    @State var isSyncInProgress = false
    @State var isMining = false
    @State var isBalanceHidden = false
    @State var isLoadingTransactions = false
    @State var syncStatus: TariValidationService.SyncStatus = .idle
    @State var recentTransactions = [FormattedTransaction]()
    @State var presentedTransaction: FormattedTransaction?
    @State var isSendPresented = false
    @State var isReceivePresented = false
    
    let walletState: WalletState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    miningStatus
                    wallet
                    recentActivity
                        .padding(.top, 24)
                }
                .padding(16)
            }
            .sceneBackground(.secondaryBackground)
            .toolbar { toolbar }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                load()
            }
            .onReceive(Tari.mainWallet.walletBalance.$balance) {
                update(walletBalance: $0)
            }
            .onReceive(Tari.mainWallet.transactions.$all) {
                update(transactions: $0)
            }
            .onReceive(AppConnectionHandler.shared.connectionMonitor.$syncStatus) {
                update(syncStatus: $0)
            }
            .navigationDestination(item: $presentedTransaction) {
                if let transaction = transaction(for: $0) {
                    TransactionDetails(transaction)
                }
            }
            .navigationDestination(isPresented: $isSendPresented) {
                UISendViewController()
                    .navigationBarBackButtonHidden()
                    .background(Color.secondaryBackground)
            }
            .navigationDestination(isPresented: $isReceivePresented) {
                UIReceiveViewController()
                    .navigationBarBackButtonHidden()
                    .background(Color.secondaryBackground)
            }
        }
    }
}

private extension Home {
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack {
                Text("Tari Universe")
                    .heading2XL()
                    .foregroundStyle(.primaryText)
                connectionStatusTag
            }
        }
    }
    
    var connectionStatusTag: some View {
        Button(action: { AppConnectionHandler.shared.connectionMonitor.showDetailsPopup() }) {
            HStack(spacing: 4) {
                Circle()
                    .foregroundStyle(syncStatus.color)
                    .frame(width: 7, height: 7)
                Divider()
                Text(network.selectedNetwork.presentedName)
                    .headingSmall()
                    .foregroundStyle(.primaryText)
                Text(network.selectedNetwork.version)
                    .headingSmall()
                    .foregroundStyle(.secondaryText)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 6)
            .background {
                Capsule()
                    .fill(.primaryBackground, stroke: .outlined)
            }
            .frame(height: 20)
        }
    }
    
    var miningStatus: some View {
        HStack {
            VStack(alignment: .leading, spacing: -6) {
                Text("Active Miners")
                    .headingSmall()
                    .foregroundStyle(.white.opacity(0.5))
                HStack(spacing: 6) {
                    Image(.minersIcon)
                    Text(activeMiners)
                        .heading2XL()
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            
            Text(isMining ? "You're mining" : "You're not mining")
                .headingSmall()
                .foregroundStyle(isMining ? .systemGreen : .systemRed)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color(UIColor(hex: 0x0E1510)), Color(UIColor(hex: 0x07160B))], // TODO: move to assets
                    startPoint: UnitPoint(x: 0.25, y: 0.5),
                    endPoint: UnitPoint(x: 0.75, y: 0.5)
                ))
        }
    }
    
    var wallet: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                Image(.walletCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text("Wallet Balance")
                            .body()
                            .foregroundStyle(.whiteMain.opacity(0.5))

                        Button(action: { withAnimation { isBalanceHidden.toggle() } }) {
                            Image(.discloseHide)
                        }
                    }
                    Text(isBalanceHidden ? "******* XTM" : "\(totalBalance) XTM")
                        .heading2XL()
                        .foregroundStyle(.whiteMain)
                    HStack(spacing: 6) {
                        Text("Available: \(availableBalance) tXTM")
                            .body()
                            
                        Button(action: showAmountHelp) {
                            Image(.roundedQuestionMark)
                        }
                    }
                    .foregroundStyle(.whiteMain.opacity(0.5))
                }
                .padding(20)
            }
            
            HStack(spacing: 8) {
                TariButton("Send", style: .label, size: .large) {
                    isSendPresented = true
                }
                .disabled(isSyncInProgress)
                
                TariButton("Receive", style: .label, size: .large) {
                    isReceivePresented = true
                }
            }
        }
    }
    
    var recentActivity: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Recent Activity")
                    .headingXL()
                    .foregroundStyle(.primaryText)
                Spacer()
                // TODO: Add sync status
            }
            if !recentTransactions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(recentTransactions) { transaction in
                        Button(action: { presentedTransaction = transaction }) {
                            TransactionItem(transaction: transaction, isBalanceHidden: isBalanceHidden)
                        }
                    }
                    // TODO: view all
                }
            } else if isLoadingTransactions {
                ProgressView()
            } else {
                noActivity
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    var noActivity: some View {
        VStack(spacing: 0) {
            Text("You don’t have any activity yet.")
                .headingLarge()
            Text("Once you receive some tXTM, you’ll see it here.")
                .body2()
        }
        .foregroundStyle(.primaryText)
    }
}

private extension TariValidationService.SyncStatus {
    var color: Color {
        switch self {
        case .syncing: .systemYellow
        case .synced: .successMain
        case .idle, .failed: .systemRed
        }
    }
}

#Preview {
    Home(walletState: .current)
}
