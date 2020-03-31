//  TariEventBus.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/22
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

public enum TariEventTypes: String {
    //Wallet callbacks
    case receievedTransaction = "tari-event-receieved-transaction"
    case receievedTransactionReply = "tari-event-receieved-transaction-reply"
    case receivedFinalizedTransaction = "tari-event-received-finalized-transaction"
    case transactionBroadcast = "tari-event-transaction-broadcase"
    case transactionMined = "tari-event-transaction-mined"
    case discoveryProcessComplete = "tari-event-discovery-process-complete"
    case baseNodeSyncComplete = "tari-event-base-node-synce-complete"

    //Common UI updates
    case transactionListUpdate = "tari-event-transaction-list-update"
    case balanceUpdate = "tari-event-balance-update"

    //Tor instantiation statuses
    case torPortsOpened = "tari-event-tor-ports-opened"
    case torConnectionProgress = "tari-event-tor-connection-progress"
    case torConnected = "tari-event-tor-connected"
    case torConnectionFailed = "tari-event-tor-connection-failed"
}

private let IDENTIFIER = "com.tari.eventbus"

open class TariEventBus {
    static let shared = TariEventBus()
    static let queue = DispatchQueue(label: IDENTIFIER, attributes: [])

    struct NamedObserver {
        let observer: NSObjectProtocol
        let eventType: TariEventTypes
    }

    var cache = [UInt: [NamedObserver]]()

    // MARK: Publish

    open class func postToMainThread(_ eventType: TariEventTypes, sender: Any? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: eventType.rawValue), object: sender)
        }
    }

    // MARK: Subscribe

    @discardableResult
    open class func on(_ target: AnyObject, eventType: TariEventTypes, sender: Any? = nil, queue: OperationQueue?, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        let id = UInt(bitPattern: ObjectIdentifier(target))
        let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: eventType.rawValue), object: sender, queue: queue, using: handler)
        let namedObserver = NamedObserver(observer: observer, eventType: eventType)

        TariEventBus.queue.sync {
            if let namedObservers = TariEventBus.shared.cache[id] {
                TariEventBus.shared.cache[id] = namedObservers + [namedObserver]
            } else {
                TariEventBus.shared.cache[id] = [namedObserver]
            }
        }

        return observer
    }

    @discardableResult
    open class func onMainThread(_ target: AnyObject, eventType: TariEventTypes, sender: Any? = nil, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        return TariEventBus.on(target, eventType: eventType, sender: sender, queue: OperationQueue.main, handler: handler)
    }

    // MARK: Unregister

    open class func unregister(_ target: AnyObject) {
        let id = UInt(bitPattern: ObjectIdentifier(target))
        let center = NotificationCenter.default

        TariEventBus.queue.sync {
            if let namedObservers = TariEventBus.shared.cache.removeValue(forKey: id) {
                for namedObserver in namedObservers {
                    center.removeObserver(namedObserver.observer)
                }
            }
        }
    }

    open class func unregister(_ target: AnyObject, eventType: TariEventTypes) {
        let id = UInt(bitPattern: ObjectIdentifier(target))
        let center = NotificationCenter.default

        TariEventBus.queue.sync {
            if let namedObservers = TariEventBus.shared.cache[id] {
                TariEventBus.shared.cache[id] = namedObservers.filter({ (namedObserver: NamedObserver) -> Bool in
                    if namedObserver.eventType == eventType {
                        center.removeObserver(namedObserver.observer)
                        return false
                    } else {
                        return true
                    }
                })
            }
        }
    }

}
