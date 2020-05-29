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
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private static var isInProgress = false

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard !AppContainerLock.shared.hasLock(.main) else {
            TariLogger.warn("Cannot run while main app is in foreground")
             self.completeHandler(success: false, debugMessage: "Main app has lock")
            return
        }
        
        guard !NotificationService.isInProgress else {
            TariLogger.warn("Extension sync already in progress")
            return
        }
        
        //Below 3 lines always need to be here
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        NotificationService.isInProgress = true
        AppContainerLock.shared.setLock(.ext)
        
        if TariSettings.shared.extensionActive {
            self.listenForTorConnection()
            
            //If nothing happens in a minute kill it
            DispatchQueue.global().asyncAfter(deadline: .now() + 60) { [weak self] in
                self?.completeHandler(success: false, debugMessage: "Extension took longer than 60 seconds")
            }
        } else {
            self.completeHandler(success: true, debugMessage: "Extension not active")
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        completeHandler(success: false, debugMessage: "Expired")
    }
    
    private func listenForTorConnection() {
        TariLib.shared.startTor()
        TariEventBus.onBackgroundThread(self, eventType: .torConnected) { [weak self] (_) in
            guard let self = self else { return }
            TariEventBus.unregister(self, eventType: .torConnected)

            do {
                try TariLib.shared.startWalletService(container: .ext)
                try! TariLib.shared.tariWallet!.syncBaseNode()
                self.listenForReceivedTransaction()
                self.listenForBaseNodeSync()
            } catch {
                TariLogger.error("Did not start wallet", error: error)
                self.completeHandler(success: false, debugMessage: "Wallet did not start")
            }
        }
    }
    
    private func listenForReceivedTransaction() {
        TariEventBus.onMainThread(self, eventType: .receievedTransaction) { [weak self] (result) in
            guard let self = self else { return }
                        
            //TX receieved, giving it some more time to send reply
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                self.completeHandler(success: true, debugMessage: "Received transaction successfully")
            }
        }
    }
    
    private func listenForBaseNodeSync() {
        TariEventBus.onMainThread(self, eventType: .baseNodeSyncComplete) { [weak self] (result) in
            guard let self = self else { return }

            //If receievedTransaction isn't triggered 10s after a base node sync assume nothing is coming
            DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
                guard let self = self else { return }
                self.completeHandler(success: false, debugMessage: "Base node synced but no incoming transaction")
            }
        }
    }
    
    private func completeHandler(success: Bool, debugMessage: String = "") {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            TariEventBus.unregister(self)
            TariLib.shared.stopWallet()
            TariLib.shared.stopTor()
            
            if TariSettings.shared.environment == .debug {
                bestAttemptContent.title =  "\(bestAttemptContent.title) \(success ? "✅" : "❌")"
                bestAttemptContent.body =  "\(bestAttemptContent.body)\n~\(debugMessage)~"
            }
            
            contentHandler(bestAttemptContent)
        }
        
        NotificationService.isInProgress = false
        AppContainerLock.shared.removeLock(.ext)
    }
}