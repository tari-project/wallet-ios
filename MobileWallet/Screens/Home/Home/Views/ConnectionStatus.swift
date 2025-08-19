//  ConnectionStatus.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 28.07.2025
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

enum ConnectionStatus {
    case success, progress, error
}

struct ConnectionStatusSheet: View, ChainTipObserver {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var networkMonitor = NetworkMonitor()
    @State var scannedHeight: UInt64 = 0
    @State var chainTip: UInt64 = 0

    var body: some View {
        VStack(spacing: 0) {
            Text("Connection Status")
                .modalTitle()
                .foregroundStyle(.primaryText)
            Spacer(minLength: 10)
            VStack(spacing: 0) {
                item("Internet", message: internetMessage, status: internetStatus)
                item(chainTipTitle, message: chainTipMessage, status: chainTipStatus)
            }
            Spacer(minLength: 10)
            TariButton("Close", style: .text, size: .medium) {
                dismiss()
            }
        }
        .padding(.vertical, 48)
        .padding(.horizontal, 12)
        .presentationDetents([.height(290)])
        .observeChainTip(self)
    }
}

private extension ConnectionStatusSheet {
    func item(_ title: String, message: String, status: ImageResource) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .body()
                .foregroundStyle(.primaryText)
            Spacer()
            Text(message)
                .body2()
                .foregroundStyle(.secondaryText)
            Image(status)
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
        .background(alignment: .bottom) {
            Divider()
        }
    }
    
    var internetMessage: String {
        switch networkMonitor.status {
        case .connected: "Connected"
        case .disconnected: "No connection"
        }
    }
    
    var internetStatus: ImageResource {
        switch networkMonitor.status {
        case .connected: .successStatus
        case .disconnected: .errorStatus
        }
    }
    
    var chainTipTitle: String {
        0 < chainTip
            ? "Chain Tip (#\(chainTip))"
            : "Chain Tip"
    }
    
    var chainTipMessage: String {
        isChainTipSynced
            ? "Synced"
            : 0 < scannedHeight && 0 < chainTip
                ? "Syncing (#\(scannedHeight))"
                : "No connection"
    }
    
    var chainTipStatus: ImageResource {
        isChainTipSynced
            ? .successStatus
            : 0 < scannedHeight && 0 < chainTip
                ? .progressStatus
                : .errorStatus
    }
}

#Preview {
    ConnectionStatusSheet()
}
