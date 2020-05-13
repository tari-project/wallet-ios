//  NotificationService.swift
	
/*
	Package MobileWalletNotificationService
	Created by Jason van den Berg on 2020/05/11
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

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        //Below 2 lines always need to be here
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        self.completeHandler()
        //TODO add back when last of the crashes from stopping the wallet have been fixed
        //self.listenForTorConnection()
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        completeHandler()
    }
    
    private func listenForTorConnection() {
        TariLib.shared.startTor()
        TariEventBus.onBackgroundThread(self, eventType: .torConnected) { [weak self] (_) in
            guard let self = self else { return }
            TariEventBus.unregister(self, eventType: .torConnected)

            do {
                try TariLib.shared.startExistingWallet(isBackgroundTask: true)
                self.listenForReceivedTransaction()
            } catch {
                TariLogger.error("Didn't start wallet", error: error)
                self.completeHandler()
            }
        }
    }
    
    private func listenForReceivedTransaction() {
        try! TariLib.shared.tariWallet!.syncBaseNode()
        TariEventBus.onMainThread(self, eventType: .receievedTransaction) { [weak self] (result) in
            guard let self = self else { return }
                        
            //TX receieved, giving it some more time to send reply
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                if let receivedTX = result?.object as? TransactionProtocol {
                    let state = receivedTX.status.0
                    if state == .completed || state == .broadcast || state == .mined {
                        if TariSettings.shared.environment == .debug {
                            self.updateContent(title: "TX received", body: "And reply sent")
                        }
                        self.completeHandler()
                    }
                }
            }
        }
    }
    
    private func updateContent(title: String, body: String) {
        if let bestAttemptContent = self.bestAttemptContent {
            bestAttemptContent.title =  title
            bestAttemptContent.body =  body
        }
    }
    
    private func completeHandler() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
            TariEventBus.unregister(self)
            TariLib.shared.stopWallet()
            TariLib.shared.stopTor()
        }
    }
}
