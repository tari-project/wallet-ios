//  ChainTipObserver.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 29.07.2025
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

protocol ChainTipObserver {
    var scannedHeight: UInt64 { get nonmutating set }
    var chainTip: UInt64 { get nonmutating set }
}

extension ChainTipObserver {
    var isChainTipSynced: Bool {
        0 < scannedHeight && scannedHeight == chainTip
    }
    
    var unsyncedBlockCount: UInt64 {
        chainTip - min(chainTip, scannedHeight)
    }
}

extension View {
    func observeChainTip(_ observer: ChainTipObserver) -> some View {
        self.onReceive(Tari.mainWallet.connectionCallbacks.$scannedHeight) { observer.scannedHeight = $0 }
            .onReceive(Tari.mainWallet.connectionCallbacks.$blockHeight) { observer.chainTip = $0 }
    }
}
