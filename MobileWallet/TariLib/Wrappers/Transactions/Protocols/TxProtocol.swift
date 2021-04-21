//  TxProtocol.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/15
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

enum TxDirection {
    case inbound
    case outbound
    case none
}

enum TxStatus: Error {
    case txNullError
    case completed
    case broadcast
    case minedUnconfirmed
    case imported
    case pending
    case minedConfirmed
    case unknown
}

protocol TxProtocol {
    var pointer: OpaquePointer { get }
    var id: (UInt64, Error?) { get }
    var microTari: (MicroTari?, Error?) { get }
    // var fee: (UInt64, Error?) { get }
    var message: (String, Error?) { get }
    var timestamp: (UInt64, Error?) { get }
    var sourcePublicKey: (PublicKey?, Error?) { get }
    var status: (TxStatus, Error?) { get }
    var destinationPublicKey: (PublicKey?, Error?) { get }
    var direction: TxDirection { get }
    var contact: (Contact?, Error?) { get }
}

extension TxProtocol {
    var date: (Date?, Error?) {
        let (timestamp, error) = self.timestamp
        if error != nil {
            return (nil, error)
        }

        return (Date(timeIntervalSince1970: Double(timestamp)), nil)
    }

    func statusFrom(code: Int32) -> TxStatus {
        switch code {
            case -1:
                return .txNullError
            case 0:
                return .completed
            case 1:
                return .broadcast
            case 2:
                return .minedUnconfirmed
            case 3:
                 return .imported
            case 4:
                 return .pending
            case 6:
             return .minedConfirmed
            default:
                return .unknown
        }
    }

    var isCancelled: Bool {
        if let completedTx = self as? CompletedTx {
            return completedTx.isCancelled
        }
        return false
    }

    var isPending: Bool {
        if let _ = self as? PendingInboundTx {
            return true
        }

        if let _ = self as? PendingOutboundTx {
            return true
        }
        let (status, error) = self.status
        if error != nil { fatalError() }
        return status == .minedUnconfirmed
    }
}
