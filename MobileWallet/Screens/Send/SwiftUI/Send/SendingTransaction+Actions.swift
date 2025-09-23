//  SendingTransaction+Actions.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 12.09.2025
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

extension SendingTransaction {
    func load() {
        loadBackgroundAnimation()
        connectToNetwork()
    }
    
    func connectToNetwork() {
        withAnimation(.easeInOut(duration: 4)) {
            connectingProgress = 1
        } completion: {
            isNetworkConnected = true
            finaliseSend()
        }
    }
    
    func send() {
        guard !isSendingTransaction else { return }
        isSendingTransaction = true
        Task {
            do {
                try Tari.mainWallet.transactions.send(
                    toAddress: try TariAddress(base58: confirmation.address.fullRaw),
                    amount: confirmation.amount.rawValue,
                    feePerGram: confirmation.feePerGram.rawValue,
                    paymentID: confirmation.note ?? ""
                )
                Task { @MainActor in
                    isSendComplete = true
                    finaliseSend()
                }
            } catch {
                Task { @MainActor in
                    handleTransactionFail()
                }
            }
        }
    }
    
    func finaliseSend() {
        guard isSendComplete && isNetworkConnected else { return }
        withAnimation(.easeInOut(duration: 5)) {
            finishingProgress = 1
        } completion: {
            TabState.shared.selected = .home
            HomeRouter.shared.isSendPresented = false
        }
    }
    
    func handleTransactionFail() {
        guard !isSendFail else { return }
        isSendFail = true
        showTransactionError()
        dismiss()
    }
}

private extension SendingTransaction {
    func loadBackgroundAnimation() {
        backgroundPlayer = AVPlayer(url: Bundle.main.url(forResource: "sending-background", withExtension: "mp4")!)
        backgroundPlayer?.play()
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: .main) { notification in
            backgroundPlayer?.seek(to: .zero)
            backgroundPlayer?.play()
        }
        Task(after: 1) { // Reveal background animation after video loads to prevent UI blink
            withAnimation {
                backgroundOpacity = 1
            }
        }
    }
    
    func showTransactionError() {
        if AppConnectionHandler.shared.connectionMonitor.networkConnection == .disconnected {
            PopUpPresenter.show(message: MessageModel(
                title: localized("sending_tari.error.interwebs_connection.title"),
                message: localized("sending_tari.error.interwebs_connection.description"),
                type: .error
            ))
        } else {
            PopUpPresenter.show(message: MessageModel(
                title: localized("sending_tari.error.no_connection.title"),
                message: localized("sending_tari.error.no_connection.description"),
                type: .error
            ))
        }
    }
}
