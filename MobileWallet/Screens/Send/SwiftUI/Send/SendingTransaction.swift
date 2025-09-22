//  SendingTransaction.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 04.09.2025
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
import AVKit
import Lottie

struct SendingTransaction: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @State var backgroundPlayer: AVPlayer?
    @State var backgroundOpacity: CGFloat = 0
    @State var connectingProgress: CGFloat = 0
    @State var finishingProgress: CGFloat = 0
    @State var isNetworkConnected = false
    @State var isSendingTransaction = false
    @State var isSendComplete = false
    @State var isSendFail = false

    let confirmation: SendConfirmation
    
    var body: some View {
        ZStack {
            animatedBackground
            VStack {
                animatedLogo
                message
                progressIndicator
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            toolbarBackItem { dismiss() }
        }
        .onReceive(AppConnectionHandler.shared.connectionMonitor.$networkConnection) { status in
            if case .connected = status {
                send()
            }
        }
        .onFirstAppear {
            load()
            send()
        }
        .onChange(of: scenePhase) {
            backgroundPlayer?.play()
        }
    }
}

private extension SendingTransaction {
    var animatedBackground: some View {
        GeometryReader { geometry in
            if let backgroundPlayer {
                UIVideoPlayer(player: backgroundPlayer, videoGravity: .resizeAspectFill)
                    .aspectRatio(geometry.size, contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .disabled(true)
            }
        }
        .ignoresSafeArea()
        .opacity(backgroundOpacity)
    }
    
    @ViewBuilder
    var animatedLogo: some View {
        if isSendComplete && isNetworkConnected {
            LottieView(animation: .named("sendingTariAnimation"))
                .playbackMode(.fromProgress(0.2, toProgress: 1, loopMode: .playOnce))
        } else {
            LottieView(animation: .named("sendingTariAnimation"))
                .playbackMode(.fromProgress(0, toProgress: 0.2, loopMode: .playOnce))
        }
    }
    
    var message: some View {
        VStack(spacing: 0) {
            Text(isNetworkConnected ? "Good to go! " : "Connecting to the...")
                .body()
            Text(isNetworkConnected ? "Your XTM is on the way!" : "Tari network...")
                .headingLarge()
        }
        .foregroundStyle(.primaryText)
    }
    
    var progressIndicator: some View {
        HStack(spacing: 6) {
            ProgressIndicator(value: connectingProgress)
            ProgressIndicator(value: finishingProgress)
        }
        .tint(.secondaryMain)
        .frame(width: 126)
    }
}
