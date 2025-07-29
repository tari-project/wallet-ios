//  ConnectionMonitor.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/04/07
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

import UIKit
import Combine

final class ConnectionMonitor {

    // MARK: - Properties

    @Published private(set) var networkConnection: NetworkMonitor.Status = .disconnected
    @Published private(set) var baseNodeConnection: BaseNodeConnectivityStatus = .offline
    @Published private(set) var walletScannedHeight: UInt64 = 0
    @Published private(set) var chainTip: UInt64 = 0

    private let networkMonitor = NetworkMonitor()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setups

    func setupPublishers(
        baseNodeConnectionStatus: AnyPublisher<BaseNodeConnectivityStatus, Never>,
        scannedHeight: AnyPublisher<UInt64, Never>,
        blockHeight: AnyPublisher<UInt64, Never>
    ) {
        networkMonitor.$status
            .assign(to: \.networkConnection, on: self)
            .store(in: &cancellables)

        baseNodeConnectionStatus
            .assign(to: \.baseNodeConnection, on: self)
            .store(in: &cancellables)

        scannedHeight
            .assign(to: \.walletScannedHeight, on: self)
            .store(in: &cancellables)

        blockHeight
            .assign(to: \.chainTip, on: self)
            .store(in: &cancellables)
    }
}
