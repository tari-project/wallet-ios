//  NodeSyncOperation.swift

/*
    Package MobileWallet
    Created by Jason van den Berg on 2020/03/11
    Using Swift 5.0
    Running on macOS 10.15

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

import Foundation

class NodeSyncOperation: Operation {
    var completionHandler: ((Bool) -> Void)?

    override func main() {
        if isCancelled {
            return
        }

        if TariSettings.shared.isDebug {
            NotificationManager.shared.scheduleNotification(title: "Background task", body: "Starting Tor")
        }

        if TariLib.shared.walletExists {
            handleWalletEvents()
            TariLib.shared.startTor()
        } else {
            //If there's no wallet, we're not syncing a node
            onComplete(true)
        }
    }

    private func handleWalletEvents() {
        //Handle on tor connected
        TariEventBus.onMainThread(self, eventType: .torConnected) {(_) in
            do {
                try TariLib.shared.startExistingWallet(isBackgroundTask: true)

                NotificationManager.shared.scheduleNotification(title: "Background task", body: "Wallet started")

                //This is useful for testing but should remove this when push notifications are working properly
                if TariSettings.shared.isDebug {
                    self.testReceiveTx()
                }
            } catch {
                TariLogger.error("Failed to start wallet", error: error)
                self.onComplete(false)
            }
        }

        TariEventBus.onMainThread(self, eventType: .torConnectionFailed) {(result) in
            let error: Error? = result?.object as? Error

            self.onComplete(false)

            if TariSettings.shared.isDebug {
                NotificationManager.shared.scheduleNotification(title: "Background task", body: "Tor connection failed")
            }

            TariLogger.error("Failed to connect to tor", error: error)
        }

        //TODO when a callback is added for when a node is synced, we should use that instead.
        TariEventBus.onMainThread(self, eventType: .receievedTransaction) {(_) in
            //guard let _ = self else { return }
            NotificationManager.shared.scheduleNotification(
                title: NSLocalizedString("You've got Tari!", comment: "Background refresh TX received notification"),
                body: String(
                    format: NSLocalizedString(
                        "Someone just sent you some %@",
                        comment: "Background refresh TX received notification"),
                    TariSettings.shared.network.currencyDisplayName
                )
            )

            self.onComplete(true)
        }

        //TODO we might want to listen on multiple events, to send push notications for different background events
    }

    private func onComplete(_ success: Bool) {
        if let done = self.completionHandler {
            TariEventBus.unregister(self)
            done(success)
        }
    }
}

extension NodeSyncOperation {
    fileprivate func testReceiveTx() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: {
            if let wallet = TariLib.shared.tariWallet {
                do {
                    try wallet.generateTestReceiveTransaction()
                } catch {
                    TariLogger.error("Failed to make test send TX", error: error)
                }
            }
        })
    }
}
