//  StatusLoggerManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 11/10/2022
	Using Swift 5.0
	Running on macOS 12.6

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

import Combine

final class StatusLoggerManager {

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupCallbacks()
    }

    private func setupCallbacks() {

        Tari.shared.connectionMonitor.$baseNodeConnection
            .sink { Logger.log(message: "Base Node Connection: \($0)", domain: .connection, level: .verbose) }
            .store(in: &cancellables)

        Tari.shared.connectionMonitor.$syncStatus
            .sink { Logger.log(message: "Sync Status: \($0)", domain: .connection, level: .verbose) }
            .store(in: &cancellables)

        Tari.shared.connectionMonitor.$torConnection
            .sink { Logger.log(message: "Tor Connection Status: \($0)", domain: .connection, level: .verbose) }
            .store(in: &cancellables)

        Tari.shared.connectionMonitor.$networkConnection
            .sink { Logger.log(message: "Network Connection Status: \($0)", domain: .connection, level: .verbose) }
            .store(in: &cancellables)

        Tari.shared.connectionMonitor.$torBootstrapProgress
            .sink { Logger.log(message: "Tor Bootstrap Progress: \($0)", domain: .connection, level: .verbose) }
            .store(in: &cancellables)

        Tari.shared.connectionMonitor.$isTorBootstrapCompleted
            .removeDuplicates()
            .sink { Logger.log(message: "Is Tor Bootstrap Progress Completed: \($0)", domain: .connection, level: .verbose) }
            .store(in: &cancellables)

    }
}
