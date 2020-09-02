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
    private var safetyTimeoutCallBack: (() -> Void)?
    private static var isInProgress = false {
        didSet {
            if isInProgress {
                ConnectionMonitor.shared.start()
                AppContainerLock.shared.setLock(.ext)
            } else {
                ConnectionMonitor.shared.stop()
                AppContainerLock.shared.removeLock(.ext)
            }
        }
    }
    
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
        
        self.listenForTorConnection()
        
        safetyTimeoutCallBack = { [weak self] in
            self?.completeHandler(success: false, debugMessage: "Extension took longer than 60 seconds")
        }

        //If nothing happens in a minute kill it
        DispatchQueue.global().asyncAfter(deadline: .now() + 60) { [weak self] in
            self?.safetyTimeoutCallBack?()
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        completeHandler(success: false, debugMessage: "Service expired. \n\(ConnectionMonitor.shared.state.formattedDisplayItems.joined(separator: "\n"))")
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
                self.listenForStoredMessages()
            } catch {
                TariLogger.error("Did not start wallet", error: error)
                self.completeHandler(success: false, debugMessage: "Wallet did not start")
            }
        }
    }
    
    private func listenForReceivedTransaction() {
        TariEventBus.onMainThread(self, eventType: .receievedTx) { [weak self] (result) in
            guard let self = self else { return }
            self.safetyTimeoutCallBack = nil
            
            //TX receieved, giving it some more time to send reply
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                self.completeHandler(success: true, debugMessage: "Received transaction successfully")
            }
        }
    }
    
    private func listenForStoredMessages() {
        TariEventBus.onMainThread(self, eventType: .storedMessagesReceived) { [weak self] (result) in
            guard let self = self else { return }
            self.safetyTimeoutCallBack = nil

            //If receievedTransaction isn't triggered after a stored messages are received assume nothing is coming
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
                guard let self = self else { return }
                self.completeHandler(success: false, debugMessage: "Stored messages received but no incoming transaction")
            }
        }
    }
    
    private func completeHandler(success: Bool, debugMessage: String = "") {
        //A background operation will use this flag to set scheduled reminder notifications for users to open up the app if this extension failed to receieve the TX
        if !success {
            ReminderNotifications.shared.setShouldScheduleReminder()
            TariLogger.info("Setting flag for scheduling reminder notificaions in main app background operation")
        }
        
        if !debugMessage.isEmpty {
            TariLogger.info("App extension completed \(success ? "✅" : "❌")")
            TariLogger.info(debugMessage)
        }
        
        TariEventBus.unregister(self)
        TariLib.shared.stopWallet()
        TariLib.shared.stopTor()
        
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            if TariSettings.shared.environment == .debug {
                bestAttemptContent.title = "\(bestAttemptContent.title)\(success ? "✅" : "❌")"
                bestAttemptContent.body =  "\(bestAttemptContent.body)\n\(debugMessage)"
            }
            
            contentHandler(bestAttemptContent)
        }
        
        NotificationService.isInProgress = false
        
        safetyTimeoutCallBack = nil
    }
}
