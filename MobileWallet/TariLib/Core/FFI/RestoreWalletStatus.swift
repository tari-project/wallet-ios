//  RestoreWalletStatus.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 03/10/2022
	Using Swift 5.0
	Running on macOS 12.4

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

enum RestoreWalletStatus {
    case unknown
    case connectingToBaseNode
    case connectedToBaseNode
    case connectionFailed(attempt: UInt64, maxAttempts: UInt64)
    case progress(restoredUTXOs: UInt64, totalNumberOfUTXOs: UInt64)
    case completed
    case scanningRoundFailed(attempt: UInt64, maxAttempts: UInt64)
    case recoveryFailed

    init(status: UInt8, firstValue: UInt64, secondValue: UInt64) {

        switch status {
        case 0:
            self = .connectingToBaseNode
        case 1:
            self = .connectedToBaseNode
        case 2:
            self = .connectionFailed(attempt: firstValue, maxAttempts: secondValue)
        case 3:
            self = .progress(restoredUTXOs: firstValue, totalNumberOfUTXOs: secondValue)
        case 4:
            self = .completed
        case 5:
            self = .scanningRoundFailed(attempt: firstValue, maxAttempts: secondValue)
        case 6:
            self = .recoveryFailed
        default:
            self = .unknown
        }
    }
}
