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

struct Home: View {
    @State var isMining = false
    @State var isBalanceHidden = false
    
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Tari Universe")
                            .heading2XL()
                            .foregroundStyle(.primaryText)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .foregroundStyle(.systemRed)
                                .frame(width: 7, height: 7)
                            Divider()
                            Text("Mainnet")
                                .headingSmall()
                                .foregroundStyle(.primaryText)
                            Text("v4.5.0")
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
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            load()
        }
    }
}

private extension Home {
    var miningStatus: some View {
        HStack {
            VStack(alignment: .leading, spacing: -6) {
                Text("Active Miners")
                    .headingSmall()
                    .foregroundStyle(.white.opacity(0.5))
                HStack(spacing: 6) {
                    Image(uiImage: .minersIcon)
                    Text("123")
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
                    colors: [.green, .black],
                    startPoint: .top,
                    endPoint: .bottom
                ))
        }
    }
    
    var wallet: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: .walletCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text("Wallet Balance")
                            .body()
                            .foregroundStyle(.whiteMain.opacity(0.5))

                        Button(action: { withAnimation { isBalanceHidden.toggle() } }) {
                            Image(uiImage: .discloseHide)
                        }
                    }
                    Text(isBalanceHidden ? "******* XTM" : "0 XTM")
                        .heading2XL()
                        .foregroundStyle(.whiteMain)
                    Text("Available: 300.1 tXTM")
                        .body()
                        .foregroundStyle(.whiteMain.opacity(0.5))
                }
                .padding(20)
            }
            
            HStack(spacing: 8) {
                TariButton("Send", style: .outlined, size: .large) {
                    
                }
                TariButton("Receive", style: .outlined, size: .large) {
                    
                }
            }
        }
    }
    
    var recentActivity: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent Activity")
                .headingXL()
                .foregroundStyle(.primaryText)
            
            VStack(spacing: 4) {
                TransactionItem()
                TransactionItem()
                // view all
            }
        }
    }
    
    var noActivity: some View {
        VStack(spacing: 0) {
            Text("You don’t have any activity yet.")
            
            Text("Once you receive some tXTM, you’ll see it here.")
        }
    }
}

#Preview {
    Home()
}
